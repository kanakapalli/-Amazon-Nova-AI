import boto3
import json
import os
import time
from dotenv import load_dotenv
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By

# Load environment variables from nova_backend/.env if present
load_dotenv(os.path.join(os.path.dirname(__file__), 'nova_backend', '.env'))

def initialize_browser():
    """Sets up a headless Chrome browser for the Nova agent to control."""
    print("-> Initializing headless Chrome...")
    chrome_options = Options()
    chrome_options.add_argument("--headless=new")
    chrome_options.add_argument("--window-size=1920,1080")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    
    service = Service(ChromeDriverManager().install())
    return webdriver.Chrome(service=service, options=chrome_options)

def run_nova_act_devpost_search():
    """
    This script acts as a standalone Amazon Nova Act agent to navigate Devpost 
    and identify high-value hackathons based on scraped text.
    """
    print("=== Amazon Nova Act: Independent Web Agent ===")
    print("Objective: Find the latest top 5 hackathons from Devpost with prize money > $40,000.")
    print("-" * 60)
    
    # 1. Initialize Bedrock Client
    try:
        bedrock_client = boto3.client('bedrock-runtime', region_name=os.getenv('AWS_REGION', 'us-east-1'))
    except Exception as e:
        print(f"Failed to initialize AWS Bedrock: {e}")
        return

    # 2. Browse Devpost
    driver = initialize_browser()
    target_url = "https://devpost.com/hackathons"
    print(f"-> Navigating to {target_url}...")
    driver.get(target_url)
    
    # Allow time for JavaScript to render hackathon listings
    time.sleep(5) 
    
    # Extract the visible text from the page
    print("-> Extracting page content...")
    page_text = driver.find_element(By.TAG_NAME, "body").text
    driver.quit()
    print("-> Browser closed. Page content extracted.")

    # 3. Formulate the request to Amazon Nova
    prompt = f"""
You are an AI data extraction agent (Nova Act) that parses raw website text.
Your objective: Find the top 5 hackathons that have a listed prize money of over $40,000. 

For each hackathon, provide:
1. The Hackathon Name
2. The Prize Amount
3. A brief description or deadline (if available in the text)

Here is the raw page text from Devpost:
---
{page_text[:12000]} 
---

Please output ONLY a structured summary of the top 5 hackathons that meet the >$40,000 criteria.
"""

    payload = {
        "messages": [
            {
                "role": "user",
                "content": [{"text": prompt}]
            }
        ],
        "system": [
            {
                "text": "You are a specialized AI assistant that accurately extracts and structures information from web text."
            }
        ],
        "inferenceConfig": {
            "maxTokens": 1000,
            "temperature": 0.2,
            "topP": 0.9
        }
    }

    print("\n-> Sending reasoning request to Amazon Nova (amazon.nova-pro-v1:0)...")
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
            print("\n" + "="*20 + " NOVA'S EXTRACTED ANSWER " + "="*20)
            print(result_text)
            print("="*65 + "\n")
        else:
            print("Unexpected response structure:", response_body)

    except Exception as e:
        print("\nAWS Bedrock Error Details:")
        print(str(e))

if __name__ == "__main__":
    run_nova_act_devpost_search()
