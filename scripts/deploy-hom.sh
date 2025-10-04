#!/bin/bash

# Script de deploy para ambiente de homologação
# FastDelivery Tracker - Ambiente HOM

set -e

# Configurações
ENVIRONMENT="hom"
STACK_NAME="fast-delivery-tracker-hom"
REGION="sa-east-1"
LAMBDA_ZIP_FILE="lambdas.zip"

echo "🚀 Iniciando deploy do FastDelivery Tracker - Ambiente HOM"
echo "=================================================="

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI não está configurado. Execute 'aws configure' primeiro."
    exit 1
fi

# Confirmar deploy em produção
echo "⚠️  Você está prestes a fazer deploy no ambiente de HOMOLOGAÇÃO."
read -p "Tem certeza? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deploy cancelado."
    exit 1
fi

# Criar arquivo ZIP com as funções Lambda
echo "📦 Criando pacote das funções Lambda..."
cd lambdas
zip -r ../$LAMBDA_ZIP_FILE *.py requirements.txt
cd ..

# Deploy do CloudFormation
echo "☁️  Fazendo deploy do CloudFormation..."
aws cloudformation deploy \
    --template-file cloudformation/main-template.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides Environment=$ENVIRONMENT \
    --capabilities CAPABILITY_IAM \
    --region $REGION

# Obter ARNs das funções Lambda
ADD_ORDER_LAMBDA=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`AddOrderLambdaArn`].OutputValue' \
    --output text)

SET_DELIVERED_LAMBDA=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`SetAsDeliveredLambdaArn`].OutputValue' \
    --output text)

NOTIFY_OWNER_LAMBDA=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`NotifyOwnerLambdaArn`].OutputValue' \
    --output text)

# Atualizar código das funções Lambda
echo "🔄 Atualizando código das funções Lambda..."

aws lambda update-function-code \
    --function-name $ADD_ORDER_LAMBDA \
    --zip-file fileb://$LAMBDA_ZIP_FILE \
    --region $REGION

aws lambda update-function-code \
    --function-name $SET_DELIVERED_LAMBDA \
    --zip-file fileb://$LAMBDA_ZIP_FILE \
    --region $REGION

aws lambda update-function-code \
    --function-name $NOTIFY_OWNER_LAMBDA \
    --zip-file fileb://$LAMBDA_ZIP_FILE \
    --region $REGION

# Obter URL da API
API_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text)

# Limpar arquivo ZIP
rm $LAMBDA_ZIP_FILE

echo ""
echo "✅ Deploy concluído com sucesso!"
echo "=================================================="
echo "🌐 URL da API: $API_URL"
echo "📋 Endpoints disponíveis:"
echo "   POST   $API_URL/add-order"
echo "   PUT    $API_URL/order/{order_id}/delivered"
echo ""
echo "🔧 Para testar a API:"
echo "curl -X POST $API_URL/add-order \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"customer_name\":\"João Silva\",\"customer_email\":\"joao@email.com\",\"delivery_address\":\"Rua A, 123\",\"items\":[\"Hambúrguer Artesanal\",\"Batata Frita\",\"Coca-Cola\"]}'"
echo ""
echo "📊 Para verificar logs:"
echo "aws logs describe-log-groups --region $REGION"
