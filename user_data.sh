#!/bin/bash
set -xe

dnf update -y

dnf install -y docker

systemctl start docker
systemctl enable docker

docker run -d \
  -p 1337:1337 \
  -e HOST=0.0.0.0 \
  -e PORT=1337 \
  --name strapi \
  ghcr.io/strapi/strapi:4