output "yandex_lb_network_load_balancer" {
  description = "LB external ip"
  value       = yandex_lb_network_load_balancer.k3s.listener[*].external_address_spec[*].address
}
