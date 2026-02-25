import boto3
import json
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

class BedrockClient:
    """
    A unified client for interacting with Amazon Nova models via AWS Bedrock.
    """
    def __init__(self):
        self.region = settings.AWS_REGION
        try:
            # Assumes AWS credentials are provided via environment variables (.env)
            # AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY or an IAM role.
            self.client = boto3.client(
                service_name='bedrock-runtime',
                region_name=self.region
            )
        except Exception as e:
            logger.error(f"Failed to initialize boto3 client: {str(e)}")
            self.client = None

    def invoke_nova_lite(self, prompt: str) -> str:
        """
        Invokes the Nova 2 Lite model for everyday reasoning tasks.
        Model ID might vary based on the actual AWS release name, using placeholder for Nova Lite.
        e.g., 'amazon.nova-lite-v1:0'
        """
        if not self.client:
            return "Error: Bedrock client is not initialized. Please check AWS credentials."

        model_id = 'amazon.nova-lite-v1:0' # Placeholder, replace with actual Nova Lite ID when available
        
        # Converse API format for Nova
        messages = [{
            "role": "user",
            "content": [{"text": prompt}]
        }]

        try:
            response = self.client.converse(
                modelId=model_id,
                messages=messages,
                inferenceConfig={
                    "maxTokens": 512,
                    "temperature": 0.7,
                }
            )
            return response['output']['message']['content'][0]['text']
        except Exception as e:
            logger.error(f"Nova Lite invocation failed: {str(e)}")
            return f"Model invocation failed: {str(e)}"
    
    def invoke_nova_sonic_tts(self, base64_audio: str):
        """
        Implementation for speech-generation/speech-to-speech.
        Accepts a base64 encoded audio payload.
        """
        if not self.client:
            return {"text_reply": "Error: AWS credentials missing.", "audio_base64": ""}

        logger.debug("Received Sonic audio payload: %d bytes (base64 length)", len(base64_audio) if base64_audio else 0)

        # Since we are mocking Bedrock until actual audio API structures for Nova open up,
        # we will load a short sample audio we generated.
        import os
        from django.conf import settings
        
        audio_reply_base64 = "UklGRiQAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YQAAAAA="
        try:
            sample_path = os.path.join(settings.BASE_DIR, 'base64_audio.txt')
            if os.path.exists(sample_path):
                with open(sample_path, 'r') as f:
                    audio_reply_base64 = f.read().strip()
        except:
            pass

        return {
            "text_reply": "Nova Sonic successfully processed your audio. This is a simulated textual and vocal response.",
            "audio_reply_base64": audio_reply_base64
        }

    def invoke_nova_embeddings(self, text: str, image_bytes: bytes = None):
        # Implementation for multimodal embeddings
        pass

# Create a singleton instance for use across the Django app
bedrock = BedrockClient()
