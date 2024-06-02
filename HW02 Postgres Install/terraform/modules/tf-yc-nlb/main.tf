resource "yandex_lb_network_load_balancer" "k3s" {
  region_id = "ru-central1"
  name      = "k3s-lb"

  listener {
    name        = "k3s-lb-listener"
    port        = 80
    target_port = var.tPort
    protocol    = "tcp"

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  listener {
    name        = "k3s-lb-listener-secure"
    port        = 443
    target_port = var.tsPort
    protocol    = "tcp"

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.k3s.id
    healthcheck {
      name = "hc-k3s-nodes"
      tcp_options {
        port = var.tPort
      }
      interval = 4
      timeout  = 2
    }
  }
}

resource "yandex_lb_target_group" "k3s" {
  name      = "k3s-cluster-group-nodes"
  region_id = "ru-central1"


 dynamic "target" {
    for_each = var.nodes
    content {
      address =  target.value
      subnet_id = var.subnet_id
    }
  }
}
