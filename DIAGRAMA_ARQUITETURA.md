# 📊 DIAGRAMA DE ARQUITETURA - FastDelivery Tracker

## 🎨 **COMO CRIAR O DIAGRAMA PNG**

### **Opção 1: Usar Mermaid Online (Recomendado)**

1. **Acesse**: https://mermaid.live/
2. **Cole o código abaixo**:
3. **Clique em "Download PNG"**

### **Código Mermaid para o Diagrama:**

```mermaid
graph TB
    subgraph "Cliente"
        APP[App Hamburgueria<br/>Mobile/Web]
    end
    
    subgraph "AWS Cloud - Região sa-east-1"
        subgraph "API Layer"
            APIGW[API Gateway REST<br/>FastDeliveryAPI]
        end
        
        subgraph "Compute Layer"
            AO[addOrder Lambda<br/>Criar Pedidos]
            SD[setAsDelivered Lambda<br/>Marcar Entregue]
            NO[notifyOwner Lambda<br/>Processar Notificações]
        end
        
        subgraph "Data Layer"
            OD[(DynamoDB<br/>Orders Table)]
            TD[(DynamoDB<br/>Tokens Table)]
        end
        
        subgraph "Messaging"
            SNS[SNS Topic<br/>FastDeliveryTopic]
        end
        
        subgraph "Monitoring"
            CW[CloudWatch<br/>Logs & Metrics]
        end
    end
    
    %% Fluxo Principal
    APP -->|POST /add-order| APIGW
    APIGW -->|Invoke| AO
    AO -->|PutItem| OD
    AO -->|Publish| SNS
    
    APP -->|PUT /order/{id}/delivered| APIGW
    APIGW -->|Invoke| SD
    SD -->|UpdateItem| OD
    SD -->|Publish| SNS
    
    SNS -->|Trigger| NO
    NO -->|PutItem| TD
    
    %% Logs
    AO --> CW
    SD --> CW
    NO --> CW
    
    %% Styling
    classDef client fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef api fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef lambda fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef database fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef messaging fill:#fff8e1,stroke:#f57f17,stroke-width:2px
    classDef monitoring fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    
    class APP client
    class APIGW api
    class AO,SD,NO lambda
    class OD,TD database
    class SNS messaging
    class CW monitoring
```

### **Opção 2: Usar Draw.io (LivreOffice)**

1. **Acesse**: https://app.diagrams.net/
2. **Crie novo diagrama**
3. **Use os componentes AWS**
4. **Siga a estrutura do diagrama acima**

### **Opção 3: Usar Lucidchart**

1. **Acesse**: https://lucid.app/
2. **Crie novo diagrama AWS**
3. **Arraste os componentes**
4. **Conecte conforme o fluxo**

## 📝 **ELEMENTOS DO DIAGRAMA:**

### **Componentes AWS:**
- **API Gateway**: Ponto de entrada REST
- **Lambda Functions**: 3 funções (addOrder, setAsDelivered, notifyOwner)
- **DynamoDB**: 2 tabelas (Orders, Tokens)
- **SNS**: Tópico de notificações
- **CloudWatch**: Logs e monitoramento

### **Fluxos:**
1. **Cliente → API → Lambda → DynamoDB**
2. **Lambda → SNS → Lambda (notifyOwner)**
3. **Todas as funções → CloudWatch**

### **Cores Sugeridas:**
- **Cliente**: Azul claro
- **API Gateway**: Laranja
- **Lambda**: Roxo
- **DynamoDB**: Verde
- **SNS**: Amarelo
- **CloudWatch**: Rosa

## 🎯 **DICAS PARA O DIAGRAMA:**

1. **Mantenha simples**: Não sobrecarregue com detalhes
2. **Use cores consistentes**: Cada serviço uma cor
3. **Mostre o fluxo**: Setas indicando direção
4. **Inclua região**: Sempre mencionar sa-east-1
5. **Título claro**: "FastDelivery Tracker - Arquitetura AWS"

## 📱 **Para o Vídeo:**

- **Mostre o diagrama** nos primeiros 30 segundos
- **Explique cada componente** brevemente
- **Destaque o fluxo principal**: Cliente → API → Lambda → DB
- **Mencione a região sa-east-1**
- **Enfatize que é serverless**
