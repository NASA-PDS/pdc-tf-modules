resource "aws_iam_role" "ec2" {
  name        = "${var.venue}-${var.component}-ec2-role"
  description = "EC2 instance role for the ${var.component} component"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.required_tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.additional_policy_arns)

  role       = aws_iam_role.ec2.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "ec2users_dynamodb" {
  name = "ec2users-dynamodb"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:Get*",
        "dynamodb:Query"
      ]
      Resource = [
        var.ec2users_dynamodb_table_arn
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.venue}-${var.component}-ec2-role"
  role = aws_iam_role.ec2.name
  tags = var.required_tags
}
