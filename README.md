# foundation_clc14Terraform AWS Infrastructure

Este repositório contém a configuração Terraform para provisionar uma infraestrutura completa na AWS, incluindo instâncias EC2 Linux e Windows, VPC, Elastic IPs, Security Groups, Route 53, e S3 para hospedagem de site estático.

Pré-requisitos

•
Terraform (versão 1.0.0 ou superior)

•
AWS CLI configurado com credenciais válidas

•
Git (para clonar o repositório)

Configuração Inicial

1. Clone o Repositório

Bash


git clone <URL_DO_REPOSITORIO>
cd terraform_aws_infra


2. Inicialize o Terraform

Bash


terraform init


Este comando baixará os providers necessários (AWS e TLS) e inicializará o diretório de trabalho.

Personalização (Opcional)

Antes de aplicar a configuração, você pode personalizar os seguintes arquivos:

•
variables.tf: Contém variáveis como região, tipos de instância, AMIs, etc.

•
userdata01.sh e userdata02.sh: Scripts de inicialização para as instâncias Linux

•
index.html: Página HTML para o bucket S3

Aplicando a Configuração

1. Visualize o Plano de Execução

Bash


terraform plan


Este comando mostrará todas as alterações que serão feitas na sua conta AWS.

2. Aplique a Configuração

Bash


terraform apply


Quando solicitado, digite yes para confirmar a criação dos recursos.

Importante: Este comando criará recursos na sua conta AWS que podem gerar custos.

3. Arquivos de Chave Privada

Após a execução bem-sucedida, dois arquivos de chave privada serão gerados no diretório de trabalho:

•
access_linux.pem: Para acesso SSH às instâncias Linux

•
access_windows.pem: Para obter a senha de administrador da instância Windows

Certifique-se de proteger adequadamente esses arquivos:

Bash


chmod 400 access_linux.pem
chmod 400 access_windows.pem


Acessando as Instâncias

Instâncias Linux

1.
Obtenha o IP público da instância:

Bash


terraform output instance1_public_ip
terraform output instance2_public_ip


1.
Conecte-se via SSH:

Bash


ssh -i access_linux.pem ec2-user@<IP_PUBLICO>


Instância Windows

1.
Obtenha o IP público da instância:

Bash


terraform output windows_instance_public_ip


1.
Obtenha a senha de administrador:

•
Acesse o Console AWS > EC2 > Instâncias

•
Selecione a instância Windows

•
Clique em "Conectar" > "RDP Client"

•
Clique em "Obter senha"

•
Faça upload do arquivo access_windows.pem

•
Copie a senha descriptografada



2.
Conecte-se via RDP usando o IP público e a senha obtida

Testando o Health Check

O Route 53 está configurado com um health check para monitorar a instância webserver-instance-1. Para testar:

1.
Verifique se a instância está respondendo via HTTP:

Bash


curl http://$(terraform output -raw instance1_public_ip)


1.
Verifique o status do health check no Console AWS:

•
Acesse o Console AWS > Route 53 > Health checks

•
Localize o health check com o nome webserver-hc

•
Verifique o status (deve estar "Healthy")



2.
Teste o failover:

•
Pare a instância webserver-instance-1 temporariamente

•
Observe o health check mudar para "Unhealthy"

•
Acesse o domínio configurado - o tráfego deve ser redirecionado para o bucket S3

•
Inicie a instância novamente e aguarde o health check voltar para "Healthy"



Estrutura do Projeto

•
main.tf: Definição principal dos recursos AWS

•
variables.tf: Declaração de variáveis

•
outputs.tf: Saídas úteis após a aplicação

•
userdata01.sh e userdata02.sh: Scripts de inicialização para as instâncias Linux

•
index.html: Página HTML para o bucket S3

Recursos Criados

•
VPC (usa a VPC padrão)

•
2 instâncias EC2 Linux com Apache

•
1 instância EC2 Windows Server

•
3 Elastic IPs (uma para cada instância)

•
Security Group para SSH e HTTP

•
Security Group para RDP

•
Bucket S3 configurado para hospedagem de site estático

•
Zona hospedada privada no Route 53

•
Health check e registros de failover no Route 53

Limpeza

Para evitar cobranças contínuas, destrua os recursos quando não forem mais necessários:

Bash


terraform destroy


Quando solicitado, digite yes para confirmar a exclusão dos recursos.

Solução de Problemas

Erro de Permissão do Parameter Store

Se você encontrar um erro relacionado ao acesso ao Parameter Store:

Plain Text


Error: reading SSM Parameter (/aws/service/ami-windows-latest/...): AccessDeniedException


A configuração já foi ajustada para usar um ID de AMI fixo para o Windows Server, evitando a necessidade de permissões adicionais.

Problemas de Conexão SSH

•
Verifique se o arquivo .pem tem as permissões corretas (chmod 400)

•
Verifique se o Security Group permite tráfego SSH da sua origem

•
Verifique se a instância está em execução

Problemas de Conexão RDP

•
Verifique se o Security Group permite tráfego RDP da sua origem

•
Verifique se a instância está em execução

•


