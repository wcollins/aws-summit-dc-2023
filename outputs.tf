output "public_ips" {
  description = "Public IP of each ec2 instance"
  value       = { for k, v in aws_instance.this : k => v.public_ip }
}

output "private_ips" {
  description = "Private IP of each ec2 instance"
  value       = { for k, v in aws_instance.this : k => v.private_ip }
}