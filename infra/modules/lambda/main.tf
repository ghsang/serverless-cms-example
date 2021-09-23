data "aws_iam_policy_document" "assume_role" {
  policy_id = "${var.name}=lambda"
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
  name               = "lambda-${var.name}-iam"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "external" "build" {
  program = ["bash", "-c", <<EOT
(env GOOS=linux GOARCH=amd64 go build -o ./bin ./...) >&2 && echo "{\"dest\": \"$(pwd)/bin\"}"
EOT
  ]
  working_dir = "../functions"
}

data "archive_file" "package_zip" {
  type        = "zip"
  source_file = "${data.external.build.result.dest}/${var.name}"
  output_path = "bin/${var.name}.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name = var.name
  role          = aws_iam_role.iam_for_lambda.arn
  filename      = "bin/${var.name}.zip"
  handler       = var.name

  source_code_hash = filebase64sha256("bin/${var.name}.zip")

  runtime = "go1.x"
}
