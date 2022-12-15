# provider is plugin used for AWS access
provider "aws" {
  region  = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}


# we have to update these as per user
variable "aws_access_key" {
  type        = string
  description = "AWS Access Key. Programmable API access key needed for creating the site"
  default = ""
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Access Key. Programmable API secret access key needed for creating the site"
  default = ""
}

variable "aws_region" {
  type        = string
  description = "AWS region. Programmable API secret access key needed for creating the site"
  default = ""
}

variable "PRIVATE_KEY_PATH" {
  default = "aws-key.pem"
}
variable "PUBLIC_KEY_PATH" {
  default = "aws-key.pub"
}
variable "EC2_USER" {
  default = "ubuntu"
}

# below code is for creating resources
resource "aws_vpc" "nginx-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  instance_tenancy     = "default"
  tags = {
    Name = "apisecurity-waap-waf-VPC"
  }
}

resource "aws_subnet" "prod-subnet-public-1" {
  vpc_id                  = aws_vpc.nginx-vpc.id // Referencing the id of the VPC 
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true" // Makes this a public subnet
  availability_zone       = var.aws_region
}

resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.nginx-vpc.id
}

resource "aws_route_table" "prod-public-crt" {
	  vpc_id = aws_vpc.nginx-vpc.id
	  route {
		cidr_block = "0.0.0.0/0"                      //associated subnet can reach everywhere
		gateway_id = aws_internet_gateway.prod-igw.id //CRT uses this IGW to reach internet
	  }
	tags = {
		Name = "Automation-public-crt"
	  }
}

resource "aws_route_table_association" "prod-crta-public-subnet-1" {
  subnet_id      = aws_subnet.prod-subnet-public-1.id
  route_table_id = aws_route_table.prod-public-crt.id
}

resource "aws_security_group" "ssh-allowed" {
	vpc_id = aws_vpc.nginx-vpc.id
	egress {
		from_port   = 0
		to_port     = 0
		protocol    = -1
		cidr_blocks = ["0.0.0.0/0"]
	  }
	ingress {
		from_port = 22
		to_port   = 22
		protocol  = "tcp"
	cidr_blocks = ["0.0.0.0/0"] // Ideally best to use your machines' IP. However if it is dynamic you will need to change this in the vpc every so often. 
	  }
	ingress {
		from_port   = 80
		to_port     = 80
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	  }
        ingress {
		from_port   = 5320
		to_port     = 5320
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	  }
	ingress {
		from_port   = 5000
		to_port     = 5000
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	  }
}


resource "aws_key_pair" "aws-key" {
  key_name   = "aws-key"
  public_key = file("${path.module}/${var.PUBLIC_KEY_PATH}")
}

resource "aws_instance" "nginx_server" {
  ami           = var.ami
  instance_type = "t3.small"
  tags = {
    Name = "Automation_WAAP_WAF"
  }
  subnet_id = aws_subnet.prod-subnet-public-1.id
  vpc_security_group_ids = ["${aws_security_group.ssh-allowed.id}"]
  key_name = aws_key_pair.aws-key.id
  
  # need to update this file as per backend server
  provisioner "remote-exec" {
    inline = [
      "sudo pwd",
      "sudo apt install net-tools"
    ]
  }
  
# Setting up the ssh connection to install the nginx server
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("${path.module}/${var.PRIVATE_KEY_PATH}")
  }
}

# capture output of instance public IP to use it for origin pool
output ec2_public_ip {
  value = aws_instance.nginx_server.public_ip
}

