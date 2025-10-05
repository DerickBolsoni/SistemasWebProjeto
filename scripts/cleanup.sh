#!/bin/bash

# ==============================================================================
# Script para Limpezza dos Recursos AWS do Projeto FastDelivery Tracker
#
# DESCRIÇÃO:
# Este script automatiza a remoção de todas as stacks do CloudFormation
# associadas ao projeto, organizadas por ambiente (DEV, HOM, MAIN).
#
# ATENÇÃO:
# A execução deste script é DESTRUTIVA e removerá permanentemente os
# recursos da AWS. Use com extrema cautela.
# ==============================================================================

# --- Configuração de Segurança ---
# 'set -e' faz com que o script pare imediatamente se qualquer comando falhar.
# Isso evita que o script continue em um estado inconsistente caso um erro ocorra.
set -e

# --- Início do Script ---
echo "🗑️  Script de limpeza do FastDelivery Tracker"
echo "=================================================="

# --- Função de Confirmação ---
# Pede uma confirmação explícita do usuário antes de executar ações destrutivas.
# Parâmetros:
#   $1: Nome do ambiente (ex: "DEV")
confirm_action() {
    local environment=$1
    echo "⚠️  Você está prestes a REMOVER o ambiente '$environment'"
    echo "   Esta ação NÃO PODE ser desfeita!"
    # 'read -p' mostra a mensagem e espera a entrada do usuário na mesma linha.
    # A resposta do usuário é armazenada na variável $REPLY.
    read -p "   Tem certeza? Digite 'REMOVER' para confirmar: " -r
    
    # Compara a resposta do usuário com a string "REMOVER".
    if [[ ! $REPLY == "REMOVER" ]]; then
        echo "❌ Operação cancelada."
        return 1 # Retorna um código de erro (falso em shell script)
    fi
    return 0 # Retorna um código de sucesso (verdadeiro)
}

# --- Função para Remover a Stack ---
# Verifica se uma stack do CloudFormation existe e, se existir, a remove.
# Parâmetros:
#   $1: Nome da stack (ex: "fast-delivery-tracker-dev")
#   $2: Nome do ambiente (usado para logs, não funcionalmente)
remove_stack() {
    local stack_name=$1
    local environment=$2 # Este parâmetro não é usado na lógica, mas foi mantido.
    
    echo "🔍 Verificando se a stack '$stack_name' existe..."
    # 'aws cloudformation describe-stacks' tenta obter os detalhes da stack.
    # Se a stack não existe, o comando falha.
    # '> /dev/null 2>&1' redireciona toda a saída (padrão e de erro) para o "buraco negro",
    # para que nada seja impresso na tela. O 'if' apenas verifica o status de sucesso/falha do comando.
    if aws cloudformation describe-stacks --stack-name "$stack_name" --region us-east-1 > /dev/null 2>&1; then
        echo "🗑️  Removendo stack '$stack_name'..."
        # Inicia a remoção da stack. Este comando é assíncrono (devolve o controle imediatamente).
        aws cloudformation delete-stack --stack-name "$stack_name" --region us-east-1
        
        echo "⏳ Aguardando remoção da stack..."
        # 'aws cloudformation wait stack-delete-complete' pausa o script até que a stack seja
        # completamente removida. Isso garante que o script só continue após a limpeza ser concluída.
        aws cloudformation wait stack-delete-complete --stack-name "$stack_name" --region us-east-1
        
        echo "✅ Stack '$stack_name' removida com sucesso"
    else
        echo "ℹ️  Stack '$stack_name' não existe ou já foi removida."
    fi
}

# --- Menu Interativo ---
# Apresenta as opções disponíveis para o usuário.
echo "Escolha uma opção:"
echo "1) Remover ambiente DEV"
echo "2) Remover ambiente HOM"
echo "3) Remover ambiente MAIN"
echo "4) Remover TODOS os ambientes"
echo "5) Cancelar"
echo ""

# Lê a escolha do usuário e a armazena na variável 'choice'.
read -p "Digite sua escolha (1-5): " choice

# --- Lógica Principal (Case) ---
# Executa um bloco de código diferente com base na escolha do usuário.
case $choice in
    1)
        # Se a função 'confirm_action' retornar sucesso (0), então executa 'remove_stack'.
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
        # Bloco para remover todos os ambientes, com uma confirmação extra.
        echo "⚠️ ⚠️ ⚠️  ATENÇÃO: Você está prestes a remover TODOS os ambientes! ⚠️ ⚠️ ⚠️"
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
            
            # --- Limpeza de Backups (Lógica Adicional) ---
            # Este loop tenta encontrar e remover stacks de backup.
            # NOTA: A lógica original `DELETE_COMPLETE` busca por stacks já deletadas. 
            # Isso pode ser para limpar referências, mas o comando `delete-stack` falharia.
            # O `|| true` no final garante que o script não pare mesmo se houver erro.
            echo "🗑️  Removendo stacks de backup..."
            # O comando dentro de $() é executado e sua saída é usada pelo 'for' loop.
            for backup_stack in $(aws cloudformation list-stacks --stack-status-filter DELETE_COMPLETE --region us-east-1 --query 'StackSummaries[?contains(StackName, `fast-delivery-tracker`) && contains(StackName, `backup`)].StackName' --output text); do
                echo "🗑️  Removendo backup: $backup_stack"
                # Tenta deletar a stack. '2>/dev/null' oculta erros e '|| true' impede que o 'set -e' pare o script.
                aws cloudformation delete-stack --stack-name "$backup_stack" --region us-east-1 2>/dev/null || true
            done
            
            echo "✅ Todos os ambientes removidos"
        else
            echo "❌ Operação cancelada."
        fi
        ;;
    5)
        # Sai do script de forma limpa.
        echo "❌ Operação cancelada."
        exit 0
        ;;
    *)
        # Caso o usuário digite uma opção inválida.
        echo "❌ Opção inválida."
        exit 1 # Sai com um código de erro.
        ;;
esac

# --- Mensagem Final ---
echo ""
echo "🧹 Limpeza de recursos AWS concluída!"
echo "=================================================="
echo "📋 Recursos removidos pela stack do CloudFormation:"
echo "   - Funções Lambda"
echo "   - Tabelas DynamoDB"
echo "   - API Gateway"
echo "   - Tópicos SNS"
echo "   - IAM Roles e Policies"
echo ""
echo "💡 Dica: Use 'aws logs delete-log-group' para remover os grupos de logs restantes se necessário."