variable "subnets" {
  type = set(string)
  default = ["ru-central1-a", "ru-central1-b", "ru-central1-c", "ru-central1-d"] 
  description = "available subnets"
}
