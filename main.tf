provider "aws" {
    region = var.aws_region

    default_tags {
        tags = {
            serverless-patterns = "example-1"
        }
    }
}

resource "aws_dynamodb_table" "name_storage" {
    name           = "NameStorage"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "Name"
    attribute {
        name = "Name"
        type = "S"
    }
}

resource "aws_lambda_function" "get_function" {
    filename      = "get_lambda_function.zip"
    function_name = "GetFunction"
    role          = aws_iam_role.lambda_exec.arn
    handler       = "get.handler"
    runtime       = "nodejs14.x"
}

resource "aws_lambda_function" "save_function" {
    filename      = "save_lambda_function.zip"
    function_name = "SaveFunction"
    role          = aws_iam_role.lambda_exec.arn
    handler       = "save.handler"
    runtime       = "nodejs14.x"
}

resource "aws_api_gateway_rest_api" "my_api" {
    name        = "MyAPI"
    description = "My Serverless API"
}

resource "aws_api_gateway_resource" "root" {
    rest_api_id = aws_api_gateway_rest_api.my_api.id
    parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
    path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "get_method" {
    rest_api_id   = aws_api_gateway_rest_api.my_api.id
    resource_id   = aws_api_gateway_resource.root.id
    http_method   = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_method" "post_method" {
    rest_api_id   = aws_api_gateway_rest_api.my_api.id
    resource_id   = aws_api_gateway_resource.root.id
    http_method   = "POST"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_integration" {
    rest_api_id          = aws_api_gateway_rest_api.my_api.id
    resource_id          = aws_api_gateway_resource.root.id
    http_method          = aws_api_gateway_method.get_method.http_method
    integration_http_method = "GET"
    type                 = "AWS_PROXY"
    uri                  = aws_lambda_function.get_function.invoke_arn
}

resource "aws_api_gateway_integration" "post_integration" {
    rest_api_id          = aws_api_gateway_rest_api.my_api.id
    resource_id          = aws_api_gateway_resource.root.id
    http_method          = aws_api_gateway_method.post_method.http_method
    integration_http_method = "POST"
    type                 = "AWS_PROXY"
    uri                  = aws_lambda_function.save_function.invoke_arn
}

resource "aws_api_gateway_method_response" "get_response" {
    rest_api_id = aws_api_gateway_rest_api.my_api.id
    resource_id = aws_api_gateway_resource.root.id
    http_method = aws_api_gateway_method.get_method.http_method
    status_code = 200
}

resource "aws_api_gateway_method_response" "post_response" {
    rest_api_id = aws_api_gateway_rest_api.my_api.id
    resource_id = aws_api_gateway_resource.root.id
    http_method = aws_api_gateway_method.post_method.http_method
    status_code = 200
}

resource "aws_api_gateway_integration_response" "get_response" {
    rest_api_id = aws_api_gateway_rest_api.my_api.id
    resource_id = aws_api_gateway_resource.root.id
    http_method = aws_api_gateway_method.get_method.http_method
    status_code = aws_api_gateway_method_response.get_response.status_code
}

resource "aws_api_gateway_integration_response" "post_response" {
    rest_api_id = aws_api_gateway_rest_api.my_api.id
    resource_id = aws_api_gateway_resource.root.id
    http_method = aws_api_gateway_method.post_method.http_method
    status_code = aws_api_gateway_method_response.post_response.status_code
}

resource "aws_iam_role" "lambda_exec" {
    name = "lambda_exec_role"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": "sts:AssumeRole",
            "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
}
EOF
}