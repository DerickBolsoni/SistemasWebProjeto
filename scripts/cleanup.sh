#!/bin/bash

# Script para limpeza dos recursos AWS do FastDelivery Tracker
# ATENÇÃO: Este script remove TODOS os recursos do projeto!

set -e

echo "🗑️  Script de limpeza do FastDelivery Tracker"
echo "=================================================="

# Função para confirmar ação
confirm_action() {
    local environment=$1
    echo "⚠️  Você está prestes a REMOVER o ambiente $environment"
    echo "   Esta ação NÃO PODE ser desfeita!"
    read -p "   Tem certeza? Digite 'REMOVER' para confirmar: " -r
    if [[ ! $REPLY == "REMOVER" ]]; then
        echo "❌ Operação cancelada."
        return 1
    fi
    return 0
}

# Função para remover stack
remove_stack() {
    local stack_name=$1
    local environment=$2
    
    echo "🔍 Verificando se a stack $stack_name existe..."
    if aws cloudformation describe-stacks --stack-name "$stack_name" --region us-east-1 > /dev/null 2>&1; then
        echo "🗑️  Removendo stack $stack_name..."
        aws cloudformation delete-stack --stack-name "$stack_name" --region us-east-1
        
        echo "⏳ Aguardando remoção da stack..."
        aws cloudformation wait stack-delete-complete --stack-name "$stack_name" --region us-east-1
        
        echo "✅ Stack $stack_name removida com sucesso"
    else
        echo "ℹ️  Stack $stack_name não existe"
    fi
}

# Menu de opções
echo "Escolha uma opção:"
echo "1) Remover ambiente DEV"
echo "2) Remover ambiente HOM"
echo "3) Remover ambiente MAIN"
echo "4) Remover TODOS os ambientes"
echo "5) Cancelar"
echo ""

read -p "Digite sua escolha (1-5): " choice

case $choice in
    1)
        if confirm_action "DEV"; then
            remove_stack "fast-delivery-tracker-dev" "DEV"
        fi
        ;;
    2)
        if confirm_action "HOM"; then
            remove_stack "fast-delivery-tracker-hom" "HOM"
        fi
        ;;
    3)
        if confirm_action "MAIN"; then
            remove_stack "fast-delivery-tracker-main" "MAIN"
        fi
        ;;
    4)
        echo "⚠️  ⚠️  ⚠️  ATENÇÃO: Você está prestes a remover TODOS os ambientes! ⚠️  ⚠️  ⚠️"
        echo "   Esta ação removerá:"
        echo "   - DEV"
        echo "   - HOM"
        echo "   - MAIN"
        echo "   - Todos os backups"
        read -p "   Digite 'REMOVER TUDO' para confirmar: " -r
        if [[ $REPLY == "REMOVER TUDO" ]]; then
            echo "🗑️  Removendo todos os ambientes..."
            
            remove_stack "fast-delivery-tracker-dev" "DEV"
            remove_stack "fast-delivery-tracker-hom" "HOM"
            remove_stack "fast-delivery-tracker-main" "MAIN"
            
            # Remover backups
            echo "🗑️  Removendo stacks de backup..."
            for backup_stack in $(aws cloudformation list-stacks --stack-status-filter DELETE_COMPLETE --region us-east-1 --query 'StackSummaries[?contains(StackName, `fast-delivery-tracker`) && contains(StackName, `backup`)].StackName' --output text); do
                echo "🗑️  Removendo backup: $backup_stack"
                aws cloudformation delete-stack --stack-name "$backup_stack" --region us-east-1 2>/dev/null || true
            done
            
            echo "✅ Todos os ambientes removidos"
        else
            echo "❌ Operação cancelada."
        fi
        ;;
    5)
        echo "❌ Operação cancelada."
        exit 0
        ;;
    *)
        echo "❌ Opção inválida."
        exit 1
        ;;
esac

echo ""
echo "🧹 Limpeza de recursos AWS concluída!"
echo "=================================================="
echo "📋 Recursos removidos:"
echo "   - Stacks CloudFormation"
echo "   - Funções Lambda"
echo "   - Tabelas DynamoDB"
echo "   - API Gateway"
echo "   - Tópicos SNS"
echo "   - IAM Roles e Policies"
echo ""
echo "💡 Dica: Use 'aws logs delete-log-group' para remover logs restantes se necessário"
