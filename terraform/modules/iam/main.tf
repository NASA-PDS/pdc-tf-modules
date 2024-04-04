# main iam module
resource "aws_iam_role" "iam_role" {
  for_each             = { for role in local.policy_data : role.iam_role_name => role }
  name                 = "${var.iam_role_preffix}-${each.key}"
  description          = each.value.iam_role_description
  assume_role_policy   = jsonencode(each.value.trust_relationship)
  permissions_boundary = var.permission_boundary != "" ? var.permission_boundary : null

  tags = var.tags
}

resource "aws_iam_policy" "iam_policy" {
  for_each = { for policy in local.policies_flat : "${policy.iam_role_name}-${policy.iam_policy_name}" => policy }
  name     = "${var.iam_role_preffix}-${each.value.iam_policy_name}"
  policy   = jsonencode(each.value.iam_policy_document)

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "iam_policy_attachment" {
  for_each   = { for policy in local.policies_flat : "${policy.iam_role_name}-${policy.iam_policy_name}" => policy }
  role       = aws_iam_role.iam_role[each.value.iam_role_name].id
  policy_arn = aws_iam_policy.iam_policy["${each.value.iam_role_name}-${each.value.iam_policy_name}"].arn
}
