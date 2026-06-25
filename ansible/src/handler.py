import json
import boto3
import os
import urllib.parse
from fpdf import FPDF
import tempfile

s3 = boto3.client('s3')

def lambda_handler(event, context):
    try:
        dest_bucket = os.environ['DEST_BUCKET']
        
        for record in event['Records']:
            source_bucket = record['s3']['bucket']['name']
            key = urllib.parse.unquote_plus(record['s3']['object']['key'])
            
            # Download file
            download_path = os.path.join(tempfile.gettempdir(), os.path.basename(key))
            s3.download_file(source_bucket, key, download_path)
            
            # Convert to PDF
            pdf = FPDF()
            pdf.add_page()
            # FPDF supports JPEG, PNG, GIF
            try:
                pdf.image(download_path, x=10, y=10, w=190)
            except Exception as e:
                print(f"Error reading image: {e}")
                # Fallback if image format not supported
                pdf.set_font("Arial", size=15)
                pdf.cell(200, 10, txt="Unsupported image format or corrupt file.", ln=1, align='C')
            
            new_key = os.path.splitext(key)[0] + '.pdf'
            upload_path = os.path.join(tempfile.gettempdir(), os.path.basename(new_key))
            pdf.output(upload_path)
            
            # Upload PDF
            s3.upload_file(upload_path, dest_bucket, new_key)
            
        return {
            'statusCode': 200,
            'body': json.dumps('Successfully converted to PDF')
        }
    except Exception as e:
        print(f"Error: {e}")
        raise e
