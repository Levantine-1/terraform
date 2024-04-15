resource "aws_security_group" "sg_http" {
  # Make sure the name of the security groups are added to the variables file under terraform/ec2/instances/variables.tf
  name        = "http_https"
  description = "HTTP Traffic on Port 80 and HTTPS Traffic on Port 443"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}