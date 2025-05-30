variable "aws_region" {
  description = "Região da AWS para provisionar os recursos"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Tipo de instância EC2 para Linux"
  type        = string
  default     = "t3.micro"
}

variable "ami_id_linux" {
  description = "ID da AMI Linux a ser usada"
  type        = string
  default     = "ami-0953476d60561c955" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type (us-east-1)
}

variable "key_name_linux" {
  description = "Nome do par de chaves EC2 para Linux"
  type        = string
  default     = "access_linux"
}

variable "sg_name_linux" {
  description = "Nome do Security Group para Linux"
  type        = string
  default     = "webserver-instances-sg"
}

variable "instance1_name" {
  description = "Nome da primeira instância EC2 Linux"
  type        = string
  default     = "webserver-instance-1"
}

variable "instance2_name" {
  description = "Nome da segunda instância EC2 Linux"
  type        = string
  default     = "webserver-instance-2"
}

variable "domain_name" {
  description = "Nome do domínio para a zona privada Route 53 e bucket S3"
  type        = string
  default     = "caiosantos.clc14.foundation.com.br"
}

variable "health_check_name" {
  description = "Nome do Health Check do Route 53"
  type        = string
  default     = "webserver-hc"
}

# --- Windows Instance Variables ---
variable "windows_instance_name" {
  description = "Nome da instância EC2 Windows"
  type        = string
  default     = "windows-server-instance-1"
}

variable "windows_instance_type" {
  description = "Tipo de instância EC2 para Windows"
  type        = string
  default     = "t3.medium" # Windows generally requires more resources than Linux
}

variable "windows_ami_parameter_path" {
  description = "Caminho do AWS Systems Manager Parameter Store para a AMI mais recente do Windows Server 2022 Base"
  type        = string
  default     = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base"
}

variable "key_name_windows" {
  description = "Nome do par de chaves EC2 para Windows"
  type        = string
  default     = "access_windows"
}

variable "sg_name_windows" {
  description = "Nome do Security Group para Windows (RDP)"
  type        = string
  default     = "windows-rdp-sg"
}

