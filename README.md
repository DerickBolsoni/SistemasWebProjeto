# 🍔 FastDelivery Tracker - Sistema de Entrega de Hamburgueria

Sistema serverless para gerenciamento e acompanhamento de entregas de pedidos de hamburgueria, desenvolvido com AWS (Lambda, API Gateway, DynamoDB e SNS).

## 📘 Descrição do Projeto

O FastDelivery Tracker é um sistema que permite registrar pedidos de hambúrguer, atualizar o status de entrega e notificar automaticamente o dono do restaurante quando o pedido é entregue. O projeto segue a arquitetura do The Best Burger App, com foco na parte de entrega e notificações automáticas via AWS SNS.

### Funcionalidades Principais:
- ✅ Criar pedidos de hambúrguer via API
- ✅ Marcar pedidos como entregues
- ✅ Notificações automáticas via SNS
- ✅ Geração de tokens de rastreamento
- ✅ Logs estruturados para monitoramento

## 🧱 Arquitetura

### Serviços AWS Utilizados:
- **API Gateway**: Expõe os endpoints HTTP
- **AWS Lambda**: Executa funções serverless (addOrder, setAsDelivered, notifyOwner)
- **DynamoDB**: Armazena dados dos pedidos e tokens
- **SNS (Simple Notification Service)**: Envia notificações quando um pedido muda de status
- **CloudWatch**: Armazena logs das funções Lambda

### Fluxo Simplificado:
1. **Cliente envia pedido** → `addOrder` → grava na tabela Orders
2. **Pedido é entregue** → `setAsDelivered` → atualiza status e publica mensagem no SNS Topic
3. **SNS notifica** → `notifyOwner` → grava token do dono na tabela Tokens

### Arquitetura Geral:
```
[Cliente / App Hamburgueria]
       ↓
[API Gateway REST]
       ↓
[Lambda Functions]
       ↓
[DynamoDB] ←→ [SNS Topic]
       ↓
[Notificação de Pedido / Entrega]
```

### Endpoints da API:
- **POST /add-order**: Criar novo pedido de hambúrguer
- **PUT /order/{order_id}/delivered**: Marcar pedido como entregue

## 🚀 Como Executar Localmente

### Pré-requisitos
- AWS CLI configurado com perfil `dev`
- Python 3.9+
- Permissões IAM adequadas
- Região AWS: `sa-east-1`

### Configuração Inicial

1. **Clone o repositório**
```bash
git clone <repository-url>
cd SistemasWebProjeto
```

2. **Configure AWS CLI**
```bash
aws configure --profile dev
# AWS Access Key ID: [SUA_ACCESS_KEY]
# AWS Secret Access Key: [SUA_SECRET_KEY]
# Default region name: sa-east-1
# Default output format: json
```

3. **Execute o setup inicial**
```bash
./scripts/setup.sh
```

4. **Deploy no ambiente DEV**
```bash
./scripts/deploy-dev.sh
```

### Fluxo Git (Requisito do Professor)

⚠️ **IMPORTANTE**: Seguir o fluxo Git correto para não perder pontos!

```bash
# 1. Criar branch pessoal
git checkout -b dev_seu_nome

# 2. Fazer commits na sua branch
git add .
git commit -m "Implementação das funções Lambda"

# 3. Push para sua branch
git push origin dev_seu_nome

# 4. Criar Pull Request para branch dev
# (via interface do GitHub/GitLab)

# 5. Após aprovação, merge para dev
# 6. Só então pode fazer merge para main
```

❌ **NÃO FAÇA**: Commits diretos na branch `main`

## 📁 Estrutura do Projeto

