terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- VPC (Using Default) ---
data "aws_vpc" "default" {
  default = true
}

# --- Create keys directory ---
resource "null_resource" "create_keys_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ./keys && chmod 700 ./keys"
  }
}

# --- Linux Key Pair ---
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name_linux
  public_key = tls_private_key.pk.public_key_openssh

  # Save the private key in the keys directory
  provisioner "local-exec" {
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./keys/${var.key_name_linux}.pem && chmod 400 ./keys/${var.key_name_linux}.pem"
  }

  depends_on = [null_resource.create_keys_dir]
}

# --- Linux Security Group ---
resource "aws_security_group" "webserver_sg" {
  name        = var.sg_name_linux
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg_name_linux
  }
}

# --- EC2 Instances ---
resource "aws_instance" "webserver_1" {
  ami                    = var.ami_id_linux
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
  user_data              = file("${path.module}/userdata01.sh")

  tags = {
    Name = var.instance1_name
  }
}

resource "aws_instance" "webserver_2" {
  ami                    = var.ami_id_linux
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
  user_data              = file("${path.module}/userdata02.sh")

  tags = {
    Name = var.instance2_name
  }
}

# --- Elastic IPs ---
resource "aws_eip" "eip_1" {
  instance = aws_instance.webserver_1.id
  domain   = "vpc" # Updated from 'vpc = true'
  tags = {
    Name = "${var.instance1_name}-eip"
  }
}

resource "aws_eip" "eip_2" {
  instance = aws_instance.webserver_2.id
  domain   = "vpc" # Updated from 'vpc = true'
  tags = {
    Name = "${var.instance2_name}-eip"
  }
}

# --- S3 Bucket for Website (ACLs Disabled Configuration) ---
resource "aws_s3_bucket" "website_bucket" {
  bucket = "www.${var.domain_name}"
}

resource "aws_s3_bucket_ownership_controls" "website_bucket_ownership" {
  bucket = aws_s3_bucket.website_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "website_bucket_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false

  depends_on = [aws_s3_bucket_ownership_controls.website_bucket_ownership]
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website_bucket_access]
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
}

# --- Route 53 Private Zone ---
resource "aws_route53_zone" "private_zone" {
  name = var.domain_name

  vpc {
    vpc_id = data.aws_vpc.default.id
  }

  tags = {
    Name = "${var.domain_name}-private-zone"
  }
}

# --- Route 53 Health Check (Corrected: Using ip_address) ---
resource "aws_route53_health_check" "webserver_hc" {
  ip_address        = aws_eip.eip_1.public_ip # Corrected: Use ip_address instead of fqdn
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "10"

  tags = {
    Name = var.health_check_name
  }
}

# --- Route 53 Records (Failover) ---
resource "aws_route53_record" "www_primary" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "webserver-1-primary"
  health_check_id = aws_route53_health_check.webserver_hc.id
  ttl             = 60
  records         = [aws_eip.eip_1.public_ip]
}

# Corrected S3 alias record reference
resource "aws_route53_record" "www_secondary" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "s3-website-secondary"
  alias {
    # Corrected: Ensure 'name' points to the S3 website endpoint
    name                   = aws_s3_bucket_website_configuration.website_config.website_endpoint
    zone_id                = aws_s3_bucket.website_bucket.hosted_zone_id
    evaluate_target_health = false
  }
}

# --- Windows Key Pair ---
resource "tls_private_key" "pk_windows" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key_windows" {
  key_name   = var.key_name_windows
  public_key = tls_private_key.pk_windows.public_key_openssh

  # Save the private key in the keys directory
  provisioner "local-exec" {
    command = "echo '${tls_private_key.pk_windows.private_key_pem}' > ./keys/${var.key_name_windows}.pem && chmod 400 ./keys/${var.key_name_windows}.pem"
  }

  depends_on = [null_resource.create_keys_dir]
}

# --- Windows Security Group (RDP) ---
resource "aws_security_group" "windows_rdp_sg" {
  name        = var.sg_name_windows
  description = "Allow RDP inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "RDP from anywhere"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg_name_windows
  }
}

# --- Windows EC2 Instance (com AMI fornecida pelo usuário) ---
resource "aws_instance" "windows_server_1" {
  ami                    = "ami-0fa71268a899c2733" # AMI do Windows Server fornecida pelo usuário
  instance_type          = var.windows_instance_type
  key_name               = aws_key_pair.generated_key_windows.key_name
  vpc_security_group_ids = [aws_security_group.windows_rdp_sg.id]
  # No user data specified for Windows instance

  tags = {
    Name = var.windows_instance_name
  }
}

# --- Elastic IP for Windows Instance ---
resource "aws_eip" "eip_windows" {
  instance = aws_instance.windows_server_1.id
  domain   = "vpc"
  tags = {
    Name = "${var.windows_instance_name}-eip"
  }
}
