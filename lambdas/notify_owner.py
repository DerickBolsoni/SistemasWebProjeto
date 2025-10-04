import json
import logging
import boto3
from datetime import datetime, timezone
import os
import uuid

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TOKENS_TABLE_NAME = os.environ.get("TOKENS_TABLE_NAME")

def lambda_handler(event, context):
    logger.info("Evento SNS recebido: %s", json.dumps(event))
    try:
        dynamodb = boto3.resource('dynamodb')
        tokens_table = dynamodb.Table(TOKENS_TABLE_NAME)

        records = event.get("Records", [])
        processed = 0

        for record in records:
            sns_message = json.loads(record.get("Sns", {}).get("Message", "{}"))
            logger.info("Mensagem SNS processada: %s", sns_message)

            tracking_token = str(uuid.uuid4())
            tokens_table.put_item(Item={
                "tracking_token": tracking_token,
                "order_id": sns_message.get("pedido", "unknown"),
                "status": sns_message.get("status", "UNKNOWN"),
                "created_at": datetime.now(timezone.utc).isoformat()
            })

            processed += 1

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"mensagem": "Notificações processadas com sucesso", "processed_records": processed})
        }

    except Exception as e:
        logger.error("Erro na execução da Lambda: %s", str(e))
        return {"statusCode": 500, "headers": {"Content-Type": "application/json"}, "body": json.dumps({"erro": str(e)})}
