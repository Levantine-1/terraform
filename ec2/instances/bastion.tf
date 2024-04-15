resource "aws_instance" "bastion_instance" {
  ami                    = "ami-0c2644caf041bb6de" // Debian 12 (HVM), SSD Volume Type
  instance_type          = "t3a.nano"
  key_name               = "automation"
  subnet_id              = data.aws_subnets.default_subnets.ids[0]
  vpc_security_group_ids = [data.aws_security_group.ssh.id, data.aws_security_group.http_https.id, data.aws_security_group.wireguard.id]
  tags = {
    Name = "Bastion"
  }
  user_data = file("${path.module}/scripts/user_data.sh")
}

resource "aws_eip" "bastion_instance_eip" {
  instance = aws_instance.bastion_instance.id
  tags = {
    Name = "Bastion"
  }
}

resource "aws_route53_record" "configure_bastion_r53_record_levantine_io" {
  zone_id = data.aws_route53_zone.levantine_io_tld.zone_id
  name    = "bastion.${var.environment}.levantine.io"
  type    = "A"
  ttl     = 300
  records = [aws_eip.bastion_instance_eip.public_ip]
}

resource "aws_route53_record" "configure_bastion_r53_record_nhitruong_com" {
  zone_id = data.aws_route53_zone.nhitruong_com_tld.zone_id
  name    = "bastion.${var.environment}.nhitruong.com"
  type    = "A"
  ttl     = 300
  records = [aws_eip.bastion_instance_eip.public_ip]
}

# Only create this Address Record in the prod environment
resource "aws_route53_record" "create_prod_redirect_record_levantine_io" {
  provider = aws.delegate
  count   = var.environment == "prod" ? 1 : 0
  name    = "levantine.io"
  zone_id = var.levantine_io_hosted_zone_id
  type    = "A"
  ttl     = 300
  records = [aws_eip.bastion_instance_eip.public_ip]
}

# Only create this Address Record in the prod environment
resource "aws_route53_record" "create_prod_redirect_record_nhitruong_com" {
  provider = aws.delegate
  count   = var.environment == "prod" ? 1 : 0
  name    = "nhitruong.com"
  zone_id = var.nhitruong_com_hosted_zone_id
  type    = "A"
  ttl     = 300
  records = [aws_eip.bastion_instance_eip.public_ip]
}
