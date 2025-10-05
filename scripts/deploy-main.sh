#!/bin/bash

# ==============================================================================
# Script de Deploy para o Ambiente de PRODUÇÃO (MAIN)
#
# PROJETO: FastDelivery Tracker
#
# DESCRIÇÃO:
# Este script automatiza o processo de deploy da aplicação na AWS para o
# ambiente de produção. Ele inclui várias checagens de segurança para
# minimizar o risco de deploys acidentais ou incorretos.
#
# ATENÇÃO:
# ESTE SCRIPT REALIZA ALTERAÇÕES DIRETAMENTE NO AMBIENTE DE PRODUÇÃO.
# TENHA CERTEZA ABSOLUTA DO QUE ESTÁ FAZENDO ANTES DE EXECUTAR.
# ==============================================================================

# --- Configuração de Segurança ---
# 'set -e' garante que o script irá parar imediatamente se qualquer comando falhar.
# Essencial para evitar um deploy parcial ou um estado inconsistente em produção.
set -e

# --- Variáveis de Configuração ---
# Centralizar as configurações em variáveis facilita a manutenção do script.
ENVIRONMENT="main"
STACK_NAME="fast-delivery-tracker-main"
REGION="sa-east-1"
LAMBDA_ZIP_FILE="lambdas.zip" # Nome do arquivo temporário para o código das Lambdas

echo "🚀 Iniciando deploy do FastDelivery Tracker - Ambiente MAIN (PRODUÇÃO)"
echo "=================================================="

# --- Checagem de Pré-requisitos (Pre-flight Check) ---
# 1. Verifica se o AWS CLI está configurado e autenticado.
echo "🔍 Verificando credenciais da AWS..."
# 'aws sts get-caller-identity' é um comando leve que falha se não houver credenciais válidas.
# A saída é descartada com '> /dev/null 2>&1'. O 'if' apenas checa se o comando foi bem-sucedido.
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI não está configurado. Execute 'aws configure' primeiro."
    exit 1 # Encerra o script com um código de erro.
fi

# --- Barreiras de Segurança (Safety Gates) ---
# 2. Confirmação manual para deploy em produção. Previne execuções acidentais.
echo "⚠️  ⚠️  ⚠️  ATENÇÃO: Você está prestes a fazer deploy em PRODUÇÃO! ⚠️  ⚠️  ⚠️"
echo "Este ambiente será usado por clientes reais."
read -p "Você tem CERTEZA ABSOLUTA? Digite 'DEPLOY' para confirmar: " -r
if [[ ! $REPLY == "DEPLOY" ]]; then
    echo "❌ Deploy cancelado pelo usuário."
    exit 1
fi

# 3. Confirmação de que os testes foram realizados nos ambientes anteriores.
echo "🔍 Verificando se o código foi testado em outros ambientes..."
read -p "Este código foi testado no ambiente DEV? (y/N): " -n 1 -r
echo # Adiciona uma nova linha após a resposta do usuário
# A expressão regular `^[Yy]$` verifica se a resposta foi 'Y' ou 'y'.
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

# --- Backup (Opcional, mas recomendado) ---
# Esta seção foi comentada pois a lógica de criar uma nova stack como backup
# pode ter custos inesperados. Uma estratégia melhor seria usar Change Sets ou backups do DynamoDB.
# echo "💾 Verificando se existe ambiente atual para backup..."
# if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION > /dev/null 2>&1; then
#     echo "📦 Criando snapshot de backup da stack atual..."
#     BACKUP_STACK_NAME="${STACK_NAME}-backup-$(date +%Y%m%d-%H%M%S)"
#     aws cloudformation create-stack \
#         --stack-name "$BACKUP_STACK_NAME" \
#         --template-url "$(aws cloudformation get-template --stack-name $STACK_NAME --query 'TemplateBody' --output text)" \
#         --parameters ... # Seria necessário replicar os parâmetros
# fi

