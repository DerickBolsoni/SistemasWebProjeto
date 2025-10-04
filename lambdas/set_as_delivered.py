import json
import logging
import boto3
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Inicializar clientes AWS
dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')
orders_table = dynamodb.Table('Orders')

def lambda_handler(event, context):
    logger.info("Evento recebido: %s", json.dumps(event))
    try:
        # Extrair order_id dos parâmetros da URL
        order_id = event.get('pathParameters', {}).get('order_id')
        
        if not order_id:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"erro": "order_id é obrigatório"})
            }
        
        # Verificar se o pedido existe
        response = orders_table.get_item(Key={'order_id': order_id})
        if 'Item' not in response:
            return {
                "statusCode": 404,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"erro": "Pedido não encontrado"})
            }
        
        order = response['Item']
        
        # Atualizar status do pedido
        timestamp = datetime.utcnow().isoformat()
        
        orders_table.update_item(
            Key={'order_id': order_id},
            UpdateExpression='SET #status = :status, updated_at = :timestamp',
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':status': 'DELIVERED',
                ':timestamp': timestamp
            }
        )
        
        logger.info("Pedido %s marcado como entregue", order_id)
        
        # Enviar notificação via SNS
        sns.publish(
            TopicArn='arn:aws:sns:sa-east-1:490422578972:FastDeliveryTopic',
            Message=json.dumps({
                "pedido": order_id, 
                "status": "Entregue",
                "acao": "pedido_entregue",
                "cliente": order['customer_name'],
                "entregue_em": timestamp
            })
        )
        
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "mensagem": "Pedido marcado como entregue e notificação enviada",
                "order_id": order_id,
                "status": "DELIVERED",
                "delivered_at": timestamp
            })
        }
        
    except Exception as e:
        logger.error("Erro na execução da Lambda: %s", str(e))
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"erro": "Erro interno na função Lambda."})
        }

