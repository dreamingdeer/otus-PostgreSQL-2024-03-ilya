# get latest id
resource "yandex_compute_image" "ubuntu" {
  source_family = var.source_family
}

resource "yandex_compute_instance" "vm_ubuntu_lts" {
  count = var.vm_count
  name = "${var.name}-${count.index}"


  allow_stopping_for_update = true
  platform_id = "standard-v3"

  resources {
    cores  = var.cores
    memory = var.memory
    core_fraction = var.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = yandex_compute_image.ubuntu.id
      size     = var.disk_size
    }
  }

 dynamic "secondary_disk" {
    for_each = yandex_compute_disk.disk
    content {
      disk_id = secondary_disk.value.id
      auto_delete = false
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = var.vm_nat
  }
  metadata = {
    #cloud init params for vm
    user-data = var.user_data_file
  }
  scheduling_policy {
    preemptible = true
  }
  zone = var.instance_zone
}

resource "yandex_compute_disk" "disk" {
  for_each = var.vm_second_disks
  name     = each.value.name
  type     = each.value.type
  zone     = var.instance_zone
  size     = each.value.size

  labels = {
    environment = each.key
  }
}
