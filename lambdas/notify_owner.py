import json
import logging
import boto3
from datetime import datetime
import uuid

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Inicializar clientes AWS
dynamodb = boto3.resource('dynamodb')
tokens_table = dynamodb.Table('Tokens')
sns = boto3.client('sns')

def lambda_handler(event, context):
    logger.info("Evento SNS recebido: %s", json.dumps(event))
    try:
        # Processar cada record do SNS
        for record in event['Records']:
            try:
                # Extrair mensagem do SNS
                sns_message = json.loads(record['Sns']['Message'])
                logger.info("Mensagem SNS processada: %s", json.dumps(sns_message))
                
                # Extrair dados da mensagem
                pedido_id = sns_message.get('pedido')
                status = sns_message.get('status')
                acao = sns_message.get('acao')
                cliente = sns_message.get('cliente')
                entregue_em = sns_message.get('entregue_em')
                
                if not pedido_id:
                    logger.error("ID do pedido ausente na mensagem SNS")
                    continue
                
                # Gerar token único para tracking
                tracking_token = str(uuid.uuid4())
                timestamp = datetime.utcnow().isoformat()
                
                # Preparar item para tabela Tokens
                token_item = {
                    'tracking_token': tracking_token,
                    'order_id': pedido_id,
                    'status': status,
                    'acao': acao,
                    'cliente': cliente or 'N/A',
                    'entregue_em': entregue_em or timestamp,
                    'created_at': timestamp,
                    'notification_sent': True
                }
                
                # Salvar token no DynamoDB
                tokens_table.put_item(Item=token_item)
                
                logger.info("Token criado com sucesso: %s para pedido: %s", tracking_token, pedido_id)
                
                # Log da notificação processada
                logger.info("Notificação processada - Pedido: %s, Status: %s, Ação: %s", 
                           pedido_id, status, acao)
                
            except Exception as e:
                logger.error("Erro ao processar record SNS: %s", str(e))
                continue
        
        logger.info("Processamento de notificações SNS concluído")
        
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "mensagem": "Notificações processadas com sucesso",
                "processed_records": len(event['Records'])
            })
        }
        
    except Exception as e:
        logger.error("Erro na execução da Lambda: %s", str(e))
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"erro": "Erro interno na função Lambda."})
        }

