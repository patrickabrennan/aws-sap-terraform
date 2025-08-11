########################################
# Associate IAM Instance Profile AFTER launch
########################################

resource "aws_iam_instance_profile_association" "this" {
  instance_id = aws_instance.this.id
  iam_instance_profile = (
    var.ha
    ? data.aws_ssm_parameter.ec2_ha_instance_profile.value
    : data.aws_ssm_parameter.ec2_non_ha_instance_profile.value
  )

  depends_on = [aws_instance.this]
}
