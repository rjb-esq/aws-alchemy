terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>3.27"
        }
    }

    required_version = ">= 0.14.9"
}

provider "aws" {
    profile = "default"
    region = "us-east-1"
}

resource "aws_s3_bucket" "beanstalk_bucket" {
    bucket = "beanstalk-flask-test"
}

resource "aws_s3_bucket_object" "beanstalk_bucket_obj" {
    bucket = aws_s3_bucket.beanstalk_bucket.id
    key = "beanstalk/application.zip"
    source = "application.zip"
}

resource "aws_elastic_beanstalk_application" "beanstalk_app" {
    name = "beanstalk-flask-test-app"
    description = "Test application for elastic beanstalk"
}

resource "aws_elastic_beanstalk_application_version" "beanstalk_flask_test_app_version" {
    bucket = aws_s3_bucket.beanstalk_bucket.id
    key = aws_s3_bucket_object.beanstalk_bucket_obj.id
    application = aws_elastic_beanstalk_application.beanstalk_app.name
    name = "beanstalk-flask-test-app-version"
}

#Create and subscribe to an SNS topic with my Email.
resource "aws_sns_topic" "alarm" {
  name              = "cpu-alarm-topic"
  kms_master_key_id = aws_kms_key.sns_encryption_key.id
  delivery_policy   = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ryanjosephboyce@gmail.com --region us-east-1"
  }
}

resource "aws_kms_key" "sns_encryption_key" {
  description             = "SNS Topic Encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}


resource "aws_cloudwatch_metric_alarm" "cpu-alarm" {
  alarm_name                = "terraform-test-cpu-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "75"
  alarm_description         = "Metric to watch for CPU utilization over 75 Percent"
  alarm_actions             = [aws_sns_topic.alarm.arn]
}

resource "aws_elastic_beanstalk_environment" "terraform_prod" {
    name = "beanstalk-terraform-prod"
    application = aws_elastic_beanstalk_application.beanstalk_app.name
    solution_stack_name = "64bit Amazon Linux 2 v3.3.8 running Python 3.8"
    description = "Flask env - prod"
    version_label = aws_elastic_beanstalk_application_version.beanstalk_flask_test_app_version.name

    setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name = "IamInstanceProfile"
      value = "aws-elasticbeanstalk-ec2-role"
    }
    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name = "InstanceType"
        value = "t3.small"
    }
}

resource "aws_elastic_beanstalk_environment" "terraform_staging" {
    name = "beanstalk-terraform-staging"
    application = aws_elastic_beanstalk_application.beanstalk_app.name
    solution_stack_name = "64bit Amazon Linux 2 v3.3.8 running Python 3.8"
    description = "Flask env - staging"
    version_label = aws_elastic_beanstalk_application_version.beanstalk_flask_test_app_version.name

    setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name = "IamInstanceProfile"
      value = "aws-elasticbeanstalk-ec2-role"
    }
    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name = "InstanceType"
        value = "t3.micro"
    }
}