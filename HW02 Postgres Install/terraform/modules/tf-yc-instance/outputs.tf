# output ip addreses
output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm_ubuntu_lts[*].network_interface.0.ip_address
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm_ubuntu_lts[*].network_interface.0.nat_ip_address
}

output "vm_source_image_id" {
  value = yandex_compute_image.ubuntu.id
}
