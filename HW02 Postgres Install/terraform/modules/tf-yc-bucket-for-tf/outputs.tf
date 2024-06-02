# output id sa account for s3
output "yandex_iam_service_account_id" {
  value = yandex_iam_service_account.sa.id
}

output "access_key" {
  value = yandex_iam_service_account_static_access_key.sa-static-key.access_key
}

output "secret_key" {
  sensitive = true
  value = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
}

output "bucket_name" {
  value = yandex_storage_bucket.s3-tfstate.bucket
}

output "bucket_domain_name" {
  value = yandex_storage_bucket.s3-tfstate.bucket_domain_name
}
