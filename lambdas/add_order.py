import json
import boto3
import uuid
import os
from datetime import datetime
from botocore.exceptions import ClientError

# Ambiente
ORDERS_TABLE = os.environ.get("ORDERS_TABLE", "Orders")
SNS_TOPIC_ARN = os.environ.get("ORDERS_TOPIC_ARN")  # informe no Lambda

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(ORDERS_TABLE)
sns_client = boto3.client("sns")

def lambda_handler(event, context):
    try:
        # 🚩 Aceita o evento do API Gateway ou do teste manual
        if "body" in event:
            body = json.loads(event["body"])
        else:
            body = event

        # Validação básica
        if not all(k in body for k in ("customer_name","customer_email","delivery_address","items")):
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"erro": "Campos obrigatórios ausentes"})
            }

        order_id = str(uuid.uuid4())
        order = {
            "order_id": order_id,
            "customer_name": body["customer_name"],
            "customer_email": body["customer_email"],
            "delivery_address": body["delivery_address"],
            "items": body["items"],
            "status": "Criado",
            "created_at": datetime.utcnow().isoformat()
        }

        # Grava no DynamoDB
        table.put_item(Item=order)

        # Publica no SNS (opcional)
        if SNS_TOPIC_ARN:
            sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=json.dumps(order),
                Subject="Novo Pedido Criado"
            )

        return {
            "statusCode": 201,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "mensagem": "Pedido criado com sucesso",
                "order_id": order_id
            })
        }

    except ClientError as e:
        print(f"Erro AWS: {e}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"erro": "Erro AWS", "detalhe": str(e)})
        }

    except Exception as e:
        print(f"Erro geral: {e}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"erro": "Erro geral", "detalhe": str(e)})
        }
