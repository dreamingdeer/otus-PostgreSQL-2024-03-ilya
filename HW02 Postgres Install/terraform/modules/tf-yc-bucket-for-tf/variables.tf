variable "sa_name" {
  type = string
  default = "momo-sa-s3"
  description = "Service account name"
}
variable "folder_id" {
  type = string
  default = "b1gehfo5aq2007vqdqfs"
  description = "Folder id"
}
variable "vm_count" {
  type = number
  default = 1
  description = "number of VM"
}
variable "bucket_name" {
  type = string
  default = "tf-momo-state"
  description = "Bucket name for store tf states"
}
variable "iam_token" {
  type = string
}
variable "cloud_id" {
  type = string
}
variable "zone" {
  type = string
}
