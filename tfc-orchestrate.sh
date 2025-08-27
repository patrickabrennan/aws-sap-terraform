#!/usr/bin/env bash
set -euo pipefail

# ========= CONFIG =========
: "${TFC_TOKEN:?Set TFC_TOKEN to your Terraform Cloud user/team API token}"
: "${TFC_ORG:?Set TFC_ORG to your Terraform Cloud org name}"

TFC_HOST="${TFC_HOST:-https://app.terraform.io}"   # Change if using TFE
API="$TFC_HOST/api/v2"

# Workspace order for APPLY (edit this ONE list only)
APPLY_ORDER=( network kms efs security_group iam ec2_instance )

# Polling settings
POLL_INTERVAL="${POLL_INTERVAL:-5}"   # seconds
MAX_POLLS="${MAX_POLLS:-360}"         # ~30 minutes per workspace

# Precheck behavior: wait for workspace to become idle (1) or fail immediately (0)
WAIT_WS_IDLE="${WAIT_WS_IDLE:-1}"

# ========= ARGS =========
# Usage: ./tfc-orchestrate.sh [apply|destroy]
ACTION="${1:-apply}"
if [[ "$ACTION" != "apply" && "$ACTION" != "destroy" ]]; then
  echo "Usage: $0 [apply|destroy]"
  exit 1
fi

# Confirm destructive action unless FORCE=1
if [[ "$ACTION" == "destroy" && "${FORCE:-0}" != "1" ]]; then
  read -r -p "This will DESTROY in reverse order. Type 'destroy' to continue: " ans
  [[ "$ans" == "destroy" ]] || { echo "Aborted."; exit 1; }
fi

# ========= HELPERS =========
command -v jq >/dev/null 2>&1 || { echo "jq is required. Please install jq and re-run."; exit 1; }

hdr_auth=( -H "Authorization: Bearer ${TFC_TOKEN}" )
hdr_json=( -H "Content-Type: application/vnd.api+json" -H "Accept: application/vnd.api+json" )

get_ws_id() {
  local name="$1"
  curl -sS "${hdr_auth[@]}" "${hdr_json[@]}" \
    "$API/organizations/$TFC_ORG/workspaces/$name" \
  | jq -r '.data.id // "null"'
}

get_ws_locked() {
  local name="$1"
  curl -sS "${hdr_auth[@]}" "${hdr_json[@]}" \
    "$API/organizations/$TFC_ORG/workspaces/$name" \
  | jq -r '.data.attributes.locked // false'
}

# Get latest run status for a workspace (or "none" if no runs)
get_latest_run_status() {
  local ws_id="$1"
  curl -sS "${hdr_auth[@]}" "${hdr_json[@]}" \
    "$API/workspaces/$ws_id/runs?page%5Bsize%5D=1&sort=-created-at" \
  | jq -r '.data[0].attributes.status // "none"'
}

# Return 0 (true) if status represents an in-progress run, 1 otherwise
is_in_progress_status() {
  case "$1" in
    # common in-flight statuses
    planning|planned|plan_queued|cost_estimating|cost_estimated|policy_checking|policy_checked|policy_override|confirmed|applying|apply_queued|queued|pending)
      return 0 ;;
    # known terminal / idle-ish statuses
    applied|planned_and_finished|errored|plan_errored|canceled|force_canceled|discarded|policy_soft_failed|none)
      return 1 ;;
    # unknown -> be conservative: treat as busy
    *)
      return 0 ;;
  esac
}

# Precheck: ensure workspace exists, not locked, and (optionally) wait until idle
precheck_workspace() {
  local ws_name="$1"
  local ws_id locked status

  ws_id="$(get_ws_id "$ws_name")"
  if [[ -z "$ws_id" || "$ws_id" == "null" ]]; then
    echo "✖ Workspace not found: $ws_name"
    return 1
  fi

  locked="$(get_ws_locked "$ws_name")"
  if [[ "$locked" == "true" ]]; then
    echo "✖ Workspace is locked: $ws_name"
    return 1
  fi

  status="$(get_latest_run_status "$ws_id")"
  if is_in_progress_status "$status"; then
    echo "ℹ [$ws_name] current run status: $status"
    if [[ "$WAIT_WS_IDLE" != "1" ]]; then
      echo "✖ Workspace is busy and WAIT_WS_IDLE=0. Try again later."
      return 1
    fi

    echo "…waiting for workspace to become idle before queuing new run"
    for ((i=1;i<=MAX_POLLS;i++)); do
      sleep "$POLL_INTERVAL"
      status="$(get_latest_run_status "$ws_id")"
      if ! is_in_progress_status "$status"; then
        echo "✔ [$ws_name] workspace is now idle (status: $status)"
        break
      fi
      printf "[%s] still busy: %s (poll %d/%d)\n" "$ws_name" "$status" "$i" "$MAX_POLLS"
      if (( i == MAX_POLLS )); then
        echo "✖ Timeout waiting for $ws_name to become idle."
        return 1
      fi
    done
  else
    echo "✔ [$ws_name] workspace is idle (status: $status)"
  fi
  return 0
}

