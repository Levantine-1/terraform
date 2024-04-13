resource "aws_security_group" "sg_wireguard" {
  # Make sure the name of the security groups are added to the variables file under terraform/ec2/instances/variables.tf
  name        = "wireguard"
  description = "Wireguard VPN Traffic"

  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "tcp"
    cidr_blocks = ["76.102.71.37/32"]
  }

    ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["76.102.71.37/32"]
  }
}