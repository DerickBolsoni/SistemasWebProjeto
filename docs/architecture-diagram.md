# Diagramas de Arquitetura - FastDelivery Tracker 🍔

## Arquitetura Geral do Sistema (Conforme Requisitos do Professor)

```mermaid
graph TB
    Client[Cliente / App Hamburgueria] --> APIGW[API Gateway REST]
    
    APIGW --> AddOrder[addOrder Lambda]
    APIGW --> SetDelivered[setAsDelivered Lambda]
    
    AddOrder --> OrdersDB[(DynamoDB<br/>Orders)]
    SetDelivered --> OrdersDB
    SetDelivered --> SNS[SNS Topic<br/>FastDeliveryTopic]
    
    SNS --> NotifyOwner[notifyOwner Lambda]
    NotifyOwner --> TokensDB[(DynamoDB<br/>Tokens)]
    
    subgraph "AWS Cloud - Região sa-east-1"
        subgraph "API Layer"
            APIGW
        end
        
        subgraph "Compute Layer"
            AddOrder
            SetDelivered
            NotifyOwner
        end
        
        subgraph "Data Layer"
            OrdersDB
            TokensDB
        end
        
        subgraph "Messaging"
            SNS
        end
        
        subgraph "Monitoring"
            CloudWatch[CloudWatch Logs]
        end
    end
    
    AddOrder --> CloudWatch
    SetDelivered --> CloudWatch
    NotifyOwner --> CloudWatch
    
    style Client fill:#e1f5fe
    style APIGW fill:#fff3e0
    style AddOrder fill:#f3e5f5
    style SetDelivered fill:#f3e5f5
    style NotifyOwner fill:#f3e5f5
    style OrdersDB fill:#e8f5e8
    style TokensDB fill:#e8f5e8
    style SNS fill:#fff8e1
    style CloudWatch fill:#fce4ec
```

## Fluxo de Dados Detalhado (Sistema de Hamburgueria)

```mermaid
sequenceDiagram
    participant C as Cliente Hamburgueria
    participant API as API Gateway
    participant AO as addOrder Lambda
    participant OD as Orders DB
    participant SD as setAsDelivered Lambda
    participant SNS as SNS FastDeliveryTopic
    participant NO as notifyOwner Lambda
    participant TD as Tokens DB
    
    Note over C,TD: Fluxo 1: Criação de Pedido de Hambúrguer
    C->>API: POST /add-order
    API->>AO: Invoke Lambda
    AO->>OD: PutItem (novo pedido)
    OD-->>AO: Confirmação
    AO->>SNS: Publish (notificação novo pedido)
    SNS-->>AO: MessageId
    AO-->>API: 201 Created
    API-->>C: Pedido criado
    
    Note over C,TD: Fluxo 2: Marcar Pedido como Entregue
    C->>API: PUT /order/{id}/delivered
    API->>SD: Invoke Lambda
    SD->>OD: UpdateItem (status = DELIVERED)
    OD-->>SD: Confirmação
    SD->>SNS: Publish (notificação entrega)
    SNS-->>SD: MessageId
    SD-->>API: 200 OK
    API-->>C: Pedido entregue
    
    Note over C,TD: Fluxo 3: Processamento de Notificação
    SNS->>NO: Invoke Lambda (SNS trigger)
    NO->>TD: PutItem (novo token)
    TD-->>NO: Confirmação
    NO-->>SNS: 200 OK
```

## Arquitetura por Ambiente (sa-east-1)

```mermaid
graph LR
    subgraph "Ambientes AWS"
        DEV[DEV<br/>Desenvolvimento]
        HOM[HOM<br/>Homologação]
        MAIN[MAIN<br/>Produção]
    end
    
    subgraph "Dev Environment - sa-east-1"
        DEVAPI[FastDeliveryAPI-dev]
        DEVL1[addOrder-dev]
        DEVL2[setAsDelivered-dev]
        DEVL3[notifyOwner-dev]
        DEVD1[Orders-dev]
        DEVD2[Tokens-dev]
        DEVSNSS[FastDeliveryTopic]
    end
    
    subgraph "Hom Environment - sa-east-1"
        HOMAPI[FastDeliveryAPI-hom]
        HOML1[addOrder-hom]
        HOML2[setAsDelivered-hom]
        HOML3[notifyOwner-hom]
        HOMD1[Orders-hom]
        HOMD2[Tokens-hom]
        HOMSNSS[FastDeliveryTopic]
    end
    
    subgraph "Main Environment - sa-east-1"
        MAINAPI[FastDeliveryAPI-main]
        MAINL1[addOrder-main]
        MAINL2[setAsDelivered-main]
        MAINL3[notifyOwner-main]
        MAIND1[Orders-main]
        MAIND2[Tokens-main]
        MAINSNSS[FastDeliveryTopic]
    end
    
    DEV --> DEVAPI
    HOM --> HOMAPI
    MAIN --> MAINAPI
```

