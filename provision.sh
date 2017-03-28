#!/bin/sh
sudo curl -sSL https://get.docker.com/ | sh
docker run --detach --publish 8080:8080 drhelius/terraform-azure-bootcamp-2017
