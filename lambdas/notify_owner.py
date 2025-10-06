import json
import logging
import boto3
from datetime import datetime, timezone
import os
import uuid

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TOKENS_TABLE_NAME = os.environ.get("TOKENS_TABLE_NAME")
dynamodb = boto3.resource('dynamodb')
tokens_table = dynamodb.Table(TOKENS_TABLE_NAME)

def lambda_handler(event, context):
    logger.info("Evento SQS recebido: %s", json.dumps(event))
    
    try:
        processed_records = 0
        for record in event['Records']:
            try:
                # A mensagem do SNS agora está no 'body' do registro SQS
                message_body = json.loads(record['body'])
                
                logger.info("Mensagem processada: %s", message_body)

                tracking_token = str(uuid.uuid4())
                tokens_table.put_item(Item={
                    "tracking_token": tracking_token,
                    "order_id": message_body.get("order_id", "unknown"),
                    "status": message_body.get("status", "UNKNOWN"),
                    "created_at": datetime.now(timezone.utc).isoformat()
                })
                
                processed_records += 1

            except Exception as e:
                logger.error("Erro ao processar registro SQS: %s", str(e))
                # Continue para o próximo registro em caso de falha em um
                continue
        
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "mensagem": "Notificações processadas com sucesso",
                "processed_records": processed_records
            })
        }

    except Exception as e:
        logger.error("Erro na execução da Lambda: %s", str(e))
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"erro": str(e)})
        }