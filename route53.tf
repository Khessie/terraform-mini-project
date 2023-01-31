resource "aws_route53_zone" "hosted-zone" {
  name = var.domain_name

  tags = {
    Environmnet = "dev"
  }

}

resource "aws_route53_record" "record" {
  zone_id = aws_route53_zone.hosted-zone.zone_id
  name    = "terraform-test.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.load-balancer.dns_name
    zone_id                = aws_lb.load-balancer.zone_id
    evaluate_target_health = true
  }
}
