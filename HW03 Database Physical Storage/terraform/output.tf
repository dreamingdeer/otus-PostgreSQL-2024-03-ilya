output "base_image_id" {
  value = module.pg01.vm_source_image_id
}

output "external_ips_bastion" {
  value = module.bastion.external_ip_address_vm_1
}

output "internal_ips_bastion" {
  value = module.bastion.internal_ip_address_vm_1
}

output "pg_main" {
  value = module.pg01.internal_ip_address_vm_1
}

output "pg_bkp" {
  value = module.pg01-diskmig.internal_ip_address_vm_1
}
