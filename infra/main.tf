terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.59"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "ap-northeast-2"
}

data "aws_iam_policy_document" "assume_role" {
  policy_id = "lambda"
  version   = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "external" "build" {
  program = ["bash", "-c", <<EOT
(env GOOS=linux GOARCH=amd64 go build -o ./bin ./...) >&2 && echo "{\"dest\": \"$(pwd)/bin\"}"
EOT
  ]
  working_dir = "../functions"
}

data "archive_file" "hello_zip" {
  type        = "zip"
  source_file = "${data.external.build.result.dest}/hello"
  output_path = "bin/hello.zip"
}

resource "aws_lambda_function" "hello" {
  function_name = "hello"
  role          = aws_iam_role.iam_for_lambda.arn
  filename      = "bin/hello.zip"
  handler       = "hello"

  source_code_hash = filebase64sha256("bin/hello.zip")

  runtime = "go1.x"
}
