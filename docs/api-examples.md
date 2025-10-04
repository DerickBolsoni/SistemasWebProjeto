# Exemplos de Uso da API - FastDelivery Tracker

## 🚀 Testando a API

### 1. Criar um Pedido

```bash
curl -X POST https://your-api-gateway-url/orders \
  -H 'Content-Type: application/json' \
  -d '{
    "customer_name": "João Silva",
    "customer_email": "joao.silva@email.com",
    "delivery_address": "Rua das Flores, 123, Bairro Centro",
    "items": [
      "Pizza Margherita Grande",
      "Coca-Cola 2L",
      "Salada Caesar"
    ],
    "special_instructions": "Entregar no portão, não tocar a campainha",
    "estimated_delivery_time": "45 minutos"
  }'
```

**Resposta esperada:**
```json
{
  "message": "Pedido criado com sucesso",
  "order_id": "123e4567-e89b-12d3-a456-426614174000",
  "status": "PENDING"
}
```

### 2. Marcar Pedido como Entregue

```bash
curl -X PUT https://your-api-gateway-url/orders/123e4567-e89b-12d3-a456-426614174000/delivered \
  -H 'Content-Type: application/json'
```

**Resposta esperada:**
```json
{
  "message": "Pedido marcado como entregue e notificação enviada",
  "order_id": "123e4567-e89b-12d3-a456-426614174000",
  "status": "DELIVERED",
  "delivered_at": "2024-01-15T14:30:00Z"
}
```

## 📱 Exemplos com JavaScript

### Criar Pedido (Frontend)

```javascript
async function createOrder(orderData) {
  try {
    const response = await fetch('https://your-api-gateway-url/orders', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(orderData)
    });
    
    const result = await response.json();
    
    if (response.ok) {
      console.log('Pedido criado:', result);
      return result;
    } else {
      console.error('Erro ao criar pedido:', result);
      throw new Error(result.error);
    }
  } catch (error) {
    console.error('Erro na requisição:', error);
    throw error;
  }
}

// Uso
const orderData = {
  customer_name: "Maria Santos",
  customer_email: "maria@email.com",
  delivery_address: "Av. Principal, 456",
  items: ["Hambúrguer Artesanal", "Batata Frita", "Refrigerante"],
  special_instructions: "Sem cebola no hambúrguer"
};

createOrder(orderData)
  .then(order => {
    console.log('Pedido criado com ID:', order.order_id);
  })
  .catch(error => {
    console.error('Falha ao criar pedido:', error);
  });
```

### Marcar como Entregue

```javascript
async function markAsDelivered(orderId) {
  try {
    const response = await fetch(`https://your-api-gateway-url/orders/${orderId}/delivered`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      }
    });
    
    const result = await response.json();
    
    if (response.ok) {
      console.log('Pedido marcado como entregue:', result);
      return result;
    } else {
      console.error('Erro ao marcar como entregue:', result);
      throw new Error(result.error);
    }
  } catch (error) {
    console.error('Erro na requisição:', error);
    throw error;
  }
}

// Uso
markAsDelivered('123e4567-e89b-12d3-a456-426614174000')
  .then(result => {
    console.log('Pedido entregue:', result.delivered_at);
  })
  .catch(error => {
    console.error('Falha ao marcar como entregue:', error);
  });
```

## 🐍 Exemplos com Python

### Cliente Python

```python
import requests
import json

