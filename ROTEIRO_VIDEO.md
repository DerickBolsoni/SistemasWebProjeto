# 🎥 ROTEIRO PARA VÍDEO - FastDelivery Tracker (10-15 min)

## 📋 **ESTRUTURA DO VÍDEO**

### **INTRODUÇÃO (2 minutos)**

**O que falar:**
- "Olá! Sou [seu nome] e vou apresentar o projeto FastDelivery Tracker"
- "É um sistema serverless para entrega de hambúrguer desenvolvido com AWS"
- "O objetivo é gerenciar pedidos e enviar notificações automáticas"
- "Utiliza Lambda, API Gateway, DynamoDB e SNS na região sa-east-1"

**O que mostrar:**
- Tela com título do projeto
- Diagrama de arquitetura (30 segundos)
- Estrutura de pastas do projeto

---

### **ARQUITETURA (3 minutos)**

**O que falar:**
- "A arquitetura segue o padrão serverless da AWS"
- "Cliente faz requisição para API Gateway"
- "API Gateway invoca funções Lambda"
- "Lambda salva dados no DynamoDB"
- "SNS envia notificações automáticas"

**O que mostrar:**
- Diagrama de arquitetura detalhado
- Fluxo passo a passo
- Componentes AWS utilizados

**Pontos-chave:**
- ✅ Região sa-east-1
- ✅ Tópico SNS: FastDeliveryTopic
- ✅ 3 funções Lambda
- ✅ 2 tabelas DynamoDB
- ✅ Template do professor seguido

---

### **DEMONSTRAÇÃO DO CÓDIGO (4 minutos)**

**O que falar:**
- "Vou mostrar as funções Lambda que implementei"
- "Todas seguem o template padrão do professor"
- "Com logging estruturado e tratamento de erros"

**O que mostrar:**

#### **1. Função addOrder (1.5 min)**
```python
# Mostrar o código
# Destacar:
- logger = logging.getLogger()
- logger.setLevel(logging.INFO)
- Template do professor
- Validação de campos
- Integração SNS
```

#### **2. Função setAsDelivered (1.5 min)**
```python
# Mostrar o código
# Destacar:
- Atualização DynamoDB
- Publicação no SNS
- Tratamento de erros
```

#### **3. Função notifyOwner (1 min)**
```python
# Mostrar o código
# Destacar:
- Trigger via SNS
- Processamento de mensagens
- Geração de tokens
```

---

### **DEPLOY E TESTE (3 minutos)**

**O que falar:**
- "Agora vou fazer o deploy e testar o sistema"
- "Primeiro executo o script de setup"
- "Depois o deploy no ambiente DEV"
- "Por fim, testo a API"

**O que mostrar:**

#### **1. Setup (30 seg)**
```bash
./scripts/setup.sh
```

#### **2. Deploy (1 min)**
```bash
./scripts/deploy-dev.sh
```
- Mostrar output do deploy
- Destacar criação dos recursos

#### **3. Teste da API (1.5 min)**
```bash
# Criar pedido
curl -X POST $API_URL/add-order \
  -H 'Content-Type: application/json' \
  -d '{
    "customer_name": "João Silva",
    "customer_email": "joao@email.com",
    "delivery_address": "Rua das Flores, 123",
    "items": ["Hambúrguer Artesanal", "Batata Frita", "Coca-Cola"]
  }'

# Marcar como entregue
curl -X PUT $API_URL/order/ORDER_ID/delivered
```

#### **4. Verificar Logs (30 seg)**
```bash
aws logs tail /aws/lambda/fast-delivery-tracker-add-order-dev --follow
```

---

### **CONCLUSÃO (2 minutos)**

**O que falar:**
- "O sistema está funcionando perfeitamente"
- "Seguimos todos os requisitos do professor"
- "Template padrão implementado"
- "Região sa-east-1 configurada"
- "SNS FastDeliveryTopic funcionando"
- "Logs estruturados implementados"

**O que mostrar:**
- Resumo dos recursos criados
- Logs funcionando
- API respondendo corretamente

**Próximos passos:**
- Deploy em HOM e MAIN
- Monitoramento em produção
- Possíveis melhorias

---

## 🎯 **DICAS PARA GRAVAÇÃO**

### **Preparação:**
- ✅ Teste tudo antes de gravar
- ✅ Tenha a API URL anotada
- ✅ Prepare exemplos de teste
- ✅ Abra todos os arquivos necessários
- ✅ Configure o terminal

### **Durante a gravação:**
- ✅ Fale devagar e claro
- ✅ Mostre o código com zoom adequado
- ✅ Execute comandos sem pressa
- ✅ Explique o que está fazendo
- ✅ Mantenha o foco no tempo

### **Técnicas:**
- **Use zoom no código** para facilitar leitura
- **Destaque linhas importantes** com cursor
- **Execute comandos passo a passo**
- **Mostre resultados claramente**
- **Mantenha ritmo constante**

### **Ferramentas recomendadas:**
- **OBS Studio** (gratuito)
- **Zoom** (para compartilhar tela)
- **Loom** (simples de usar)
- **Screencastify** (extensão Chrome)

---

## 📊 **CRONÔMETRO SUGERIDO**

- **0:00 - 2:00**: Introdução
- **2:00 - 5:00**: Arquitetura
- **5:00 - 9:00**: Código
- **9:00 - 12:00**: Deploy e Teste
- **12:00 - 14:00**: Conclusão

**Total: 14 minutos** (dentro do limite de 10-15 min)

---

## 🚨 **CHECKLIST PRÉ-GRAVAÇÃO**

- [ ] Sistema testado e funcionando
- [ ] API URL anotada
- [ ] Comandos preparados
- [ ] Arquivos abertos
- [ ] Diagrama pronto
- [ ] Microfone funcionando
- [ ] Tela configurada
- [ ] Backup do projeto
