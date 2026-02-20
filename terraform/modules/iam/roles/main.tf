data "aws_caller_identity" "current" {}

data "aws_iam_policy" "permissions_boundary" {
  name = var.permissions_boundary_policy_name
}

resource "aws_iam_role" "this" {
  name                 = var.role_name
  description          = var.role_description
  permissions_boundary = data.aws_iam_policy.permissions_boundary.arn
  assume_role_policy   = jsonencode(var.assume_role_policy)

  tags = merge(var.required_tags)
}

resource "aws_iam_policy" "this" {
  for_each = var.custom_policies

  name        = each.key
  description = each.value.description
  policy      = jsonencode(each.value.policy_document)

  tags = merge(var.required_tags)
}

resource "aws_iam_role_policy_attachment" "custom" {
  for_each = var.custom_policies

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[each.key].arn
}

resource "aws_iam_role_policy_attachment" "existing" {
  for_each = toset(var.custom_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
