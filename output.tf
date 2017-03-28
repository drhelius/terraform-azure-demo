output "lb_public_ip" {
  value = "${azurerm_public_ip.demo.ip_address}"
}
