resource "aws_security_group" "sg_ssh" {
  # Make sure the name of the security groups are added to the variables file under terraform/ec2/instances/variables.tf
  name        = "ssh"
  description = "SSH Traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["24.4.63.140/32"]
    description = "House internet"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}