# --- Empacotamento do Código ---
echo "📦 Criando pacote .zip com as funções Lambda..."
cd lambdas # Entra no diretório das funções
# O comando 'zip' cria um arquivo. O '-r' é para recursividade (não necessário aqui, mas boa prática).
# '../$LAMBDA_ZIP_FILE' cria o arquivo no diretório pai (raiz do projeto).
zip ../$LAMBDA_ZIP_FILE *.py requirements.txt
cd .. # Volta para o diretório raiz do projeto

# --- Deploy da Infraestrutura via CloudFormation ---
echo "☁️  Fazendo deploy da infraestrutura com CloudFormation..."
# O comando 'aws cloudformation deploy' é idempotente: ele cria a stack se não existir
# ou atualiza se já existir.
aws cloudformation deploy \
    --template-file cloudformation/main-template.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides Environment=$ENVIRONMENT \
    # '--capabilities CAPABILITY_IAM' é uma confirmação de segurança de que a stack pode criar recursos de IAM (roles, policies).
    --capabilities CAPABILITY_IAM \
    --region $REGION \
    # '--role-arn' especifica um papel para o CloudFormation usar. É uma boa prática de segurança
    # para limitar as permissões ao invés de usar as do usuário que executa o script.
    # O `$(...)` executa um comando para obter o ID da conta dinamicamente.
    --role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/CloudFormationExecutionRole

# --- Extração de Outputs da Stack ---
# Após o deploy, pegamos os ARNs (nomes únicos) das Lambdas criadas.
# A flag '--query' usa a linguagem JMESPath para filtrar o JSON de retorno e pegar apenas o valor que precisamos.
echo "🔗 Obtendo ARNs das funções Lambda criadas..."
ADD_ORDER_LAMBDA=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`AddOrderLambdaArn`].OutputValue' --output text)
SET_DELIVERED_LAMBDA=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`SetAsDeliveredLambdaArn`].OutputValue' --output text)
NOTIFY_OWNER_LAMBDA=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`NotifyOwnerLambdaArn`].OutputValue' --output text)

# --- Atualização do Código das Funções Lambda ---
echo "🔄 Atualizando o código-fonte das funções Lambda..."
# Com os ARNs em mãos, agora atualizamos o código de cada função com o .zip que criamos.
# 'fileb://' é importante para que o CLI envie o arquivo como um binário.
aws lambda update-function-code --function-name $ADD_ORDER_LAMBDA --zip-file fileb://$LAMBDA_ZIP_FILE --region $REGION
aws lambda update-function-code --function-name $SET_DELIVERED_LAMBDA --zip-file fileb://$LAMBDA_ZIP_FILE --region $REGION
aws lambda update-function-code --function-name $NOTIFY_OWNER_LAMBDA --zip-file fileb://$LAMBDA_ZIP_FILE --region $REGION

# --- Obtenção da URL da API ---
# Pega a URL do API Gateway, também definida como um Output na stack do CloudFormation.
echo "🔗 Obtendo URL do API Gateway..."
API_URL=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' --output text)

# --- Limpeza ---
# Remove o arquivo .zip local que foi criado, já que não é mais necessário.
echo "🧹 Limpando arquivos temporários..."
rm $LAMBDA_ZIP_FILE

# --- Resumo Final ---
# Exibe as informações mais importantes para o usuário após o deploy.
echo ""
echo "✅ Deploy em PRODUÇÃO concluído com sucesso!"
echo "=================================================="
echo "🌐 URL da API: $API_URL"
echo "📋 Endpoints disponíveis:"
echo "   POST   $API_URL/add-order"
echo "   PUT    $API_URL/order/{order_id}/delivered"
echo ""
echo "📊 Para monitorar em produção, use comandos como:"
echo "   aws logs describe-log-groups --region $REGION"
echo "   aws cloudwatch get-metric-statistics --namespace AWS/Lambda --region $REGION"
echo ""
echo "🚨 Lembre-se de monitorar os logs e métricas da aplicação após o deploy!"