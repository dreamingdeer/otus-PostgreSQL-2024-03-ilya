variable "nodes" {
  type = list(string)
#  default = ["ru-central1-a", "ru-central1-b", "ru-central1-c"]
  description = "available nodes"
}
variable "subnet_id" {
  type = string
#  default = "e9bgji3n08h5drjmfedn"
  description = "VPC subnet"
}
variable "tPort" {
  type = number
  default = 80
  description = "http port"
}
variable "tsPort" {
  type = number
  default = 443
  description = "https port"
}