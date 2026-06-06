variable "env" {
  type = string
}

variable "github_org" {
  description = "GitHub username or org name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
