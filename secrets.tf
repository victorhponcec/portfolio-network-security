resource "random_password" "db" {
  length           = 14
  special          = false
  override_special = ".-_"
}

resource "random_password" "vpn" {
  length           = 14
  special          = false
  override_special = ".-_"
}