output "lb_public_ip" {
  value = "${azurerm_public_ip.demo.ip_address}"
}

output "vm_random_password" {
  value = "${random_string.vm_password.result}"
}