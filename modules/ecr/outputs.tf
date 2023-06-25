output "repositories" {
  description = "The URL of the repository (in the form aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName)."
  value       = { for k, v in aws_ecr_repository.repositories : k => v.repository_url }
}
