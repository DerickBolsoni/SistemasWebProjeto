# 🧪 GUIA DE TESTE COMPLETO - FastDelivery Tracker

## 📋 **CHECKLIST PRÉ-TESTE**

### 1. **Verificar AWS CLI**
```bash
# Verificar se está configurado
aws sts get-caller-identity

# Se não estiver, configurar:
aws configure
# AWS Access Key ID: [SUA_ACCESS_KEY]
# AWS Secret Access Key: [SUA_SECRET_KEY]  
# Default region name: sa-east-1
# Default output format: json
```

### 2. **Executar Setup**
```bash
# Tornar scripts executáveis (Linux/Mac)
chmod +x scripts/*.sh

# No Windows, executar diretamente:
./scripts/setup.sh
```

### 3. **Deploy no Ambiente DEV**
```bash
./scripts/deploy-dev.sh
```

### 4. **Testar API**
```bash
# Obter URL da API
API_URL=$(aws cloudformation describe-stacks \
  --stack-name fast-delivery-tracker-dev \
  --region sa-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
  --output text)

echo "API URL: $API_URL"

# Teste 1: Criar pedido
curl -X POST $API_URL/add-order \
  -H 'Content-Type: application/json' \
  -d '{
    "customer_name": "João Silva",
    "customer_email": "joao@email.com",
    "delivery_address": "Rua das Flores, 123",
    "items": ["Hambúrguer Artesanal", "Batata Frita", "Coca-Cola"],
    "special_instructions": "Sem cebola"
  }'

# Anotar o order_id da resposta!

# Teste 2: Marcar como entregue (substituir ORDER_ID)
curl -X PUT $API_URL/order/ORDER_ID/delivered
```

### 5. **Verificar Logs**
```bash
# Ver logs da função addOrder
aws logs tail /aws/lambda/fast-delivery-tracker-add-order-dev --follow --region sa-east-1

# Ver logs da função setAsDelivered
aws logs tail /aws/lambda/fast-delivery-tracker-set-delivered-dev --follow --region sa-east-1

# Ver logs da função notifyOwner
aws logs tail /aws/lambda/fast-delivery-tracker-notify-owner-dev --follow --region sa-east-1
```

### 6. **Verificar Recursos Criados**
```bash
# Lambda functions
aws lambda list-functions --region sa-east-1 --query 'Functions[?contains(FunctionName, `fast-delivery-tracker`)]'

# DynamoDB tables
aws dynamodb list-tables --region sa-east-1 --query 'TableNames[?contains(@, `fast-delivery-tracker`)]'

# API Gateway
aws apigateway get-rest-apis --region sa-east-1 --query 'items[?contains(name, `FastDeliveryAPI`)]'

# SNS topic
aws sns list-topics --region sa-east-1 --query 'Topics[?contains(TopicArn, `FastDeliveryTopic`)]'
```

## ✅ **RESULTADOS ESPERADOS**

### **API Response (Criar Pedido):**
```json
{
  "mensagem": "Pedido criado com sucesso",
  "order_id": "123e4567-e89b-12d3-a456-426614174000",
  "status": "PENDING"
}
```

### **API Response (Marcar Entregue):**
```json
{
  "mensagem": "Pedido marcado como entregue e notificação enviada",
  "order_id": "123e4567-e89b-12d3-a456-426614174000", 
  "status": "DELIVERED",
  "delivered_at": "2024-01-15T14:30:00Z"
}
```

### **Logs Esperados:**
- `Evento recebido: {...}`
- `Pedido criado com sucesso: order_id`
- `Pedido X marcado como entregue`
- `Token criado com sucesso: tracking_token`

## 🚨 **TROUBLESHOOTING**

### **Erro: AWS CLI não configurado**
```bash
aws configure
```

### **Erro: Permissões insuficientes**
- Verificar IAM policies
- Usar usuário com permissões de administrador

### **Erro: Região incorreta**
```bash
aws configure set region sa-east-1
```

### **Erro: Stack creation failed**
```bash
aws cloudformation describe-stack-events --stack-name fast-delivery-tracker-dev --region sa-east-1
```

## 🎯 **CRITÉRIOS DE SUCESSO**

- ✅ Deploy executa sem erros
- ✅ API responde com status 201 (criar pedido)
- ✅ API responde com status 200 (marcar entregue)
- ✅ Logs aparecem no CloudWatch
- ✅ Recursos criados na região sa-east-1
- ✅ SNS tópico FastDeliveryTopic existe
