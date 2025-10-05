import json
import logging
import boto3
from datetime import datetime, timezone
import os
# --- Importação das bibliotecas necessárias ---
import json  # Para manipular dados no formato JSON
import logging  # Para registrar logs de execução no CloudWatch
import boto3  # SDK da AWS para interagir com serviços
from datetime import datetime  # Para gerar timestamps
import uuid  # Para gerar identificadores únicos para os tokens

# --- Configuração do Logger ---
# Inicializa o logger para registrar informações e erros.
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ORDERS_TABLE_NAME = os.environ.get("ORDERS_TABLE_NAME")
TOKENS_TABLE_NAME = os.environ.get("TOKENS_TABLE_NAME")
# --- Inicialização dos clientes da AWS ---
# Cria um objeto de recurso para interagir com o DynamoDB.
dynamodb = boto3.resource('dynamodb')
# Aponta para a tabela específica 'Tokens' onde os tokens de rastreamento serão salvos.
tokens_table = dynamodb.Table('Tokens')
# Inicializa o cliente do SNS (neste código, não é usado para publicar, mas é uma boa prática inicializar os clientes no escopo global).
sns = boto3.client('sns')

# --- Função Principal (Handler) ---
# Esta função é acionada por uma notificação enviada a um Tópico SNS.
# Seu principal objetivo é processar essa notificação, gerar um token e salvá-lo.
def lambda_handler(event, context):
    # Loga o evento completo recebido do SNS para fins de depuração.
    logger.info("Evento SNS recebido: %s", json.dumps(event))
    
    # --- Bloco Principal de Tratamento de Erros ---
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
        # Captura erros que podem ocorrer fora do loop (ex: evento malformado).
        logger.error("Erro na execução da Lambda: %s", str(e))
        return {"statusCode": 500, "headers": {"Content-Type": "application/json"}, "body": json.dumps({"erro": str(e)})}
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"erro": "Erro interno na função Lambda."})
        }
