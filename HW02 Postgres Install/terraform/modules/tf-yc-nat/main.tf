resource "yandex_vpc_network" "default" {
  folder_id      = var.folder_id
  name        = "default"
  description = "Мегасеть! голой ж давить ежей"
  labels = {
    tf-label    = "tf-label-value"
    empty-label = ""
  }
}
resource "yandex_vpc_subnet" "pg-subnet" {
  name = "pg zone d"
  description = "for k3s cluster in ru-central1-d"
  folder_id      = var.folder_id
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.default.id
  
  route_table_id = yandex_vpc_route_table.rt.id
  v4_cidr_blocks = ["10.128.0.0/24"]
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "pg-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  name       = "pg-net-route-table"
  network_id = yandex_vpc_network.default.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}
