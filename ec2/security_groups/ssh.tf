resource "aws_security_group" "sg_ssh" {
  # Make sure the name of the security groups are added to the variables file under terraform/ec2/instances/variables.tf
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