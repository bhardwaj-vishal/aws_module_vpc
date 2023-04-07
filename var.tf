variable "vpc-cidr" {
  type = string
}

variable "vpc-enabled" {
  type = bool
}

variable "instance-tenancy" {
  type = string
  default = "default"
}

variable "enable-dns-support" {
  type = bool
  default = true
}

variable "enable-dns-hostnames" {
  type = bool
  default = false
}

variable "tags" {
  type        = map(string)
  default     = {}
}

variable "vpc-public-subnet-cidr" {
  type = list(string)
}

variable "map_public_ip_on_launch" {
  default = true
}

variable "prefix" {
  type = string
  default = "lfs-test"
}

variable "common_tags" {
  type        = map(string)
  default     = {}
}

# Private Subnet
variable "vpc-private-subnet-cidr" {
  type = list(string)
}

# K8s Subnet
variable "vpc-k8s-subnet-cidr" {
  type = list(string)
}

# Database Subnet
variable "vpc-db-subnet-cidr" {
  type = list(string)
}