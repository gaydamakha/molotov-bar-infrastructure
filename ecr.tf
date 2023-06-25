module "registry" {
  source      = "./modules/ecr"
  registry    = local.registry
  account_ids = [
    local.account.master,
  ]
}
