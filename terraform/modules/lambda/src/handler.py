import json

def lambda_handler(event, context):
    print("This is a dummy lambda. Will be replaced by Ansible.")
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from dummy Lambda!')
    }
