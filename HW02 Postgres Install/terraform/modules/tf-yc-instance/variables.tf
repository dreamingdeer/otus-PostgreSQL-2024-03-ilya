variable "name" {
  type = string
}

variable "vm_nat" {
  type = bool
  default = true
}
variable "vm_count" {
  type = number
  default = 1
  description = "number of VM"
}
variable "cores" {
  type = number
  default = 2
  description = "Num of CPU cores"
}
variable "core_fraction" {
  type = number
  default = 5
  description = "percent of granted CPU"
}
variable "memory" {
  type = number
  default = 2
  description = "RAM in GB"
}
variable "disk_size" {
  type = number
  default = 15
  description = "Size in GB for disk"
}
variable "image_id" {
  type = string
  default = "fd8kdq6d0p8sij7h5qe3"
  description = "Image on YA with cloud-init for deploy"
}
variable "subnet_id" {
  type = string
  default = "e9bgji3n08h5drjmfedn"
  description = "VPC subnet"
}
variable "instance_zone" {
  type = string
  default = "ru-central1-d"
  description = "Zone"
}
variable "user_data_file" {
  type = string
  default = "meta.yml"
}
variable "source_family" {
  type = string
  default = "ubuntu-2004-lts"
}

variable "vm_second_disks" {
  type = map(object({
    name = string,
    type = string,
    size = number
  }))
  default = {}
}
