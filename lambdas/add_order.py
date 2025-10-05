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
# --- Importação das bibliotecas necessárias ---
import json  # Para manipular dados no formato JSON (recebidos do API Gateway)
import logging  # Para registrar logs e monitorar a execução da função no CloudWatch
import boto3  # SDK da AWS para Python, para interagir com serviços como DynamoDB e SNS
from datetime import datetime  # Para gerar timestamps (data e hora)
import uuid  # Para gerar identificadores únicos universais (ID do pedido)

# --- Configuração do Logger ---
# Inicializa o logger para que possamos enviar mensagens para o Amazon CloudWatch.
logger = logging.getLogger()
logger.setLevel(logging.INFO)  # Define o nível de log para INFO, capturando informações úteis.

# --- Inicialização dos clientes da AWS ---
# Cria um objeto de recurso para interagir com o DynamoDB.
dynamodb = boto3.resource('dynamodb')
# Aponta para a tabela específica 'Orders' onde os pedidos serão armazenados.
table = dynamodb.Table('Orders')

# --- Função Principal (Handler) ---
# Esta é a função que a AWS Lambda executa quando o serviço é acionado.
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

    # Loga o evento de entrada completo. É uma boa prática para depuração.
    logger.info("Evento recebido: %s", json.dumps(event))
    
    # --- Bloco de Tratamento de Erros (Try/Except) ---
    # Tenta executar o código principal. Se qualquer erro ocorrer, o bloco 'except' será acionado.
    try:
        # Extrai o corpo (body) da requisição HTTP. O 'get' evita erros se o corpo não existir.
        body = json.loads(event.get("body", "{}"))
        
        # --- Validação dos Dados de Entrada ---
        # Define uma lista de campos que são obrigatórios para criar um pedido.
        required_fields = ['customer_name', 'customer_email', 'delivery_address', 'items']
        # Itera sobre os campos obrigatórios para verificar se todos foram enviados.
        for field in required_fields:
            if field not in body:
                # Se um campo estiver faltando, retorna um erro 400 (Bad Request) informando o cliente.
                logger.error("Erro de validação: campo '%s' ausente.", field)
                return {
                    "statusCode": 400,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"erro": f"Campo obrigatório ausente: {field}"})
                }
        
        # --- Geração de Dados para o Novo Pedido ---
        # Cria um ID de pedido único e universal usando a biblioteca uuid.
        order_id = str(uuid.uuid4())
        # Pega a data e hora atuais no formato ISO 8601 UTC.
        timestamp = datetime.utcnow().isoformat()
        
        # --- Montagem do Item para o DynamoDB ---
        # Cria um dicionário (objeto) que representa o pedido a ser salvo no banco de dados.
        order_item = {
            'order_id': order_id,  # Chave de partição (identificador único)
            'customer_name': body['customer_name'],
            'customer_email': body['customer_email'],
            'delivery_address': body['delivery_address'],
            'items': body['items'],
            'status': 'PENDING',  # Status inicial do pedido
            'created_at': timestamp,  # Data de criação
            'updated_at': timestamp   # Data da última atualização (inicialmente a mesma da criação)
        }
        
        # --- Adição de Campos Opcionais ---
        # Verifica se informações extras foram enviadas e as adiciona ao item.
        if 'special_instructions' in body:
            order_item['special_instructions'] = body['special_instructions']
        
        if 'estimated_delivery_time' in body:
            order_item['estimated_delivery_time'] = body['estimated_delivery_time']
        
        # --- Persistência no Banco de Dados ---
        # Salva o item (pedido) na tabela 'Orders' do DynamoDB.
        table.put_item(Item=order_item)
        
        logger.info("Pedido criado com sucesso: %s", order_id)
        
        # --- Notificação via SNS (Simple Notification Service) ---
        # Aciona um tópico do SNS para notificar outros sistemas (ou Lambdas) sobre o novo pedido.
        # Isso desacopla os serviços: esta função não precisa saber quem vai processar a notificação.
        sns = boto3.client('sns')
        sns.publish(
            TopicArn='arn:aws:sns:sa-east-1:490422578972:FastDeliveryTopic',  # ARN (endereço) do tópico
            Message=json.dumps({"pedido": order_id, "status": "Criado", "acao": "novo_pedido"})
        )
        
        # --- Resposta de Sucesso ---
        # Retorna uma resposta HTTP 201 (Created) para o cliente, confirmando que o pedido foi criado.
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
        
    # --- Bloco de Captura de Erros ---
    except Exception as e:
        # Se qualquer erro inesperado acontecer no bloco 'try', ele será capturado aqui.
        logger.error("Erro na execução da Lambda: %s", str(e))
        # Retorna um erro 500 (Internal Server Error), informando que algo deu errado no servidor.
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"erro": "Erro interno na função Lambda."})
        }
