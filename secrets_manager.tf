/*
resource "aws_secretsmanager_secret" "db_password" {
  name        = "db-password-v8"
  description = "Database Password"
}

resource "aws_secretsmanager_secret_version" "db_password_v1" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db.result
  })
}
*/

/*
resource "aws_secretsmanager_secret" "vpn_password" {
  name        = "vpn-password-v1"
  description = "VPN phase 1 Password"
}

resource "aws_secretsmanager_secret_version" "vpn_password_v1" {
  secret_id = aws_secretsmanager_secret.vpn_password.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.vpn.result
  })
}

*/