class FastDeliveryClient:
    def __init__(self, base_url):
        self.base_url = base_url
    
    def create_order(self, customer_name, customer_email, delivery_address, items, **kwargs):
        """Cria um novo pedido"""
        payload = {
            "customer_name": customer_name,
            "customer_email": customer_email,
            "delivery_address": delivery_address,
            "items": items
        }
        
        # Adicionar campos opcionais
        if "special_instructions" in kwargs:
            payload["special_instructions"] = kwargs["special_instructions"]
        if "estimated_delivery_time" in kwargs:
            payload["estimated_delivery_time"] = kwargs["estimated_delivery_time"]
        
        response = requests.post(
            f"{self.base_url}/orders",
            headers={"Content-Type": "application/json"},
            data=json.dumps(payload)
        )
        
        if response.status_code == 201:
            return response.json()
        else:
            response.raise_for_status()
    
    def mark_as_delivered(self, order_id):
        """Marca um pedido como entregue"""
        response = requests.put(
            f"{self.base_url}/orders/{order_id}/delivered",
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            response.raise_for_status()

# Uso
client = FastDeliveryClient("https://your-api-gateway-url")

# Criar pedido
try:
    order = client.create_order(
        customer_name="Pedro Oliveira",
        customer_email="pedro@email.com",
        delivery_address="Rua das Palmeiras, 789",
        items=["Pizza Portuguesa", "Guaraná"],
        special_instructions="Entregar no apartamento 301"
    )
    print(f"Pedido criado: {order['order_id']}")
    
    # Simular entrega após 30 minutos
    import time
    time.sleep(2)  # Em produção, isso seria um processo manual
    
    # Marcar como entregue
    delivery_result = client.mark_as_delivered(order['order_id'])
    print(f"Pedido entregue em: {delivery_result['delivered_at']}")
    
except requests.exceptions.RequestException as e:
    print(f"Erro na API: {e}")
```

## 🧪 Testes de Carga

### Teste Simples com Apache Bench

```bash
# Criar arquivo com dados de teste
cat > test_order.json << EOF
{
  "customer_name": "Cliente Teste",
  "customer_email": "teste@email.com",
  "delivery_address": "Endereço Teste, 123",
  "items": ["Item Teste 1", "Item Teste 2"]
}
EOF

# Executar teste de carga
ab -n 100 -c 10 -p test_order.json -T application/json \
   https://your-api-gateway-url/orders
```

## 🔍 Verificação de Logs

### Verificar Logs em Tempo Real

```bash
# Logs da função addOrder
aws logs tail /aws/lambda/fast-delivery-tracker-add-order-dev --follow

# Logs da função setAsDelivered
aws logs tail /aws/lambda/fast-delivery-tracker-set-delivered-dev --follow

# Logs da função notifyOwner
aws logs tail /aws/lambda/fast-delivery-tracker-notify-owner-dev --follow
```

### Filtrar Logs por Erro

```bash
aws logs filter-log-events \
  --log-group-name /aws/lambda/fast-delivery-tracker-add-order-dev \
  --filter-pattern "ERROR"
```

## 📊 Monitoramento

### Verificar Métricas do CloudWatch

```bash
# Métricas de invocações
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=fast-delivery-tracker-add-order-dev \
  --start-time 2024-01-15T00:00:00Z \
  --end-time 2024-01-15T23:59:59Z \
  --period 3600 \
  --statistics Sum

# Métricas de duração
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=fast-delivery-tracker-add-order-dev \
  --start-time 2024-01-15T00:00:00Z \
  --end-time 2024-01-15T23:59:59Z \
  --period 3600 \
  --statistics Average,Maximum
```

## 🚨 Tratamento de Erros

### Códigos de Erro Comuns

| Código | Descrição | Solução |
|--------|-----------|---------|
| 400 | Dados inválidos | Verificar formato do JSON e campos obrigatórios |
| 404 | Pedido não encontrado | Verificar se o order_id existe |
| 500 | Erro interno | Verificar logs do CloudWatch |

### Exemplo de Tratamento de Erros

```javascript
async function handleApiCall(apiCall) {
  try {
    const result = await apiCall();
    return result;
  } catch (error) {
    if (error.response) {
      // Erro da API
      const status = error.response.status;
      const message = error.response.data?.error || 'Erro desconhecido';
      
      switch (status) {
        case 400:
          console.error('Dados inválidos:', message);
          break;
        case 404:
          console.error('Recurso não encontrado:', message);
          break;
        case 500:
          console.error('Erro interno do servidor:', message);
          break;
        default:
          console.error('Erro HTTP:', status, message);
      }
    } else {
      // Erro de rede
      console.error('Erro de conexão:', error.message);
    }
    throw error;
  }
}
```

## 📝 Notas Importantes

1. **Rate Limiting**: A API Gateway tem limites padrão de 10.000 requisições por segundo
2. **Timeout**: Lambda tem timeout padrão de 3 segundos
3. **Payload**: Tamanho máximo do payload é 6MB para Lambda
4. **Logs**: Logs são mantidos por 14 dias por padrão
5. **CORS**: Configurado para permitir todas as origens (`*`)
