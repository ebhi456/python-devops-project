module "networking" {
  source = "./networking"

  project_name             = var.project_name
  vpc_cidr_block           = var.vpc_cidr_block
  public_subnet_cidr_block = var.public_subnet_cidr_block
}