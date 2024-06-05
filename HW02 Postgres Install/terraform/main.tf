# create subnet with nat gw for pg
module "local-nat" {
  source = "./modules/tf-yc-nat"
  folder_id = var.folder_id
}

# create bastion host for access to cluster
module "bastion" {
  source = "./modules/tf-yc-instance"
  source_family = "ubuntu-2204-lts"
  vm_count = 1
  vm_nat = true
  core_fraction = 20
  user_data_file = file("bastion-meta.yml")
  disk_size = 15
  # base name
  name = "bastion-for-pg"
  # get subnet id for vm from specified zone
  subnet_id = module.local-nat.yandex_vpc_subnets.id
    depends_on = [ module.local-nat ]

}

module "pg01" {  
  source = "./modules/tf-yc-instance"
  source_family = "ubuntu-2204-lts"
  vm_count = 1 # numbers of vm
  vm_nat = false
  cores = 4
  core_fraction = 20
  memory = 4
  disk_size = 30
  # set custom
  user_data_file = file("pg-meta.yml")
  # base name
  name = "pg"
  # get subnet id for vm from specified zone
  subnet_id = module.local-nat.yandex_vpc_subnets.id
  depends_on = [ module.bastion ]
}

# ssh до ресрусов через jump host
resource "local_file" "ssh_configs" {
  depends_on = [ module.bastion  ]
  content  = templatefile("./templates/sshconfig.tpl",
   { 
    ip_bastion = module.bastion.external_ip_address_vm_1[0]
   }
  )
  file_permission = 600
  filename = pathexpand("~/.ssh/config.d/pg.conf")
}



# # run shell command by terraform
# resource "null_resource" "deploy" {
#   depends_on = [ null_resource.copyhelm ]
#   provisioner "local-exec" {
#     command = <<EOT
#             ssh ${module.k3master.internal_ip_address_vm_1[0]} < deploy.sh
#         EOT
#   } 
# }