aws_region = "us-east-1"
environment = "dev"
vpc_cidr = "10.0.0.0/16"

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnet_cidrs = [
  "10.0.101.0/24",
  "10.0.102.0/24"
]

allowed_ssh_cidr = "106.200.31.185/32"
instance_type = "t3.micro"
key_pair_name = "strapi-key-dev"
ecr_repo_name = "strapi-app"

app_keys         = "key1,key2,key3,key4"
admin_jwt_secret = "373dbbbe98c3da409099d9328181a5a650c3ca269a3dc90b9cd7f68a511020fd"
jwt_secret       = "51e6f46047d0c63fe886111086991cd1eeac9d5fd2146810ed5a6a9fab96c8b1"
api_token_salt   = "a1750bd87cdcfa152e82dd2fb82364447efd05ac33974106cb8305c8da49e664"