import json
import logging
import boto3
from datetime import datetime
import uuid

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Inicializar cliente DynamoDB
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Orders')

def lambda_handler(event, context):
    logger.info("Evento recebido: %s", json.dumps(event))
    try:
        body = json.loads(event.get("body", "{}"))
        
        # Validar campos obrigatórios
        required_fields = ['customer_name', 'customer_email', 'delivery_address', 'items']
        for field in required_fields:
            if field not in body:
                return {
                    "statusCode": 400,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"erro": f"Campo obrigatório ausente: {field}"})
                }
        
        # Criar ID único para o pedido
        order_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        # Preparar item para DynamoDB
        order_item = {
            'order_id': order_id,
            'customer_name': body['customer_name'],
            'customer_email': body['customer_email'],
            'delivery_address': body['delivery_address'],
            'items': body['items'],
            'status': 'PENDING',
            'created_at': timestamp,
            'updated_at': timestamp
        }
        
        # Adicionar campos opcionais se fornecidos
        if 'special_instructions' in body:
            order_item['special_instructions'] = body['special_instructions']
        
        if 'estimated_delivery_time' in body:
            order_item['estimated_delivery_time'] = body['estimated_delivery_time']
        
        # Salvar no DynamoDB
        table.put_item(Item=order_item)
        
        logger.info("Pedido criado com sucesso: %s", order_id)
        
        # Acionar SNS via notify_owner
        sns = boto3.client('sns')
        sns.publish(
            TopicArn='arn:aws:sns:sa-east-1:490422578972:FastDeliveryTopic',
            Message=json.dumps({"pedido": order_id, "status": "Criado", "acao": "novo_pedido"})
        )
        
        return {
            "statusCode": 201,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "mensagem": "Pedido criado com sucesso",
                "order_id": order_id,
                "status": "PENDING"
            })
        }
        
    except Exception as e:
        logger.error("Erro na execução da Lambda: %s", str(e))
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"erro": "Erro interno na função Lambda."})
        }

