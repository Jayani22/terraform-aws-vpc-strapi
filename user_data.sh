#!/bin/bash
yum update -y
yum install docker -y
systemctl start docker
systemctl enable docker

docker pull ${docker_image}
docker run -d -p 1337:1337 ${docker_image}
