locals {
  org    = "Molotov Bar"
  region = "eu-central-1"
  env    = "dev"
  name   = "molotov-bar-api"
  account = {
    master = "439575621641"
  }
  registry = {
    molotov-bar-api = "molotov-bar-api"
  }
  db_username = "molotovbardbadmin"
  db_ip_whitelist = [
    "37.65.51.122/32"
  ]
}
