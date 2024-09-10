
output "pds_cognito_user_pool_id" {
  value = aws_cognito_user_pool.pds_cognito_user_pool.id
}

output "pds_cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.pds_cognito_user_pool_client.id
}

output "pds_cognito_initial_users" {
  value = [var.pds_cognito_initial_users.*.username]
}
