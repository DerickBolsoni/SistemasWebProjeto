# 🎥 Guia para Apresentação - FastDelivery Tracker

## 📋 Roteiro da Apresentação (10-15 minutos)

### 1. Introdução (2 minutos)
- **O que é**: Sistema de entrega de hambúrguer serverless
- **Objetivo**: Gerenciar pedidos e notificações automáticas
- **Tecnologias**: AWS Serverless (Lambda, API Gateway, DynamoDB, SNS)

### 2. Arquitetura (3 minutos)
- Mostrar diagrama principal
- Explicar fluxo: Cliente → API Gateway → Lambda → DynamoDB/SNS
- Destacar 3 funções Lambda principais
- Enfatizar região sa-east-1 e tópico SNS fixo

### 3. Demonstração do Código (4 minutos)
- Mostrar template padrão do professor
- Demonstrar função addOrder
- Mostrar integração SNS
- Explicar logging estruturado

### 4. Deploy e Teste (3 minutos)
- Executar script de deploy
- Testar API com cURL
- Mostrar logs no CloudWatch
- Verificar recursos criados

### 5. Conclusão (1 minuto)
- Fluxo Git correto
- Ambientes separados
- Pronto para produção

## 🗣️ Pontos-Chave para Enfatizar

### ✅ Requisitos Atendidos:
1. **Template do Professor**: Todas as funções seguem o padrão exato
2. **Região sa-east-1**: Configurado corretamente
3. **SNS FastDeliveryTopic**: Nome fixo conforme especificado
4. **Endpoint /add-order**: Conforme requisito
5. **Fluxo Git**: Branches dev → hom → main
6. **Logging**: logging.info() em todas as funções

### 🔧 Funcionalidades Demonstradas:
- Criar pedido de hambúrguer
- Marcar como entregue
- Notificações automáticas
- Geração de tokens
- Logs estruturados

## 📊 Comandos para Demonstração

### 1. Verificar Ambiente
```bash
aws sts get-caller-identity
aws configure list
```

### 2. Deploy
```bash
./scripts/setup.sh
./scripts/deploy-dev.sh
```

### 3. Teste da API
```bash
# Obter URL da API
API_URL=$(aws cloudformation describe-stacks \
  --stack-name fast-delivery-tracker-dev \
  --region sa-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
  --output text)

# Criar pedido
curl -X POST $API_URL/add-order \
  -H 'Content-Type: application/json' \
  -d '{
    "customer_name": "João Silva",
    "customer_email": "joao@email.com",
    "delivery_address": "Rua das Flores, 123",
    "items": ["Hambúrguer Artesanal", "Batata Frita", "Coca-Cola"],
    "special_instructions": "Sem cebola"
  }'

# Marcar como entregue (usar order_id da resposta)
curl -X PUT $API_URL/order/ORDER_ID/delivered
```

### 4. Verificar Logs
```bash
aws logs tail /aws/lambda/fast-delivery-tracker-add-order-dev --follow --region sa-east-1
```

### 5. Verificar Recursos
```bash
# Lambda functions
aws lambda list-functions --region sa-east-1 --query 'Functions[?contains(FunctionName, `fast-delivery-tracker`)]'

# DynamoDB tables
aws dynamodb list-tables --region sa-east-1 --query 'TableNames[?contains(@, `fast-delivery-tracker`)]'

# SNS topic
aws sns list-topics --region sa-east-1 --query 'Topics[?contains(TopicArn, `FastDeliveryTopic`)]'
```

## 🎯 Respostas para Possíveis Perguntas

### Q: Por que usar serverless?
**R**: Escalabilidade automática, pagamento por uso, sem gerenciamento de servidores, deploy rápido.

### Q: Como funciona o SNS?
**R**: Quando um pedido é criado ou entregue, a função Lambda publica uma mensagem no tópico FastDeliveryTopic, que automaticamente invoca a função notifyOwner para processar a notificação.

### Q: Como garantir que não há perda de dados?
**R**: DynamoDB com backup automático, logs no CloudWatch, tratamento de erros nas funções Lambda.

### Q: Como monitorar em produção?
**R**: CloudWatch Logs para debugging, CloudWatch Metrics para performance, alertas configurados.

### Q: Como fazer rollback?
**R**: CloudFormation mantém histórico de deploys, possível reverter para versão anterior.

## 📝 Checklist Pré-Apresentação

- [ ] AWS CLI configurado
- [ ] Região sa-east-1 configurada
- [ ] Permissões IAM adequadas
- [ ] Scripts executáveis
- [ ] Código commitado no Git
- [ ] URL da API anotada
- [ ] Exemplos de teste prontos
- [ ] Diagramas abertos
- [ ] Terminal preparado

## 🚨 Pontos de Atenção

1. **Não esquecer**: Enfatizar que segue exatamente o template do professor
2. **Região**: Sempre mencionar sa-east-1
3. **SNS**: Destacar o nome fixo FastDeliveryTopic
4. **Git**: Explicar o fluxo de branches
5. **Logs**: Mostrar que usa logging.info() conforme requisito

## 📈 Métricas de Sucesso

- ✅ Deploy funciona sem erros
- ✅ API responde corretamente
- ✅ SNS envia notificações
- ✅ Logs aparecem no CloudWatch
- ✅ Recursos criados na região correta
- ✅ Código segue template do professor
