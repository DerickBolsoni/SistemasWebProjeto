# 🔧 GUIA GIT - FastDelivery Tracker

## ⚠️ IMPORTANTE: FLUXO GIT CORRETO (NÃO PERDER PONTOS!)

### 1. **Configurar Git (se ainda não fez)**
```bash
git config --global user.name "Seu Nome"
git config --global user.email "seu.email@example.com"
```

### 2. **Inicializar Repositório**
```bash
# Se ainda não é um repositório Git
git init

# Adicionar remote (se tiver)
git remote add origin https://github.com/seu-usuario/seu-repositorio.git
```

### 3. **CRIAR BRANCH PESSOAL (OBRIGATÓRIO)**
```bash
# NUNCA commite direto na main!
git checkout -b dev_seu_nome
# Exemplo: git checkout -b dev_derick_bolsoni
```

### 4. **Fazer Commits na SUA Branch**
```bash
# Adicionar todos os arquivos
git add .

# Fazer commit
git commit -m "Implementação completa do FastDelivery Tracker

- Funções Lambda: addOrder, setAsDelivered, notifyOwner
- API Gateway com endpoint /add-order
- DynamoDB: tabelas Orders e Tokens
- SNS: tópico FastDeliveryTopic
- Scripts de deploy para 3 ambientes
- Documentação completa
- Região sa-east-1 configurada
- Template do professor seguido"

# Push para sua branch
git push origin dev_seu_nome
```

### 5. **Criar Pull Request**
- Vá para GitHub/GitLab
- Crie Pull Request: `dev_seu_nome` → `dev`
- Aguarde revisão e aprovação

### 6. **Após Aprovação**
```bash
# Merge para dev (após aprovação)
# Depois pode merge para main
```

## 🚨 **NUNCA FAÇA:**
- ❌ Commits diretos na `main`
- ❌ Push direto na `main`
- ❌ Ignorar o fluxo de branches

## ✅ **SEMPRE FAÇA:**
- ✅ Commits na sua branch pessoal
- ✅ Pull Request para revisão
- ✅ Seguir o fluxo: dev_seu_nome → dev → main