create_run() {
  local ws_id="$1"
  local is_destroy_bool="$2"   # true|false
  local msg="$3"

  local body
  body="$(jq -n \
    --arg ws   "$ws_id" \
    --arg msg  "$msg" \
    --argjson destroy "$is_destroy_bool" \
    '{
      data: {
        type: "runs",
        attributes: {
          message: $msg,
          "auto-apply": true,
          "is-destroy": $destroy
        },
        relationships: {
          workspace: { data: { type: "workspaces", id: $ws } }
        }
      }
    }'
  )"

  curl -sS "${hdr_auth[@]}" "${hdr_json[@]}" -X POST "$API/runs" -d "$body"
}

get_run_status() {
  local run_id="$1"
  curl -sS "${hdr_auth[@]}" "${hdr_json[@]}" \
    "$API/runs/$run_id" \
  | jq -r '.data.attributes.status'
}

apply_run() {
  local run_id="$1"
  curl -sS -o /dev/null -w "%{http_code}" \
    "${hdr_auth[@]}" "${hdr_json[@]}" \
    -X POST "$API/runs/$run_id/actions/apply"
}

wait_until_complete() {
  local run_id="$1" name="$2"
  local applied_once=false

  for ((i=1;i<=MAX_POLLS;i++)); do
    status="$(get_run_status "$run_id")"
    printf "[%s] run=%s status=%s (poll %d/%d)\n" "$name" "$run_id" "$status" "$i" "$MAX_POLLS"

    case "$status" in
      applied|planned_and_finished)
        echo "✔ [$name] completed: $status"
        return 0
        ;;
      errored|plan_errored|canceled|force_canceled|policy_soft_failed)
        echo "✖ [$name] ended in terminal state: $status"
        return 1
        ;;
      planned_and_saved|policy_checked|confirmed)
        if [[ "$applied_once" == false ]]; then
          echo "↪ [$name] requesting apply…"
          http_code="$(apply_run "$run_id")"
          if [[ "$http_code" != "202" ]]; then
            echo "✖ [$name] apply request not accepted (HTTP $http_code)."
            return 1
          fi
          applied_once=true
        fi
        ;;
      *)
        :
        ;;
    esac
    sleep "$POLL_INTERVAL"
  done

  echo "✖ [$name] timed out waiting for completion."
  return 1
}

process_workspace() {
  local ws_name="$1"
  local is_destroy="$2"  # true|false
  echo "==> Processing workspace: $ws_name  (destroy=$is_destroy)"

  ws_id="$(get_ws_id "$ws_name")"
  if [[ -z "$ws_id" || "$ws_id" == "null" ]]; then
    echo "✖ Workspace not found: $ws_name"
    return 1
  fi

  # NEW: precheck status/lock/busy
  if ! precheck_workspace "$ws_name"; then
    return 1
  fi

  run_json="$(create_run "$ws_id" "$is_destroy" "$([ "$is_destroy" == true ] && echo "Scripted destroy" || echo "Scripted apply") for $ws_name")"
  run_id="$(jq -r '.data.id // empty' <<<"$run_json")"
  if [[ -z "$run_id" ]]; then
    echo "✖ Failed to create run for $ws_name:"
    echo "$run_json"
    return 1
  fi

  wait_until_complete "$run_id" "$ws_name"
}

check_all_workspaces() {
  local missing=()
  local list=( "$@" )
  for ws in "${list[@]}"; do
    id="$(get_ws_id "$ws")"
    if [[ -z "$id" || "$id" == "null" ]]; then
      missing+=("$ws")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    echo "✖ Missing workspaces in org '$TFC_ORG': ${missing[*]}"
    exit 1
  fi
}

reverse_array() {
  local arr=( "$@" )
  local rev=()
  for ((i=${#arr[@]}-1; i>=0; i--)); do
    rev+=( "${arr[i]}" )
  done
  printf "%s\n" "${rev[@]}"
}

# ========= MAIN =========
if [[ "$ACTION" == "apply" ]]; then
  order=( "${APPLY_ORDER[@]}" )
  is_destroy=false
else
  mapfile -t order < <(reverse_array "${APPLY_ORDER[@]}")
  is_destroy=true
fi

# Preflight: ensure the whole list exists before starting
check_all_workspaces "${order[@]}"

for ws in "${order[@]}"; do
  if ! process_workspace "$ws" "$is_destroy"; then
    echo "✖ Halting due to failure in workspace: $ws"
    exit 1
  fi
done

echo "✅ All workspaces ${ACTION}ed successfully in order."

