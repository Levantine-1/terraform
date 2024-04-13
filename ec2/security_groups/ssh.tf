resource "aws_security_group" "sg_ssh" {
  name        = "ssh"
  description = "SSH Traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["76.102.71.37/32", "204.102.74.33/32"]
    # [ "House internet" , "Chinatown Library SF" ]
  }
}