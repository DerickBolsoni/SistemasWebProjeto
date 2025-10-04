#!/bin/bash

# Script de configuração inicial do projeto FastDelivery Tracker
# Este script configura as permissões e dependências necessárias

set -e

echo "🔧 Configurando ambiente para FastDelivery Tracker"
echo "=================================================="

# Verificar se AWS CLI está instalado
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI não está instalado."
    echo "📥 Instale em: https://aws.amazon.com/cli/"
    exit 1
fi

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI não está configurado."
    echo "🔑 Execute: aws configure"
    exit 1
fi

echo "✅ AWS CLI configurado"

# Verificar se Python está instalado
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 não está instalado."
    exit 1
fi

echo "✅ Python 3 instalado"

# Verificar se zip está disponível
if ! command -v zip &> /dev/null; then
    echo "❌ Comando 'zip' não está disponível."
    echo "📦 Instale o zip utility para seu sistema operacional."
    exit 1
fi

echo "✅ Zip utility disponível"

# Tornar scripts executáveis
chmod +x scripts/*.sh
echo "✅ Scripts de deploy configurados como executáveis"

# Verificar região AWS
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
    echo "⚠️  Região AWS não configurada. Configurando como sa-east-1..."
    aws configure set region sa-east-1
    REGION="sa-east-1"
fi

echo "✅ Região AWS: $REGION"

# Verificar permissões IAM
echo "🔐 Verificando permissões IAM..."

# Verificar permissões básicas
if ! aws iam get-user > /dev/null 2>&1; then
    echo "❌ Permissões IAM insuficientes. Verifique suas credenciais."
    exit 1
fi

echo "✅ Permissões IAM básicas OK"

# Verificar permissões para CloudFormation
if ! aws cloudformation list-stacks --max-items 1 > /dev/null 2>&1; then
    echo "❌ Permissões CloudFormation insuficientes."
    exit 1
fi

echo "✅ Permissões CloudFormation OK"

# Verificar permissões para Lambda
if ! aws lambda list-functions --max-items 1 > /dev/null 2>&1; then
    echo "❌ Permissões Lambda insuficientes."
    exit 1
fi

echo "✅ Permissões Lambda OK"

# Verificar permissões para DynamoDB
if ! aws dynamodb list-tables --max-items 1 > /dev/null 2>&1; then
    echo "❌ Permissões DynamoDB insuficientes."
    exit 1
fi

echo "✅ Permissões DynamoDB OK"

# Verificar permissões para SNS
if ! aws sns list-topics --max-items 1 > /dev/null 2>&1; then
    echo "❌ Permissões SNS insuficientes."
    exit 1
fi

echo "✅ Permissões SNS OK"

# Verificar permissões para API Gateway
if ! aws apigateway get-rest-apis --max-items 1 > /dev/null 2>&1; then
    echo "❌ Permissões API Gateway insuficientes."
    exit 1
fi

echo "✅ Permissões API Gateway OK"

echo ""
echo "🎉 Configuração concluída com sucesso!"
echo "=================================================="
echo "📋 Próximos passos:"
echo "   1. Para deploy em DEV:   ./scripts/deploy-dev.sh"
echo "   2. Para deploy em HOM:   ./scripts/deploy-hom.sh"
echo "   3. Para deploy em MAIN:  ./scripts/deploy-main.sh"
echo ""
echo "📚 Para mais informações, consulte o README.md"
