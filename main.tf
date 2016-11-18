variable "region" {}
variable "priv_subnets" { type = "list" }
variable "asg_max" {}
variable "asg_min" {}
variable "asg_desired" {}
variable "key_name" {}
variable "app_name" {}
variable "ami_id" {}
variable "userdata" {}
variable "instance_type" {}
variable "asg_sgs" { type = "list" }

# For multiple scaling policies, copy the scale_ variables and add a uniqueness character
# Then duplicate the scale_policy module with the updated variables
variable "scale_adjustment_type" { default = "" }
variable "scale_alarm_actions" { type = "list" default = "" }
variable "scale_alarm_description" { default = "" }
variable "scale_alarm_name" { default = "" }
variable "scale_app_name" { default = "" }
variable "scale_comparison_operator" { default = "" }
variable "scale_cooldown" { default = "" }
variable "scale_policy_enabled" { default = "" }
variable "scale_eval_periods" { default = "" }
variable "scale_metric_name" { default = "" }
variable "scale_namespace" { default = "" }
variable "scale_period" { default = "" }
variable "scale_scaling_adjustment" { default = "" }
variable "scale_statistic" { default = "" }
variable "scale_threshold_value" { default = "" }

resource "aws_launch_configuration" "lc" {
  name_prefix = "${var.app_name}"
  image_id = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  user_data = "${var.userdata}"
  security_groups = ["${var.asg_sgs}"]
  key_name = "${var.key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name = "${aws_launch_configuration.lc.name}"
  launch_configuration  = "${aws_launch_configuration.lc.name}"
  vpc_zone_identifier = ["${var.priv_subnets}"]
  max_size = "${var.asg_max}"
  min_size = "${var.asg_min}"
  desired_capacity = "${var.asg_desired}"
  health_check_grace_period = 300
  health_check_type = "EC2"
  force_delete = true
  tag {
    key = "Name"
    value = "${var.app_name}"
    propagate_at_launch = true
  }
}

module "scale_policy" {
  source = "./scale_policy"
  count = "${coalesce(var.scale_policy_enabled, 0)}"
  asg_name = "${aws_autoscaling_group.asg.name}"
  adjustment_type = "${var.scale_adjustment_type}"
  alarm_actions = "${var.scale_alarm_actions}"
  alarm_description = "${var.scale_alarm_description}"
  alarm_name = "${var.scale_alarm_name}"
  app_name = "${var.scale_app_name}"
  comparison_operator = "${var.scale_comparison_operator}"
  cooldown = "${var.scale_cooldown}"
  eval_periods = "${var.scale_eval_periods}"
  metric_name = "${var.scale_metric_name}"
  namespace = "${var.scale_namespace}"
  period = "${var.scale_period}"
  scaling_adjustment = "${var.scale_scaling_adjustment}"
  statistic = "${var.scale_statistic}"
  threshold_value = "${var.scale_threshold_value}"
}

output "asg" { value = "${aws_autoscaling_group.asg.id}" }
