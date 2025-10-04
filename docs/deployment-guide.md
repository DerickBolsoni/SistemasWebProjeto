# Guia de Deploy - FastDelivery Tracker

## 📋 Pré-requisitos

### 1. Conta AWS
- Conta AWS ativa
- Permissões de administrador ou permissões equivalentes
- MFA configurado (recomendado para produção)

### 2. AWS CLI
```bash
# Instalar AWS CLI (Linux/macOS)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Instalar AWS CLI (Windows)
# Baixar de: https://aws.amazon.com/cli/
```

### 3. Configuração AWS CLI
```bash
aws configure
# AWS Access Key ID: [SUA_ACCESS_KEY]
# AWS Secret Access Key: [SUA_SECRET_KEY]
# Default region name: us-east-1
# Default output format: json
```

### 4. Verificar Configuração
```bash
aws sts get-caller-identity
```

## 🚀 Deploy Passo a Passo

### 1. Preparação do Ambiente

```bash
# Clone o repositório
git clone <repository-url>
cd SistemasWebProjeto

# Tornar scripts executáveis
chmod +x scripts/*.sh

# Executar setup inicial
./scripts/setup.sh
```

### 2. Deploy no Ambiente DEV

```bash
# Deploy completo no ambiente de desenvolvimento
./scripts/deploy-dev.sh
```

**O que acontece:**
1. ✅ Validação de permissões AWS
2. 📦 Criação do pacote Lambda
3. ☁️ Deploy do CloudFormation
4. 🔄 Atualização do código Lambda
5. 📊 Exibição dos resultados

### 3. Teste do Ambiente DEV

```bash
# Obter URL da API
API_URL=$(aws cloudformation describe-stacks \
  --stack-name fast-delivery-tracker-dev \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
  --output text)

echo "API URL: $API_URL"

# Teste criar pedido
curl -X POST $API_URL/orders \
  -H 'Content-Type: application/json' \
  -d '{
    "customer_name": "Teste DEV",
    "customer_email": "teste@dev.com",
    "delivery_address": "Rua Teste, 123",
    "items": ["Item Teste"]
  }'
```

### 4. Deploy no Ambiente HOM

```bash
# Deploy no ambiente de homologação
./scripts/deploy-hom.sh
```

**Diferenças do DEV:**
- Confirmação manual obrigatória
- Stack name: `fast-delivery-tracker-hom`
- Recursos isolados do DEV

### 5. Deploy no Ambiente MAIN

```bash
# Deploy em produção
./scripts/deploy-main.sh
```

**Proteções extras:**
- Múltiplas confirmações
- Verificação de testes em outros ambientes
- Backup automático do ambiente atual
- Role específica para CloudFormation

## 🔧 Deploy Manual (Alternativo)

### 1. CloudFormation Manual

```bash
# Criar stack
aws cloudformation create-stack \
  --stack-name fast-delivery-tracker-dev \
  --template-body file://cloudformation/main-template.yaml \
  --parameters ParameterKey=Environment,ParameterValue=dev \
  --capabilities CAPABILITY_IAM \
  --region us-east-1

# Aguardar conclusão
aws cloudformation wait stack-create-complete \
  --stack-name fast-delivery-tracker-dev \
  --region us-east-1
```

### 2. Atualizar Lambda Manualmente

```bash
# Criar pacote
cd lambdas
zip -r ../lambdas.zip *.py requirements.txt
cd ..

# Obter ARN da função
LAMBDA_ARN=$(aws cloudformation describe-stacks \
  --stack-name fast-delivery-tracker-dev \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`AddOrderLambdaArn`].OutputValue' \
  --output text)

# Atualizar código
aws lambda update-function-code \
  --function-name $LAMBDA_ARN \
  --zip-file fileb://lambdas.zip \
  --region us-east-1
```

## 🔍 Verificação Pós-Deploy

### 1. Verificar Recursos Criados

```bash
# Listar stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Verificar Lambda functions
aws lambda list-functions --query 'Functions[?contains(FunctionName, `fast-delivery-tracker`)]'

# Verificar tabelas DynamoDB
aws dynamodb list-tables --query 'TableNames[?contains(@, `fast-delivery-tracker`)]'

# Verificar API Gateway
aws apigateway get-rest-apis --query 'items[?contains(name, `fast-delivery`)]'

# Verificar SNS topics
aws sns list-topics --query 'Topics[?contains(TopicArn, `fast-delivery`)]'
```

### 2. Verificar Logs

```bash
# Verificar log groups
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/fast-delivery-tracker"

# Ver logs recentes
aws logs tail /aws/lambda/fast-delivery-tracker-add-order-dev --since 1h
```

### 3. Teste de Integração

