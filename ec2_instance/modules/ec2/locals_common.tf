locals {
  # Common disks applied in addition to HANA/NW sets
  # Tweak sizes/names to match your original layout.
  common = {
    hana = [
      { name = "usr-sap", type = "gp3", size = 100, disk_nb = 1 },
      { name = "trans",   type = "gp3", size = 100, disk_nb = 1 },
      { name = "sapmnt",  type = "gp3", size = 100, disk_nb = 1 },
      { name = "diag",    type = "gp3", size = 50,  disk_nb = 1 },
      { name = "tmp",     type = "gp3", size = 50,  disk_nb = 1 },
    ]
    nw = [
      { name = "usr-sap", type = "gp3", size = 100, disk_nb = 1 },
      { name = "trans",   type = "gp3", size = 100, disk_nb = 1 },
      { name = "sapmnt",  type = "gp3", size = 100, disk_nb = 1 },
    ]
  }

  # HANA spec maps: choose sizes/counts by instance_type and storage type.
  # We provide a "default" profile; add exact instance types as keys if needed.
  hana_data_specs = {
    default = {
      gp3 = [ { name = "hana-data", type = "gp3", size = 512, disk_nb = 4 } ]
      io2 = [ { name = "hana-data", type = "io2", size = 512, disk_nb = 4 } ]
    }
  }

  hana_logs_specs = {
    default = {
      gp3 = [ { name = "hana-logs", type = "gp3", size = 256, disk_nb = 2 } ]
      io2 = [ { name = "hana-logs", type = "io2", size = 256, disk_nb = 2 } ]
    }
  }

  hana_backup_specs = {
    default = {
      st1 = [ { name = "hana-backup", type = "st1", size = 1024, disk_nb = 1 } ]
      gp3 = [ { name = "hana-backup", type = "gp3", size = 1024, disk_nb = 1 } ]
    }
  }

  hana_shared_specs = {
    default = {
      gp3 = [ { name = "hana-shared", type = "gp3", size = 100, disk_nb = 1 } ]
    }
  }
}
