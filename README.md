# Terraform AWS Infrastructure

Este repositório contém a configuração Terraform para provisionar uma infraestrutura completa na AWS, incluindo instâncias EC2 Linux e Windows, VPC, Elastic IPs, Security Groups, Route 53, e S3 para hospedagem de site estático.

## Pré-requisitos

- [Terraform](https://www.terraform.io/downloads.html) (versão 1.0.0 ou superior)
- [AWS CLI](https://aws.amazon.com/cli/) configurado com credenciais válidas
- Git (para clonar o repositório)

## Configuração Inicial

### 1. Clone o Repositório

```bash
git clone <URL_DO_REPOSITORIO>
cd terraform_aws_infra
```

### 2. Inicialize o Terraform

```bash
terraform init
```

Este comando baixará os providers necessários (AWS, TLS e Null) e inicializará o diretório de trabalho.

## Personalização (Opcional)

Antes de aplicar a configuração, você pode personalizar os seguintes arquivos:

- **variables.tf**: Contém variáveis como região, tipos de instância, AMIs, etc.
- **userdata01.sh** e **userdata02.sh**: Scripts de inicialização para as instâncias Linux
- **index.html**: Página HTML para o bucket S3

## Aplicando a Configuração

### 1. Visualize o Plano de Execução

```bash
terraform plan
```

Este comando mostrará todas as alterações que serão feitas na sua conta AWS.

### 2. Aplique a Configuração

```bash
terraform apply
```

Quando solicitado, digite `yes` para confirmar a criação dos recursos.

> **Importante**: Este comando criará recursos na sua conta AWS que podem gerar custos.

### 3. Arquivos de Chave Privada

Após a execução bem-sucedida, dois arquivos de chave privada serão gerados no diretório `./keys/`:

- `./keys/access_linux.pem`: Para acesso SSH às instâncias Linux
- `./keys/access_windows.pem`: Para obter a senha de administrador da instância Windows

Certifique-se de proteger adequadamente esses arquivos:

```bash
chmod 400 ./keys/access_linux.pem
chmod 400 ./keys/access_windows.pem
```

## Acessando as Instâncias

### Instâncias Linux

1. Obtenha o IP público da instância:

```bash
terraform output instance1_public_ip
terraform output instance2_public_ip
```

2. Conecte-se via SSH:

```bash
ssh -i ./keys/access_linux.pem ec2-user@<IP_PUBLICO>
```

### Instância Windows

1. Obtenha o IP público da instância:

```bash
terraform output windows_instance_public_ip
```

2. Obtenha a senha de administrador:
   - Acesse o Console AWS > EC2 > Instâncias
   - Selecione a instância Windows
   - Clique em "Conectar" > "RDP Client"
   - Clique em "Obter senha"
   - Faça upload do arquivo `./keys/access_windows.pem`
   - Copie a senha descriptografada

3. Conecte-se via RDP usando o IP público e a senha obtida

## Testando o Health Check

O Route 53 está configurado com um health check para monitorar a instância `webserver-instance-1`. Para testar:

1. Verifique se a instância está respondendo via HTTP:

```bash
curl http://$(terraform output -raw instance1_public_ip)
```

2. Verifique o status do health check no Console AWS:
   - Acesse o Console AWS > Route 53 > Health checks
   - Localize o health check com o nome `webserver-hc`
   - Verifique o status (deve estar "Healthy")

3. Teste o failover:
   - Pare a instância `webserver-instance-1` temporariamente
   - Observe o health check mudar para "Unhealthy"
   - Acesse o domínio configurado - o tráfego deve ser redirecionado para o bucket S3
   - Inicie a instância novamente e aguarde o health check voltar para "Healthy"

## Estrutura do Projeto

- **main.tf**: Definição principal dos recursos AWS
- **variables.tf**: Declaração de variáveis
- **outputs.tf**: Saídas úteis após a aplicação
- **userdata01.sh** e **userdata02.sh**: Scripts de inicialização para as instâncias Linux
- **index.html**: Página HTML para o bucket S3
- **./keys/**: Diretório onde as chaves privadas são armazenadas

## Recursos Criados

- VPC (usa a VPC padrão)
- 2 instâncias EC2 Linux com Apache
- 1 instância EC2 Windows Server
- 3 Elastic IPs (uma para cada instância)
- Security Group para SSH e HTTP
- Security Group para RDP
- Bucket S3 configurado para hospedagem de site estático
- Zona hospedada privada no Route 53
- Health check e registros de failover no Route 53

## Limpeza

Para evitar cobranças contínuas, destrua os recursos quando não forem mais necessários:

```bash
terraform destroy
```

Quando solicitado, digite `yes` para confirmar a exclusão dos recursos.

## Solução de Problemas

### Erro de Permissão ao Criar Arquivos .pem

Se você encontrar erros de permissão ao criar os arquivos .pem:

```
Error: local-exec provisioner error - cannot create ./access_linux.pem: Permission denied
```

A configuração já foi ajustada para criar um diretório `./keys/` com as permissões corretas. Certifique-se de que o usuário que executa o Terraform tenha permissão para criar diretórios e arquivos no diretório de trabalho.

### Erro de Autorização da AMI

Se você encontrar erros relacionados à autorização da AMI:

```
Error: AuthFailure: Not authorized for images: [ami-xxxxxxxxx]
```

A configuração já foi ajustada para usar uma AMI pública do Windows Server que sua conta tem acesso. Se o problema persistir, verifique se a AMI ainda está disponível ou forneça outra AMI válida.

### Problemas de Conexão SSH

- Verifique se o arquivo .pem tem as permissões corretas (chmod 400)
- Verifique se o Security Group permite tráfego SSH da sua origem
- Verifique se a instância está em execução

### Problemas de Conexão RDP

- Verifique se o Security Group permite tráfego RDP da sua origem
- Verifique se a instância está em execução
- Verifique se a senha foi obtida corretamente usando o arquivo .pem correto
