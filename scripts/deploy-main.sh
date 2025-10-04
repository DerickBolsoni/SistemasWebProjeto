#!/bin/bash

# Script de deploy para ambiente de produção
# FastDelivery Tracker - Ambiente MAIN

set -e

# Configurações
ENVIRONMENT="main"
STACK_NAME="fast-delivery-tracker-main"
REGION="sa-east-1"
LAMBDA_ZIP_FILE="lambdas.zip"

echo "🚀 Iniciando deploy do FastDelivery Tracker - Ambiente MAIN (PRODUÇÃO)"
echo "=================================================="

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI não está configurado. Execute 'aws configure' primeiro."
    exit 1
fi

# Confirmar deploy em produção
echo "⚠️  ⚠️  ⚠️  ATENÇÃO: Você está prestes a fazer deploy em PRODUÇÃO! ⚠️  ⚠️  ⚠️"
echo "Este ambiente será usado por clientes reais."
read -p "Você tem CERTEZA ABSOLUTA? Digite 'DEPLOY' para confirmar: " -r
if [[ ! $REPLY == "DEPLOY" ]]; then
    echo "❌ Deploy cancelado."
    exit 1
fi

# Verificar se o código foi testado em outros ambientes
echo "🔍 Verificando se o código foi testado em outros ambientes..."
read -p "Este código foi testado no ambiente DEV? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deploy cancelado. Teste primeiro no ambiente DEV."
    exit 1
fi

read -p "Este código foi testado no ambiente HOM? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deploy cancelado. Teste primeiro no ambiente HOM."
    exit 1
fi

# Criar backup do ambiente atual (se existir)
echo "💾 Verificando se existe ambiente atual para backup..."
if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION > /dev/null 2>&1; then
    echo "📦 Criando backup do ambiente atual..."
    aws cloudformation create-stack \
        --stack-name "${STACK_NAME}-backup-$(date +%Y%m%d-%H%M%S)" \
        --template-body file://cloudformation/main-template.yaml \
        --parameters ParameterKey=Environment,ParameterValue=backup \
        --capabilities CAPABILITY_IAM \
        --region $REGION
fi

# Criar arquivo ZIP com as funções Lambda
echo "📦 Criando pacote das funções Lambda..."
cd lambdas
zip -r ../$LAMBDA_ZIP_FILE *.py requirements.txt
cd ..

# Deploy do CloudFormation com proteções extras
echo "☁️  Fazendo deploy do CloudFormation em PRODUÇÃO..."
aws cloudformation deploy \
    --template-file cloudformation/main-template.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides Environment=$ENVIRONMENT \
    --capabilities CAPABILITY_IAM \
    --region $REGION \
    --role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/CloudFormationExecutionRole

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
echo "✅ Deploy em PRODUÇÃO concluído com sucesso!"
echo "=================================================="
echo "🌐 URL da API: $API_URL"
echo "📋 Endpoints disponíveis:"
echo "   POST   $API_URL/add-order"
echo "   PUT    $API_URL/order/{order_id}/delivered"
echo ""
echo "📊 Para monitorar em produção:"
echo "aws logs describe-log-groups --region $REGION"
echo "aws cloudwatch get-metric-statistics --namespace AWS/Lambda --region $REGION"
echo ""
echo "🚨 Lembre-se de monitorar os logs e métricas após o deploy!"
