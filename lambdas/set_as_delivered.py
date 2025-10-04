import json
import logging
import boto3
from datetime import datetime, timezone
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ORDERS_TABLE_NAME = os.environ.get("ORDERS_TABLE_NAME")
TOKENS_TABLE_NAME = os.environ.get("TOKENS_TABLE_NAME")

def lambda_handler(event, context):
    logger.info("Evento recebido: %s", json.dumps(event))
    try:
        dynamodb = boto3.resource('dynamodb')
        orders_table = dynamodb.Table(ORDERS_TABLE_NAME)
        tokens_table = dynamodb.Table(TOKENS_TABLE_NAME)

        path_params = event.get("pathParameters") or {}
        order_id = path_params.get("order_id")
        if not order_id:
            return {"statusCode": 400, "body": json.dumps({"erro": "order_id é obrigatório"})}

        timestamp = datetime.now(timezone.utc).isoformat()

        # Atualiza status no Orders
        orders_table.update_item(
            Key={"order_id": order_id},
            UpdateExpression="SET #s = :s, updated_at = :u",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":s": "DELIVERED", ":u": timestamp}
        )

        # Gravar status na tabela Tokens (necessário tracking_token)
        tracking_token = str(uuid.uuid4())
        tokens_table.put_item(Item={
            "tracking_token": tracking_token,
            "order_id": order_id,
            "status": "DELIVERED",
            "updated_at": timestamp
        })

        # Publicar SNS
        sns = boto3.client('sns')
        sns.publish(
            TopicArn=os.environ["SNS_TOPIC_ARN"],
            Message=json.dumps({
                "pedido": order_id,
                "tracking_token": tracking_token,
                "status": "DELIVERED",
                "acao": "pedido_entregue"
            })
        )

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"mensagem": "Pedido marcado como entregue", "order_id": order_id})
        }

    except Exception as e:
        logger.error("Erro na execução da Lambda: %s", str(e))
        return {"statusCode": 500, "headers": {"Content-Type": "application/json"}, "body": json.dumps({"erro": str(e)})}
