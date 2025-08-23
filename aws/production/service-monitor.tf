resource "aws_iam_role" "service-monitor" {
  name = "service-monitor"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}
data "archive_file" "dummy" {
  type        = "zip"
  output_path = "${path.module}/package.zip"

  source {
    content  = "dummy"
    filename = "dummy.txt"
  }
}
data "aws_ssm_parameter" "health_check_url" {
  name = "/service-monitor/health-check-url/v1"
}
data "aws_ssm_parameter" "basic_auth_user" {
  name = "/service-monitor/basic-auth-user/v1"
}
data "aws_ssm_parameter" "basic_auth_password" {
  name = "/service-monitor/basic-auth-password/v1"
}
data "aws_ssm_parameter" "slack_api_token" {
  name = "/service-monitor/slack-api-token/v1"
}
resource "aws_lambda_function" "service-monitor" {
  function_name = "service-monitor"
  description   = "Service monitor of staging home cluster"
  role          = aws_iam_role.service-monitor.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  architectures = ["x86_64"]
  filename      = data.archive_file.dummy.output_path

  environment {
    variables = {
      HEALTH_CHECK_URL    = data.aws_ssm_parameter.health_check_url.value
      BASIC_AUTH_USER     = data.aws_ssm_parameter.basic_auth_user.value
      BASIC_AUTH_PASSWORD = data.aws_ssm_parameter.basic_auth_password.value
      SLACK_API_TOKEN     = data.aws_ssm_parameter.slack_api_token.value
      SLACK_CHANNEL       = local.slack_channel
      CHECK_TIMEOUT       = "1"
    }
  }
}
resource "aws_iam_role" "event_bridge" {
  name = "event-bridge"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "scheduler.amazonaws.com"
        },
        "Sid" : "",
        "Effect" : "Allow"
      }
    ]
  })
}

# Shedule
resource "aws_iam_role_policy" "event_bridge" {
  name   = "service-monitor-event-bridge"
  role   = aws_iam_role.event_bridge.name
  policy = data.aws_iam_policy_document.event_bridge.json
}
data "aws_iam_policy_document" "event_bridge" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      aws_lambda_function.service-monitor.arn
    ]
  }
}
resource "aws_scheduler_schedule" "service-monitor" {
  name                         = "service-monitor"
  schedule_expression          = "rate(5 minutes)"
  schedule_expression_timezone = "Asia/Tokyo"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.service-monitor.arn
    role_arn = aws_iam_role.event_bridge.arn
  }
}

# Log
resource "aws_iam_role_policy_attachment" "service-monitor" {
  role       = aws_iam_role.service-monitor.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_cloudwatch_log_group" "service-monitor" {
  name              = "/aws/lambda/${aws_lambda_function.service-monitor.function_name}"
  retention_in_days = 3
  skip_destroy      = false
}
