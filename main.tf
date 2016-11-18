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
variable "scaleup_cpu_threshold_value" {}
variable "scaledown_cpu_threshold_value" {}

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

resource "aws_autoscaling_policy" "scale_up" {
  name = "${var.app_name}-scaleup"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpu_scale_up" {
  alarm_name = "${var.app_name}-scaleup"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUReservation"
  namespace = "AWS/EC2"
  period = "300"
  statistic = "Average"
  threshold = "${var.scaleup_cpu_threshold_value}"
  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.asg.name}"
  }
  alarm_description = "This metric monitor ec2 CPUReservation"
  alarm_actions = ["${aws_autoscaling_policy.scale_up.arn}"]
}

resource "aws_autoscaling_policy" "scale_down" {
  name = "${var.app_name}-scaledown"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpu_scale_down" {
  alarm_name = "${var.app_name}-scaledown"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "1"
  metric_name = "CPUReservation"
  namespace = "AWS/EC2"
  period = "300"
  statistic = "Average"
  threshold = "${var.scaledown_cpu_threshold_value}"
  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.asg.name}"
  }
  alarm_description = "This metric monitor ec2 CPUReservation"
  alarm_actions = ["${aws_autoscaling_policy.scale_down.arn}"]
}

output "asg" { value = "${aws_autoscaling_group.asg.id}" }
