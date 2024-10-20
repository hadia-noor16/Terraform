output "alb_dns_name" {
  value = aws_lb.myalb.dns_name
}

output "rds_endpoint" {
    value = aws_db_instance.two-tier-rds.endpoint
} 

output "alb_id" {
    value = aws_lb.myalb.id
}