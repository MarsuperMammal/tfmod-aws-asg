variable "adjustment_type" {}
variable "alarm_actions" { default = "" }
variable "alarm_description" { default = "" }
variable "alarm_name" {}
variable "app_name" {}
variable "asg_name" {}
variable "comparison_operator" {}
variable "cooldown" {}
variable "eval_periods" {}
variable "metric_name" {}
variable "namespace" {}
variable "period" {}
variable "scaling_adjustment" {}
variable "statistic" {}
variable "threshold_value" {}

resource "aws_autoscaling_policy" "scale_policy" {
  name = "${var.app_name}-scaleup"
  scaling_adjustment = "${var.scaling_adjustment}"
  adjustment_type = "${var.adjustment_type}"
  cooldown = "${var.cooldown}"
  autoscaling_group_name = "${var.asg_name}"
}

resource "aws_cloudwatch_metric_alarm" "metric_alarm" {
  alarm_name = "${var.app_name}-${var.alarm_name}"
  comparison_operator = "${var.comparison_operator}"
  evaluation_periods = "${var.eval_periods}"
  metric_name = "${var.metric_name}"
  namespace = "${var.namespace}"
  period = "${var.period}"
  statistic = "${var.statistic}"
  threshold = "${var.threshold_value}"
  dimensions {
    AutoScalingGroupName = "${var.asg_name}"
  }
  alarm_description = "${var.alarm_description}"
  alarm_actions = ["${aws_autoscaling_policy.scale_policy.arn}", "${var.alarm_actions}"]
}
