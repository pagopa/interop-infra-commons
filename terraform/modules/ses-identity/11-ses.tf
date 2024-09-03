resource "aws_sesv2_configuration_set" "this" {
  configuration_set_name = format("%s-config", replace(var.ses_identity_name, ".", "-"))

  delivery_options {
    tls_policy = "REQUIRE"
  }

  reputation_options {
    reputation_metrics_enabled = true
  }
}

resource "aws_sesv2_configuration_set_event_destination" "this" {
  configuration_set_name = aws_sesv2_configuration_set.this.configuration_set_name
  event_destination_name = format("%s-cloudwatch", aws_sesv2_configuration_set.this.configuration_set_name)

  event_destination {
    cloud_watch_destination {
      dimension_configuration {
        default_dimension_value = var.ses_identity_name
        dimension_name          = "ses:from-domain"
        dimension_value_source  = "MESSAGE_TAG"
      }
    }

    enabled              = true
    matching_event_types = ["BOUNCE", "COMPLAINT", "REJECT", "SEND"]
  }
}

resource "aws_sesv2_email_identity" "this" {
  email_identity         = var.ses_identity_name
  configuration_set_name = aws_sesv2_configuration_set.this.configuration_set_name

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }
}

resource "aws_route53_record" "dkim" {
  count = 3

  zone_id = var.hosted_zone_id
  name    = format("%s._domainkey.%s", aws_sesv2_email_identity.this.dkim_signing_attributes[0].tokens[count.index], aws_sesv2_email_identity.this.email_identity)
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_sesv2_email_identity.this.dkim_signing_attributes[0].tokens[count.index]}.dkim.eu-south-1.amazonses.com"]
}

resource "aws_sesv2_email_identity_mail_from_attributes" "this" {
  email_identity = aws_sesv2_email_identity.this.email_identity

  behavior_on_mx_failure = "REJECT_MESSAGE"
  mail_from_domain       = "mail.${aws_sesv2_email_identity.this.email_identity}"
}

resource "aws_route53_record" "spf" {
  zone_id = var.hosted_zone_id
  name    = aws_sesv2_email_identity_mail_from_attributes.this.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "mx" {
  zone_id = var.hosted_zone_id
  name    = aws_sesv2_email_identity_mail_from_attributes.this.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"]
}
