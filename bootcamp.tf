provider "azurerm" {
  client_id       = "${var.azure_client_id}"
  client_secret   = "${var.azure_client_secret}"
  subscription_id = "${var.azure_subscription_id}"
  tenant_id       = "${var.azure_tenant_id}"
}

resource "azurerm_resource_group" "demo" {
  name     = "bootcamp-terraform"
  location = "${var.azure_location}"
}

resource "azurerm_virtual_network" "demo" {
  name          = "bootcamp-virtual-network"
  address_space = ["10.0.0.0/16"]
  location      = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.demo.name}"
}

resource "azurerm_subnet" "demo" {
  name                 = "bootcamp-subnet"
  resource_group_name  = "${azurerm_resource_group.demo.name}"
  virtual_network_name = "${azurerm_virtual_network.demo.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_public_ip" "demo" {
  name                         = "bootcamp-public-ip"
  location                     = "${var.azure_location}"
  resource_group_name          = "${azurerm_resource_group.demo.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "demo" {
  count               = "${var.bootcamp_instances}"
  name                = "bootcamp-interface-${count.index}"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.demo.name}"

  ip_configuration {
    name                                    = "demo-ip-${count.index}"
    subnet_id                               = "${azurerm_subnet.demo.id}"
    private_ip_address_allocation           = "dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.demo.id}"]
  }
}

resource "azurerm_lb" "demo" {
  name                = "bootcamp-lb"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.demo.name}"

  frontend_ip_configuration {
    name                          = "default"
    public_ip_address_id          = "${azurerm_public_ip.demo.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_lb_rule" "demo" {
  name                    = "bootcamp-lb-rule-80-8080"
  resource_group_name     = "${azurerm_resource_group.demo.name}"
  loadbalancer_id         = "${azurerm_lb.demo.id}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.demo.id}"
  probe_id                = "${azurerm_lb_probe.demo.id}"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 8080
  frontend_ip_configuration_name = "default"
}

resource "azurerm_lb_probe" "demo" {
  name                = "bootcamp-lb-probe-8080-up"
  loadbalancer_id     = "${azurerm_lb.demo.id}"
  resource_group_name = "${azurerm_resource_group.demo.name}"
  protocol            = "Http"
  request_path        = "/"
  port                = 8080
}

resource "azurerm_lb_backend_address_pool" "demo" {
  name                = "bootcamp-lb-pool"
  resource_group_name = "${azurerm_resource_group.demo.name}"
  loadbalancer_id     = "${azurerm_lb.demo.id}"
}

resource "azurerm_availability_set" "demo" {
  name                = "bootcamp-availability-set"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.demo.name}"
}

resource "azurerm_storage_account" "demo" {
  name                = "bootcamp2017storage"
  resource_group_name = "${azurerm_resource_group.demo.name}"
  location            = "${var.azure_location}"
  account_type        = "Standard_LRS"
}

resource "azurerm_storage_container" "demo" {
  count                 = "${var.bootcamp_instances}"
  name                  = "bootcamp-storage-container-${count.index}"
  resource_group_name   = "${azurerm_resource_group.demo.name}"
  storage_account_name  = "${azurerm_storage_account.demo.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "demo" {
  count                 = "${var.bootcamp_instances}"
  name                  = "bootcamp-instance-${count.index}"
  location              = "${var.azure_location}"
  resource_group_name   = "${azurerm_resource_group.demo.name}"
  network_interface_ids = ["${element(azurerm_network_interface.demo.*.id, count.index)}"]
  vm_size               = "Standard_A0"
  availability_set_id   = "${azurerm_availability_set.demo.id}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "bootcamp-disk-${count.index}"
    vhd_uri       = "${azurerm_storage_account.demo.primary_blob_endpoint}${element(azurerm_storage_container.demo.*.name, count.index)}/bootcamp.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "bootcamp-instance-${count.index}"
    admin_username = "bootcamp"
    admin_password = "${var.bootcamp_admin_password}"
	custom_data    = "${base64encode(file("${path.module}/provision.sh"))}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
