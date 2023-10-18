packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "source_ami" {
  type    = string
  default = "ami-06db4d78cb1d3bbf9"
}

variable "ssh_username" {
  type    = string
  default = "admin"
}

variable "subnet_id" {
  type    = string
  default = "subnet-0b715170798cb04be"
}

# https://www.packer.io/plugins/builders/amazon/ebs
source "amazon-ebs" "my-ami" {
  region          = "${var.aws_region}"
  profile         = "github"
  ami_name        = "csye6225_${formatdate("YYYY_MM_DD_hh_mm_ss", timestamp())}"
  ami_description = "AMI for CSYE 6225"
  ami_regions = [
    "us-east-1",
  ]

  aws_polling {
    delay_seconds = 120
    max_attempts  = 50
  }

  instance_type = "t2.micro"
  source_ami    = "${var.source_ami}"
  ssh_username  = "${var.ssh_username}"
  subnet_id     = "${var.subnet_id}"

  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    volume_size           = 8
    volume_type           = "gp2"
  }
}

build {
  sources = ["source.amazon-ebs.my-ami"]

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "CHECKPOINT_DISABLE=1"
    ]
    inline = [
      "sudo apt update",
      "sudo apt install -y mariadb-server",
      "sudo systemctl start mariadb",
      "sudo systemctl enable mariadb",
      "sudo mysql -u root <<EOF",
      "ALTER USER 'root'@'localhost' IDENTIFIED BY 'Vani@1972';",
      "FLUSH PRIVILEGES;",
      "EOF",
      "sudo apt update",
      "sudo apt install -y nodejs npm",
      "node -v",
      "npm -v",
      "mkdir -p webapp/dist"
    ]
  }
  provisioner "file" {
    //source      = "package.json"  
    source      = fileexists("package.json") ? "package.json" : "/" # Local path to the files to be copied
    destination = "/home/admin/webapp/package.json"                 # Destination path on the AMI
  }
  provisioner "file" {
    //source      = "dist/main.js"  
    source      = fileexists("dist/main.js") ? "dist/main.js" : "/" # Local path to the files to be copied
    destination = "/home/admin/webapp/dist/main.js"                 # Destination path on the AMI
  }

provisioner "file" {
    //source      = ".env" 
    source      = fileexists(".env") ? ".env" : "/" # Local path to the files to be copied
    destination = "/home/admin/webapp/.env"         # Destination path on the AMI
  }
}

