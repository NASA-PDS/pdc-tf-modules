# Terraform module for the PDS Cognito User Pool

resource "aws_cognito_user_pool" "pds_cognito_user_pool" {
  name = var.user_pool_name

  admin_create_user_config {
    invite_message_template {
      email_subject = var.email_invitation_subject
      email_message = format("%s: https://%s.auth.us-west-2.amazoncognito.com/login?client_id=%s&response_type=code&scope=email+openid+profile&redirect_uri=%s",
        var.email_invitation_message, var.user_pool_domain, var.pds_welcome_page_client_id, var.pds_welcome_page_callback_url)
      sms_message = var.sms_text_invitation_message
    }

    allow_admin_create_user_only = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }
}

resource "aws_ssm_parameter" "pds_cognito_user_pool_id_parameter" {
  name       = format(var.ssm_param_cognito_user_pool_id)
  type       = "String"
  value      = aws_cognito_user_pool.pds_cognito_user_pool.id
  depends_on = [aws_cognito_user_pool.pds_cognito_user_pool]
}

resource "aws_cognito_user_pool_client" "pds_cognito_user_pool_client" {
  name                                 = "pds-welcome-app-client"
  user_pool_id                         = aws_ssm_parameter.pds_cognito_user_pool_id_parameter.value
  generate_secret                      = false
  prevent_user_existence_errors        = "ENABLED"
  callback_urls                        = ["https://pds.nasa.gov/"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  explicit_auth_flows                  = ["ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH"]
  supported_identity_providers         = ["COGNITO"]
}

resource "aws_ssm_parameter" "pds_cognito_user_pool_client_id_parameter" {
  name       = format(var.ssm_param_cognito_user_pool_client_id)
  type       = "String"
  value      = aws_cognito_user_pool_client.pds_cognito_user_pool_client.id
  depends_on = [aws_cognito_user_pool_client.pds_cognito_user_pool_client]
}

resource "aws_cognito_user_pool_domain" "pds_cognito_user_pool_domain" {
  domain       = var.user_pool_domain
  user_pool_id = aws_ssm_parameter.pds_cognito_user_pool_id_parameter.value
}

resource "aws_cognito_user_group" "pds_cognito_user_groups" {
  count = length(var.pds_cognito_user_groups)

  name         = var.pds_cognito_user_groups[count.index].name
  description  = var.pds_cognito_user_groups[count.index].description
  user_pool_id = aws_ssm_parameter.pds_cognito_user_pool_id_parameter.value
}

resource "aws_cognito_user" "pds_cognito_initial_users" {
  count = length(var.pds_cognito_initial_users)

  username                 = var.pds_cognito_initial_users[count.index].username
  user_pool_id             = aws_ssm_parameter.pds_cognito_user_pool_id_parameter.value
  desired_delivery_mediums = ["EMAIL"]
  enabled                  = true
  message_action           = "SUPPRESS"
  password                 = var.pds_cognito_initial_users[count.index].password

  attributes = {
    email          = var.pds_cognito_initial_users[count.index].email
    email_verified = true
  }
}

resource "aws_cognito_user_in_group" "pds_cognito_initial_user_group_assignment" {
  count      = length(var.pds_cognito_initial_users)
  depends_on = [aws_cognito_user.pds_cognito_initial_users]

  username     = var.pds_cognito_initial_users[count.index].username
  group_name   = var.pds_cognito_initial_users[count.index].group
  user_pool_id = aws_ssm_parameter.pds_cognito_user_pool_id_parameter.value
}

resource "aws_cognito_user_pool_ui_customization" "pds_cognito_user_pool_ui_customization" {
  css        = ".banner-customizable { background-color: white;}"
  image_file = filebase64("./modules/cognito/media/pds-logo.png")
  user_pool_id = aws_cognito_user_pool_domain.pds_cognito_user_pool_domain.user_pool_id
}