```
SistemasWebProjeto/
├── lambdas/                    # Funções Lambda Python
│   ├── add_order.py           # Criar pedidos
│   ├── set_as_delivered.py    # Marcar como entregue
│   ├── notify_owner.py        # Processar notificações
│   └── requirements.txt       # Dependências Python
├── dynamodb/                   # Configurações DynamoDB
│   ├── orders-table.yaml      # Tabela de pedidos
│   └── tokens-table.yaml      # Tabela de tokens
├── api_gateway/               # Configurações API Gateway
│   └── api-gateway.yaml       # Endpoints REST
├── sns/                       # Configurações SNS
│   └── sns-config.yaml        # Tópico de notificações
├── cloudformation/            # Templates CloudFormation
│   └── main-template.yaml     # Template principal
├── scripts/                   # Scripts de deploy
│   ├── setup.sh              # Configuração inicial
│   ├── deploy-dev.sh         # Deploy DEV
│   ├── deploy-hom.sh         # Deploy HOM
│   ├── deploy-main.sh        # Deploy MAIN
│   └── cleanup.sh            # Limpeza de recursos
├── docs/                      # Documentação
│   └── architecture-diagram.md # Diagramas de arquitetura
└── README.md                  # Este arquivo
```

## 🔧 Ambientes

O projeto suporta 3 ambientes:

| Ambiente | Descrição | Stack Name |
|----------|-----------|------------|
| **DEV** | Desenvolvimento | `fast-delivery-tracker-dev` |
| **HOM** | Homologação | `fast-delivery-tracker-hom` |
| **MAIN** | Produção | `fast-delivery-tracker-main` |

### Deploy por Ambiente

```bash
# Desenvolvimento
./scripts/deploy-dev.sh

# Homologação
./scripts/deploy-hom.sh

# Produção (com confirmações extras)
./scripts/deploy-main.sh
```

## 📚 API Endpoints

### 1. Criar Pedido de Hambúrguer
```http
POST /add-order
Content-Type: application/json

{
  "customer_name": "João Silva",
  "customer_email": "joao@email.com",
  "delivery_address": "Rua das Flores, 123, Bairro Centro",
  "items": ["Hambúrguer Artesanal", "Batata Frita", "Coca-Cola"],
  "special_instructions": "Sem cebola, entregar no portão",
  "estimated_delivery_time": "30 minutos"
}
```

**Resposta:**
```json
{
  "mensagem": "Pedido criado com sucesso",
  "order_id": "123e4567-e89b-12d3-a456-426614174000",
  "status": "PENDING"
}
```

### 2. Marcar Pedido como Entregue
```http
PUT /order/{order_id}/delivered
```

**Resposta:**
```json
{
  "mensagem": "Pedido marcado como entregue e notificação enviada",
  "order_id": "123e4567-e89b-12d3-a456-426614174000",
  "status": "DELIVERED",
  "delivered_at": "2024-01-15T14:30:00Z"
}
```

### 3. Teste Completo com cURL

```bash
# 1. Criar pedido
curl -X POST https://sua-api-url/add-order \
  -H 'Content-Type: application/json' \
  -d '{
    "customer_name": "Maria Santos",
    "customer_email": "maria@email.com",
    "delivery_address": "Av. Principal, 456",
    "items": ["X-Burger Especial", "Onion Rings", "Guaraná"],
    "special_instructions": "Entrega rápida"
  }'

# 2. Marcar como entregue (usar order_id da resposta anterior)
curl -X PUT https://sua-api-url/order/ORDER_ID/delivered
```

## 🗄️ Estrutura de Dados

### Tabela Orders
```json
{
  "order_id": "string (PK)",
  "customer_name": "string",
  "customer_email": "string", 
  "delivery_address": "string",
  "items": ["array"],
  "status": "PENDING|DELIVERED",
  "created_at": "ISO timestamp",
  "updated_at": "ISO timestamp",
  "special_instructions": "string (opcional)",
  "estimated_delivery_time": "string (opcional)"
}
```

### Tabela Tokens
```json
{
  "tracking_token": "string (PK)",
  "order_id": "string (FK)",
  "customer_email": "string",
  "customer_name": "string",
  "status": "string",
  "message": "string",
  "delivered_at": "ISO timestamp",
  "created_at": "ISO timestamp",
  "notification_sent": "boolean",
  "ttl": "number (TTL)"
}
```