## Estrutura de Dados (DynamoDB)

```mermaid
erDiagram
    ORDERS {
        string order_id PK
        string customer_name
        string customer_email
        string delivery_address
        array items
        string status
        string created_at
        string updated_at
        string special_instructions
        string estimated_delivery_time
    }
    
    TOKENS {
        string tracking_token PK
        string order_id FK
        string status
        string acao
        string cliente
        string entregue_em
        string created_at
        boolean notification_sent
    }
    
    ORDERS ||--o{ TOKENS : "gera"
```

### Campos das Tabelas:

**Orders Table:**
- `order_id`: Identificador único do pedido (PK)
- `customer_name`: Nome do cliente
- `customer_email`: Email do cliente
- `delivery_address`: Endereço de entrega
- `items`: Lista de itens do pedido (ex: ["Hambúrguer", "Batata Frita"])
- `status`: Status do pedido (PENDING/DELIVERED)
- `created_at`: Data de criação
- `updated_at`: Data de última atualização
- `special_instructions`: Instruções especiais (opcional)
- `estimated_delivery_time`: Tempo estimado de entrega (opcional)

**Tokens Table:**
- `tracking_token`: Token único de rastreamento (PK)
- `order_id`: Referência ao pedido (FK)
- `status`: Status da notificação
- `acao`: Tipo de ação (novo_pedido/pedido_entregue)
- `cliente`: Nome do cliente
- `entregue_em`: Data/hora da entrega
- `created_at`: Data de criação do token
- `notification_sent`: Se a notificação foi enviada

## Monitoramento e Logs

```mermaid
graph TB
    subgraph "AWS Services"
        Lambda[Lambda Functions]
        APIGW[API Gateway]
        DynamoDB[DynamoDB]
        SNS[SNS]
    end
    
    subgraph "Monitoring"
        CloudWatch[CloudWatch Logs]
        Metrics[CloudWatch Metrics]
        Alarms[CloudWatch Alarms]
    end
    
    subgraph "Observability"
        Traces[X-Ray Tracing]
        Dashboards[CloudWatch Dashboards]
    end
    
    Lambda --> CloudWatch
    APIGW --> CloudWatch
    DynamoDB --> Metrics
    SNS --> Metrics
    
    CloudWatch --> Alarms
    Metrics --> Dashboards
    Lambda --> Traces
    APIGW --> Traces
```

## Segurança e IAM

```mermaid
graph TB
    subgraph "IAM Roles"
        LambdaRole[LambdaExecutionRole]
    end
    
    subgraph "IAM Policies"
        DynamoDBPolicy[DynamoDB Access]
        SNSPolicy[SNS Publish]
        LogsPolicy[CloudWatch Logs]
    end
    
    subgraph "Resources"
        OrdersTable[Orders Table]
        TokensTable[Tokens Table]
        SNSTopic[SNS Topic]
    end
    
    LambdaRole --> DynamoDBPolicy
    LambdaRole --> SNSPolicy
    LambdaRole --> LogsPolicy
    
    DynamoDBPolicy --> OrdersTable
    DynamoDBPolicy --> TokensTable
    SNSPolicy --> SNSTopic
```

## Fluxo de Deploy

```mermaid
graph LR
    subgraph "Development"
        Code[Código Python]
        Template[CloudFormation]
        Scripts[Deploy Scripts]
    end
    
    subgraph "Build"
        Package[Lambda Package]
        Validate[Template Validation]
    end
    
    subgraph "Deploy"
        DEV[Deploy DEV]
        HOM[Deploy HOM]
        MAIN[Deploy MAIN]
    end
    
    subgraph "AWS"
        DEVStack[DEV Stack]
        HOMStack[HOM Stack]
        MAINStack[MAIN Stack]
    end
    
    Code --> Package
    Template --> Validate
    Package --> DEV
    Validate --> DEV
    DEV --> DEVStack
    DEVStack --> HOM
    HOM --> HOMStack
    HOMStack --> MAIN
    MAIN --> MAINStack
```
