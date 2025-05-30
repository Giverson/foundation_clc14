output "instance1_public_ip" {
  description = "IP público da instância webserver-instance-1"
  value       = aws_eip.eip_1.public_ip
}

output "instance2_public_ip" {
  description = "IP público da instância webserver-instance-2"
  value       = aws_eip.eip_2.public_ip
}

output "s3_bucket_website_endpoint" {
  description = "Endpoint do site estático hospedado no S3"
  value       = aws_s3_bucket.website_bucket.website_endpoint
}

output "route53_private_zone_id" {
  description = "ID da zona hospedada privada do Route 53"
  value       = aws_route53_zone.private_zone.zone_id
}

output "linux_private_key_pem_file" {
  description = "Nome do arquivo PEM contendo a chave privada para acesso SSH às instâncias Linux. Salvo no diretório ./keys/"
  value       = "./keys/${var.key_name_linux}.pem"
}

output "windows_instance_id" {
  description = "ID da instância Windows Server"
  value       = aws_instance.windows_server_1.id
}

output "windows_instance_public_ip" {
  description = "IP público da instância Windows Server"
  value       = aws_eip.eip_windows.public_ip
}

output "windows_private_key_pem_file" {
  description = "Nome do arquivo PEM contendo a chave privada para obter a senha do Windows. Salvo no diretório ./keys/"
  value       = "./keys/${var.key_name_windows}.pem"
}
