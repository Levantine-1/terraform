resource "aws_security_group" "sg_wireguard" {
  # Make sure the name of the security groups are added to the variables file under terraform/ec2/instances/variables.tf
  name        = "wireguard"
  description = "Wireguard VPN Traffic"

  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WireGuard's own handshake is the security boundary, not source IP -- needs to be reachable from anywhere
  }

    ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"] # WireGuard's own handshake is the security boundary, not source IP -- needs to be reachable from anywhere
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}