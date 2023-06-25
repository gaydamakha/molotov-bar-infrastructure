variable "registry" {
  description = "A map of registry values."
  type        = map(string)
}

variable "account_ids" {
  description = "List of Account Ids to be allowed"
  type        = list(any)
}

variable "scan_on_push" {
  description = "Enable or disable the scan on push feature"
  type        = bool
  default     = true
}
