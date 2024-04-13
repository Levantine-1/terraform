resource "aws_instance" "bastion_instance" {
  ami                    = "ami-0c2644caf041bb6de" // Debian 12 (HVM), SSD Volume Type
  instance_type          = "t3a.nano"
  key_name               = "automation"
  subnet_id              = data.aws_subnets.default_subnets.ids[0]
  vpc_security_group_ids = [data.aws_security_group.ssh.id, data.aws_security_group.http_https.id, data.aws_security_group.wireguard.id]
  tags = {
    Name = "Bastion"
  }
}

resource "aws_eip" "bastion_instance_eip" {
  instance = aws_instance.bastion_instance.id
}