output "zone_id" {
  description = "ID of the private hosted zone"
  value       = aws_route53_zone.this.zone_id
}

output "zone_name" {
  description = "Name of the private hosted zone"
  value       = aws_route53_zone.this.name
}

output "zone_arn" {
  description = "ARN of the private hosted zone"
  value       = aws_route53_zone.this.arn
}
