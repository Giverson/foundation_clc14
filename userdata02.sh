#!/bin/bash

# Atualiza pacotes e instala o Apache
sudo su -
yum update -y
yum install -y httpd

# Habilita e inicia o Apache
systemctl enable httpd
systemctl start httpd

# Função para obter token do IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Obtém informações com o token IMDSv2
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
IMAGE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/ami-id)
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)
HOSTNAME=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/hostname)

# Cria página HTML com estilo moderno
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Informações da Instância EC2 - Servidor 2</title>
    <style>
        body {
            background: linear-gradient(to right, #4faffe, #00f2fe);
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            color: #333;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
        }
        .card {
            background: white;
            padding: 30px 50px;
            border-radius: 10px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
            text-align: center;
            max-width: 500px;
        }
        h1 {
            color: #2c3e50;
            margin-bottom: 20px;
        }
        p {
            font-size: 18px;
            margin: 10px 0;
        }
        .footer {
            margin-top: 20px;
            font-size: 14px;
            color: #777;
        }
    </style>
</head>
<body>
    <div class="card">
        <h1>Servidor 2 - Instância EC2</h1>
        <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
        <p><strong>Image ID (AMI):</strong> $IMAGE_ID</p>
        <p><strong>IP Público:</strong> $PUBLIC_IP</p>
        <p><strong>Hostname:</strong> $HOSTNAME</p>
        <div class="footer">Powered by Amazon EC2</div>
    </div>
</body>
</html>
EOF
