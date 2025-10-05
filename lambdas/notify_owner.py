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
        # --- Processamento em Lote das Notificações ---
        # Um único evento do SNS pode conter várias mensagens (records).
        # O 'for' loop garante que todas as mensagens sejam processadas individualmente.
        for record in event['Records']:
            
            # --- Bloco de Erro por Mensagem ---
            # Este 'try/except' interno é crucial: se uma mensagem falhar,
            # o 'continue' pula para a próxima, evitando que o lote inteiro pare por um único erro.
            try:
                # Extrai a mensagem real, que está dentro da estrutura do evento SNS.
                sns_message = json.loads(record['Sns']['Message'])
                logger.info("Mensagem SNS processada: %s", json.dumps(sns_message))
                
                # --- Extração Segura dos Dados ---
                # Usa o método .get() para extrair os dados da mensagem.
                # Isso evita erros caso uma chave não exista (retornando 'None' em vez de quebrar a execução).
                pedido_id = sns_message.get('pedido')
                status = sns_message.get('status')
                acao = sns_message.get('acao')
                cliente = sns_message.get('cliente')
                entregue_em = sns_message.get('entregue_em')
                
                # --- Validação Mínima ---
                # Verifica se o dado mais importante (ID do pedido) está presente.
                if not pedido_id:
                    logger.error("ID do pedido ausente na mensagem SNS")
                    continue  # Pula para o próximo 'record' do loop

                # --- Geração do Token de Rastreamento ---
                # Cria um token de rastreamento único e universal.
                tracking_token = str(uuid.uuid4())
                timestamp = datetime.utcnow().isoformat()
                
                # --- Montagem do Item para a Tabela 'Tokens' ---
                # Cria um dicionário que representa o token a ser salvo no DynamoDB.
                token_item = {
                    'tracking_token': tracking_token,  # Chave de partição (identificador único)
                    'order_id': pedido_id,
                    'status': status,
                    'acao': acao,
                    # Usa 'or' para definir um valor padrão caso o campo seja nulo ou vazio.
                    'cliente': cliente or 'N/A', 
                    'entregue_em': entregue_em or timestamp,
                    'created_at': timestamp,
                    'notification_sent': True  # Flag para indicar que a notificação foi processada
                }
                
                # --- Persistência no Banco de Dados ---
                # Salva o item (token) na tabela 'Tokens' do DynamoDB.
                tokens_table.put_item(Item=token_item)
                
                logger.info("Token criado com sucesso: %s para pedido: %s", tracking_token, pedido_id)
                
                # Log de confirmação para monitoramento
                logger.info("Notificação processada - Pedido: %s, Status: %s, Ação: %s", 
                            pedido_id, status, acao)
                
            except Exception as e:
                # Captura e loga o erro específico daquela mensagem SNS.
                logger.error("Erro ao processar record SNS: %s", str(e))
                continue  # Garante que a execução continue com a próxima mensagem.
        
        logger.info("Processamento de notificações SNS concluído")
        
        # --- Resposta de Sucesso ---
        # Retorna uma resposta 200 (OK) indicando que o processamento terminou.
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "mensagem": "Notificações processadas com sucesso",
                "processed_records": len(event['Records']) # Informa quantos records foram processados
            })
        }
        
    # --- Bloco de Captura de Erros Gerais ---
    except Exception as e:
        # Captura erros que podem ocorrer fora do loop (ex: evento malformado).
        logger.error("Erro na execução da Lambda: %s", str(e))
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"erro": "Erro interno na função Lambda."})
        }