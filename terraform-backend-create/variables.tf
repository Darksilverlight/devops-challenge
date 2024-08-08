variable "remote_s3_name" {
    type        = string
    description = "Public Subnet CIDR values"
    default     = "darksilverlight-devops-challenge-tfstate"
}

variable "repository_name" {
    type        = string
    description = "Repository for Docker Image"
    default     = "prod"
}