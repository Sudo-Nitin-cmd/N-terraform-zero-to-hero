provider "aws"{
	region = "us-east-1"
}

variable cidr{
	default = "10.0.0.0/16"
}

resource "aws_key_pair" "example_keypair"{
	key_name = "terraform-day5-demo"
	public_key = file("C:\\Users\\Admin\\.ssh\\id_rsa.pub")
}

resource "aws_vpc" "day5vpc"{
	cidr_block = var.cidr
}

resource "aws_subnet" "day5subnet"{
	vpc_id = aws_vpc.day5vpc.id
	cidr_block = "10.0.0.0/24"
	availability_zone = "us-east-1a"
	map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "day5igw"{
	vpc_id = aws_vpc.day5vpc.id
}

resource "aws_route_table" "day5rt"{
	vpc_id = aws_vpc.day5vpc.id

	route{
	cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.day5igw.id
	}
}

resource "aws_route_table_association" "day5rta"{
	subnet_id = aws_subnet.day5subnet.id
	route_table_id = aws_route_table.day5rt.id
}

resource "aws_security_group" "day5websg"{
	name = "day5web"
	vpc_id = aws_vpc.day5vpc.id

ingress{
	description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

ingress{
	description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
  Name = "web-day5-sg"
  }
}



resource "aws_instance" "day5server" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = "t2.micro"
  key_name      = aws_key_pair.example_keypair.key_name
  vpc_security_group_ids = [aws_security_group.day5websg.id]
  subnet_id              = aws_subnet.day5subnet.id

  connection {
    type        = "ssh"
    user        = "ubuntu"  # Replace with the appropriate username for your EC2 instance
    private_key = file("C:\\Users\\Admin\\.ssh\\id_rsa")  # Replace with the path to your private key
    host        = self.public_ip
  }

  # File provisioner to copy a file from local to the remote EC2 instance
  provisioner "file" {
    source      = "H:\\AWS Docs\\AV\\Day5_terraform\\app.py"  # Replace with the path to your local file
    destination = "/home/ubuntu/app.py"  # Replace with the path on the remote instance
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",  # Update package lists (for ubuntu)
      "sudo apt-get install -y python3-pip",  # Example package installation
      "cd /home/ubuntu",
      "sudo pip3 install flask",
      "sudo python3 app.py",
    ]
  }
}

