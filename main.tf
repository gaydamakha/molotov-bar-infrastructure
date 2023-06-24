resource "aws_vpc" "molotov_bar_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "molotov_bar_vpc"
  }
}