```bash
# Script de teste completo
cat > test-integration.sh << 'EOF'
#!/bin/bash

API_URL=$(aws cloudformation describe-stacks \
  --stack-name fast-delivery-tracker-dev \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
  --output text)

echo "🧪 Testando integração com API: $API_URL"

# Teste 1: Criar pedido
echo "📝 Teste 1: Criando pedido..."
ORDER_RESPONSE=$(curl -s -X POST $API_URL/orders \
  -H 'Content-Type: application/json' \
  -d '{
    "customer_name": "Teste Integração",
    "customer_email": "teste@integracao.com",
    "delivery_address": "Rua Integração, 123",
    "items": ["Pizza Teste", "Refrigerante"]
  }')

echo "Resposta: $ORDER_RESPONSE"

# Extrair order_id
ORDER_ID=$(echo $ORDER_RESPONSE | jq -r '.order_id')
echo "Order ID: $ORDER_ID"

# Teste 2: Marcar como entregue
echo "📦 Teste 2: Marcando como entregue..."
DELIVERY_RESPONSE=$(curl -s -X PUT $API_URL/orders/$ORDER_ID/delivered \
  -H 'Content-Type: application/json')

echo "Resposta: $DELIVERY_RESPONSE"

echo "✅ Teste de integração concluído!"
EOF

chmod +x test-integration.sh
./test-integration.sh
```

## 🚨 Troubleshooting

### Problemas Comuns

#### 1. Erro de Permissões
```
Error: User is not authorized to perform: cloudformation:CreateStack
```

**Solução:**
```bash
# Verificar permissões
aws sts get-caller-identity

# Adicionar permissões necessárias no IAM
```

#### 2. Stack Creation Failed
```
Error: The following resource(s) failed to create: [OrdersTable]
```

**Solução:**
```bash
# Verificar eventos da stack
aws cloudformation describe-stack-events \
  --stack-name fast-delivery-tracker-dev

# Verificar logs específicos
aws logs filter-log-events \
  --log-group-name /aws/cloudformation \
  --filter-pattern "fast-delivery-tracker-dev"
```

#### 3. Lambda Function Error
```
Error: Unable to update function code
```

**Solução:**
```bash
# Verificar se o arquivo ZIP existe
ls -la lambdas.zip

# Recriar o pacote
cd lambdas
zip -r ../lambdas.zip *.py requirements.txt
cd ..

# Tentar novamente
aws lambda update-function-code \
  --function-name fast-delivery-tracker-add-order-dev \
  --zip-file fileb://lambdas.zip
```

#### 4. API Gateway 502 Error
```
HTTP 502 Bad Gateway
```

**Solução:**
```bash
# Verificar logs da Lambda
aws logs tail /aws/lambda/fast-delivery-tracker-add-order-dev --since 10m

# Verificar integração API Gateway
aws apigateway get-integration \
  --rest-api-id YOUR_API_ID \
  --resource-id YOUR_RESOURCE_ID \
  --http-method POST
```

### Comandos de Diagnóstico

```bash
# Verificar saúde geral
aws cloudformation describe-stacks \
  --stack-name fast-delivery-tracker-dev \
  --query 'Stacks[0].StackStatus'

# Verificar recursos com problemas
aws cloudformation describe-stack-resources \
  --stack-name fast-delivery-tracker-dev \
  --query 'StackResources[?ResourceStatus!=`CREATE_COMPLETE`]'

# Verificar eventos recentes
aws cloudformation describe-stack-events \
  --stack-name fast-delivery-tracker-dev \
  --max-items 10
```

## 🔄 Rollback

### Rollback Automático
O CloudFormation faz rollback automático se a stack falhar durante a criação.

### Rollback Manual
```bash
# Deletar stack com problemas
aws cloudformation delete-stack \
  --stack-name fast-delivery-tracker-dev

# Aguardar remoção
aws cloudformation wait stack-delete-complete \
  --stack-name fast-delivery-tracker-dev

# Recriar com configurações anteriores
./scripts/deploy-dev.sh
```

## 📊 Monitoramento Pós-Deploy

### 1. Configurar Alarmes

```bash
# Alarme para erros Lambda
aws cloudwatch put-metric-alarm \
  --alarm-name "fast-delivery-lambda-errors" \
  --alarm-description "Alarme para erros nas funções Lambda" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=fast-delivery-tracker-add-order-dev

# Alarme para duração Lambda
aws cloudwatch put-metric-alarm \
  --alarm-name "fast-delivery-lambda-duration" \
  --alarm-description "Alarme para duração alta das funções Lambda" \
  --metric-name Duration \
  --namespace AWS/Lambda \
  --statistic Average \
  --period 300 \
  --threshold 5000 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=fast-delivery-tracker-add-order-dev
```

### 2. Dashboard CloudWatch

```bash
# Criar dashboard
aws cloudwatch put-dashboard \
  --dashboard-name "FastDelivery-Tracker" \
  --dashboard-body '{
    "widgets": [
      {
        "type": "metric",
        "properties": {
          "metrics": [
            ["AWS/Lambda", "Invocations", "FunctionName", "fast-delivery-tracker-add-order-dev"],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ],
          "period": 300,
          "stat": "Sum",
          "region": "us-east-1",
          "title": "Lambda Metrics"
        }
      }
    ]
  }'
```

## 🧹 Limpeza

### Limpeza Completa
```bash
# Usar script de limpeza
./scripts/cleanup.sh

# Ou remoção manual
aws cloudformation delete-stack --stack-name fast-delivery-tracker-dev
aws cloudformation delete-stack --stack-name fast-delivery-tracker-hom
aws cloudformation delete-stack --stack-name fast-delivery-tracker-main
```

### Limpeza Parcial
```bash
# Remover apenas um ambiente
aws cloudformation delete-stack --stack-name fast-delivery-tracker-dev
```

---

**💡 Dica**: Sempre teste primeiro no ambiente DEV antes de fazer deploy em HOM e MAIN!
