from slack_sdk import WebClient
import os
import boto3
from base64 import b64decode
import json


encrypted_secrets = os.environ['SECRET_VALUE']


#decrypt secret
def decrypt(encrypted_secrets, secret_key):
    kms_client = boto3.client('kms')
    response = kms_client.decrypt(CiphertextBlob=b64decode(encrypted_secrets))
    plaintext = response['Plaintext'].decode('utf-8')
    data = json.loads(plaintext)
    secret_value = data[secret_key]
    return secret_value

#send to Slack
def lambda_handler(event, context):
    token = decrypt(encrypted_secrets, "SLACK_TOKEN")
    client = WebClient(token=token)
    client.chat_postMessage(channel='test', text="Hello from AWS Lambda!")
    return "Message was successfully sent!"