## 🔍 Monitoramento

### Logs
```bash
# Ver logs das funções Lambda
aws logs describe-log-groups --region us-east-1

# Logs específicos de uma função
aws logs tail /aws/lambda/fast-delivery-tracker-add-order-dev --follow
```

### Métricas
```bash
# Métricas do CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=fast-delivery-tracker-add-order-dev \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average,Maximum
```

## 🧪 Como Realizar o Deploy

### Deploy por Ambiente

```bash
# 1. Desenvolvimento (primeiro teste)
./scripts/deploy-dev.sh

# 2. Homologação (testes finais)
./scripts/deploy-hom.sh

# 3. Produção (ambiente final)
./scripts/deploy-main.sh
```

### Verificar Deploy

```bash
# Verificar stack criada
aws cloudformation describe-stacks --stack-name fast-delivery-tracker-dev --region sa-east-1

# Verificar funções Lambda
aws lambda list-functions --region sa-east-1 --query 'Functions[?contains(FunctionName, `fast-delivery-tracker`)]'

# Verificar tabelas DynamoDB
aws dynamodb list-tables --region sa-east-1 --query 'TableNames[?contains(@, `fast-delivery-tracker`)]'

# Verificar API Gateway
aws apigateway get-rest-apis --region sa-east-1 --query 'items[?contains(name, `FastDeliveryAPI`)]'

# Verificar SNS
aws sns list-topics --region sa-east-1 --query 'Topics[?contains(TopicArn, `FastDeliveryTopic`)]'
```

### Monitoramento

```bash
# Ver logs das funções Lambda
aws logs describe-log-groups --region sa-east-1 --log-group-name-prefix "/aws/lambda/fast-delivery-tracker"

# Ver logs em tempo real
aws logs tail /aws/lambda/fast-delivery-tracker-add-order-dev --follow --region sa-east-1
```

## 🛠️ Desenvolvimento

### Estrutura das Funções Lambda

Todas as funções seguem o **template padrão do professor**:

```python
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Evento recebido: %s", json.dumps(event))
    try:
        # Lógica da função aqui
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"mensagem": "Sucesso"})
        }
    except Exception as e:
        logger.error("Erro na execução da Lambda: %s", str(e))
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"erro": "Erro interno na função Lambda."})
        }
```

### Integração com SNS

Todas as funções que precisam notificar usam o tópico fixo:

```python
import boto3, json
sns = boto3.client('sns')
sns.publish(
    TopicArn='arn:aws:sns:sa-east-1:490422578972:FastDeliveryTopic',
    Message=json.dumps({"pedido": pedido_id, "status": "Enviado"})
)
```

### Adicionando Novas Funcionalidades

1. **Nova função Lambda:**
   - Adicione o arquivo `.py` em `lambdas/`
   - Atualize `cloudformation/main-template.yaml`
   - Adicione permissões IAM necessárias

2. **Novo endpoint:**
   - Configure no `api_gateway/api-gateway.yaml`
   - Adicione integração com Lambda
   - Atualize documentação

## 🧹 Limpeza

Para remover todos os recursos AWS:

```bash
./scripts/cleanup.sh
```

⚠️ **ATENÇÃO**: Esta operação remove TODOS os recursos e não pode ser desfeita!

## 📊 Custos

O projeto utiliza serviços serverless com cobrança por uso:
- **Lambda**: $0.20 por 1M requisições + $0.0000166667 por GB-segundo
- **DynamoDB**: $0.25 por GB-mês + $1.25 por 1M operações
- **API Gateway**: $3.50 por 1M requisições
- **SNS**: $0.50 por 1M requisições

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 🆘 Suporte

Para suporte e dúvidas:
- Abra uma issue no GitHub
- Consulte a documentação AWS
- Verifique os logs do CloudWatch

---