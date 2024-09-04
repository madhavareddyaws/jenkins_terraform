provider "aws" {
  region = "us-east-1"  # Change this to your desired AWS region
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins_key_new"
  public_key = file("/Users/deslypeter/IdeaProjects/Jenkins/jenkins_key.pub")  # Replace with the path to your public key
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins"
  description = "Allow SSH and Jenkins ports"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH access from anywhere (restrict this in production)
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Jenkins access from anywhere (restrict this in production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins_instance" {
  ami           = "ami-066784287e358dad1"  # Amazon Linux 2 AMI (replace with the right AMI ID for your region)
  instance_type = "t2.micro"               # You can choose a bigger instance if necessary
  key_name      = aws_key_pair.jenkins_key.key_name
  security_groups = [aws_security_group.jenkins_sg.name]

  # User data script to install Jenkins
  user_data = <<-EOF
              #!/bin/bash
              echo "Updating system" >> /var/log/user_data.log
              sudo yum update -y >> /var/log/user_data.log 2>&1

              echo "Adding Jenkins repository" >> /var/log/user_data.log
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo >> /var/log/user_data.log 2>&1

              echo "Importing Jenkins GPG key" >> /var/log/user_data.log
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key >> /var/log/user_data.log 2>&1

              echo "Upgrading system packages" >> /var/log/user_data.log
              sudo yum upgrade -y >> /var/log/user_data.log 2>&1

              echo "Installing Java (Amazon Corretto 17)" >> /var/log/user_data.log
              sudo dnf install java-17-amazon-corretto -y >> /var/log/user_data.log 2>&1

              echo "Installing Jenkins" >> /var/log/user_data.log
              sudo yum install jenkins -y >> /var/log/user_data.log 2>&1

              echo "Enabling Jenkins to start at boot" >> /var/log/user_data.log
              sudo systemctl enable jenkins >> /var/log/user_data.log 2>&1

              echo "Starting Jenkins service" >> /var/log/user_data.log
              sudo systemctl start jenkins >> /var/log/user_data.log 2>&1

              echo "User data script complete" >> /var/log/user_data.log
  EOF

  tags = {
    Name = "JenkinsServer"
  }
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins_instance.public_ip}:8080"
  description = "Jenkins URL"
}
