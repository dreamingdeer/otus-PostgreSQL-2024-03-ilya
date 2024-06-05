locals {
    sshpub = sensitive(file("../../accesskey.pub"))

    pg_meta_file  = templatefile("./templates/pg-meta.tftpl", { 
        sshkey = local.sshpub
    })
    bastion_meta_file  = templatefile("./templates/bastion-meta.tftpl", {
        sshkey = local.sshpub
    })
}

# create subnet with nat gw for pg
module "local-nat" {
  source = "github.com/dreamingdeer/otus-PostgreSQL-2024-03-ilya.git//HW02 Postgres Install/terraform/modules//tf-yc-nat?ref=f5f91a1"
  folder_id = var.folder_id
}
# HW02 Postgres Install/terraform/modules/tf-yc-instance
# create bastion host for access to cluster
module "bastion" {
  source = "github.com/dreamingdeer/otus-PostgreSQL-2024-03-ilya.git//HW02 Postgres Install/terraform/modules/tf-yc-instance?ref=f5f91a1"
  source_family = "ubuntu-2204-lts"
  vm_count = 1
  vm_nat = true
  core_fraction = 20
  user_data_file = local.bastion_meta_file
  disk_size = 15
  # base name
  name = "bastion-for-pg"
  # get subnet id for vm from specified zone
  subnet_id = module.local-nat.yandex_vpc_subnets.id
  depends_on = [ module.local-nat ]
}

module "pg01" {
  source = "github.com/dreamingdeer/otus-PostgreSQL-2024-03-ilya.git//HW02 Postgres Install/terraform/modules/tf-yc-instance?ref=f5f91a1"
  source_family = "ubuntu-2204-lts"
  vm_count = 1 # numbers of vm
  vm_nat = false
  cores = 2
  core_fraction = 20
  memory = 4
  disk_size = 30
  # set custom
  user_data_file = local.pg_meta_file
  # base name
  name = "pg"
  # get subnet id for vm from specified zone
  subnet_id = module.local-nat.yandex_vpc_subnets.id
  depends_on = [ module.bastion ]
}

module "pg01-diskmig" {
  source = "github.com/dreamingdeer/otus-PostgreSQL-2024-03-ilya.git//HW02 Postgres Install/terraform/modules/tf-yc-instance?ref=f5f91a1"
  source_family = "ubuntu-2204-lts"
  vm_count = 1 # numbers of vm
  vm_nat = false
  cores = 2
  core_fraction = 20
  memory = 4
  disk_size = 30
  # set custom
  user_data_file = local.pg_meta_file
  # base name
  name = "pgbpk"
  # get subnet id for vm from specified zone
  subnet_id = module.local-nat.yandex_vpc_subnets.id
  depends_on = [ module.bastion ]
}


# ssh до ресрусов через jump host
resource "local_file" "ssh_configs" {
  depends_on = [ module.bastion  ]
  content  = templatefile("./templates/sshconfig.tftpl",
   {
    ip_bastion = module.bastion.external_ip_address_vm_1[0]
   }
  )
  file_permission = 600
  filename = pathexpand("~/.ssh/config.d/pg.conf")
}
