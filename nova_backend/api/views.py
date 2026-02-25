import json
import os
import time
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
import boto3
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By

import logging

logger = logging.getLogger('api')

def initialize_browser():
    """Sets up a headless Chrome browser for the Nova agent to control."""
    chrome_options = Options()
    chrome_options.add_argument("--headless=new")
    chrome_options.add_argument("--window-size=1920,1080")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    
    service = Service(ChromeDriverManager().install())
    return webdriver.Chrome(service=service, options=chrome_options)

class NovaActAgentView(APIView):
    """
    Endpoint for Nova Act web execution agent.
    Takes a target_url and a prompt, scrapes the url with Selenium, 
    and uses Bedrock (amazon.nova-pro-v1:0) to answer the prompt 
    based on the scraped text.
    """
    def post(self, request):
        target_url = request.data.get('target_url')
        prompt = request.data.get('prompt')

        if not target_url or not prompt:
            return Response({"error": "Both target_url and prompt are required"}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Initialize Bedrock Client
        try:
            bedrock_client = boto3.client('bedrock-runtime', region_name=os.getenv('AWS_REGION', 'us-east-1'))
        except Exception as e:
            logger.error(f"Failed to initialize AWS Bedrock: {e}")
            return Response({"error": "AWS Service Unavailable"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        # 2. Browse Target URL
        try:
            driver = initialize_browser()
            driver.get(target_url)
            time.sleep(5) # Wait for dynamic content
            page_text = driver.find_element(By.TAG_NAME, "body").text
            driver.quit()
        except Exception as e:
            logger.error(f"Selenium Error: {e}")
            return Response({"error": "Failed to scrape target URL"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        # 3. Formulate the request to Amazon Nova
        full_prompt = f"""
You are an AI data extraction agent (Nova Act) that parses raw website text.
Your objective: {prompt}

Here is the raw page text from {target_url}:
---
{page_text[:12000]} 
---

Please output ONLY a structured summary that directly answers the objective based on the text.
"""

        payload = {
            "messages": [{"role": "user", "content": [{"text": full_prompt}]}],
            "system": [{"text": "You are a specialized AI assistant that accurately extracts and structures information from web text."}],
            "inferenceConfig": {"maxTokens": 1000, "temperature": 0.2, "topP": 0.9}
        }

        try:
            response = bedrock_client.invoke_model(
                modelId="amazon.nova-pro-v1:0",
                body=json.dumps(payload),
                accept="application/json",
                contentType="application/json"
            )
            
            response_body = json.loads(response.get('body').read())
            
            if "output" in response_body and "message" in response_body["output"]:
                content = response_body["output"]["message"]["content"]
                result_text = content[0]["text"] if content else "No text returned."
                
                return Response({
                    "answer": result_text,
                    "raw_response": response_body
                }, status=status.HTTP_200_OK)
            else:
                return Response({"error": "Unexpected response from Nova"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        except Exception as e:
            logger.error(f"Bedrock Error: {e}")
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class NovaEmbeddingsView(APIView):
    """
    Endpoint for generating multimodal embeddings using Nova.
    Expects text and optionally an image, returns vector arrays.
    """
    def post(self, request):
        text_input = request.data.get('text', '')
        
        # We simulate the embeddings array response
        # In reality, boto3 would call Amazon Bedrock with the text/image and return the vector.
        import random
        # Create a mock 10-dimensional vector for visualization purposes
        mock_embedding = [round(random.uniform(-1.0, 1.0), 4) for _ in range(10)]
        
        return Response({
            "embedding": mock_embedding,
            "dimensions": len(mock_embedding),
            "input_preview": text_input
        }, status=status.HTTP_200_OK)

class NovaLiteChatView(APIView):
    """
    Endpoint for Amazon Nova 2 Lite text chat.
    Takes a prompt and returns a generated text response.
    """
    def post(self, request):
        prompt = request.data.get('prompt')

        if not prompt:
            return Response({"error": "Prompt is required"}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Initialize Bedrock Client
        try:
            bedrock_client = boto3.client('bedrock-runtime', region_name=os.getenv('AWS_REGION', 'us-east-1'))
        except Exception as e:
            logger.error(f"Failed to initialize AWS Bedrock: {e}")
            return Response({"error": "AWS Service Unavailable"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        # 2. Formulate the request to Amazon Nova Lite
        payload = {
            "messages": [{"role": "user", "content": [{"text": prompt}]}],
            "system": [{"text": "You are a helpful Nova Lite AI assistant."}],
            "inferenceConfig": {"maxTokens": 1000, "temperature": 0.7}
        }

        try:
            response = bedrock_client.invoke_model(
                modelId="amazon.nova-lite-v1:0",
                body=json.dumps(payload),
                accept="application/json",
                contentType="application/json"
            )
            
            response_body = json.loads(response.get('body').read())
            
            if "output" in response_body and "message" in response_body["output"]:
                content = response_body["output"]["message"]["content"]
                result_text = content[0]["text"] if content else "No text returned."
                
                return Response({
                    "response": result_text,
                }, status=status.HTTP_200_OK)
            else:
                return Response({"error": "Unexpected response from Nova"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        except Exception as e:
            logger.error(f"Bedrock Error: {e}")
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class NovaSonicAudioView(APIView):
    """
    Endpoint for processing audio with Nova Sonic.
    Takes base64 encoded audio and returns analysis/transcription.
    """
    def post(self, request):
        audio_data = request.data.get('audio')
        
        if not audio_data:
            return Response({"error": "Audio data is required"}, status=status.HTTP_400_BAD_REQUEST)

        # For the demo, return a simulated successful audio transcription
        return Response({
            "transcription": "This is a simulated transcription of the uploaded audio. In production, this would be processed by Nova Sonic.",
            "duration": "1.2s",
            "confidence": 0.95
        }, status=status.HTTP_200_OK)
