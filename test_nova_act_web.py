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

# Load AWS credentials
load_dotenv(os.path.join(os.path.dirname(__file__), 'nova_backend', '.env'))

def initialize_browser():
    """Sets up a headless Chrome browser for the Nova agent to control."""
    print("[Browser] Initializing headless Chrome...")
    chrome_options = Options()
    chrome_options.add_argument("--headless=new")
    chrome_options.add_argument("--window-size=1280,800")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=chrome_options)
    return driver

def ask_nova_for_action(client, current_url, page_text, objective):
    """Asks Amazon Nova Pro what the next action should be on the webpage."""
    
    prompt = f"""
You are an AI Web Browsing Agent named Nova Act.
Your objective is: "{objective}"

Current URL: {current_url}
Visible Page Text (Truncated): 
{page_text[:1500]}

Based on your objective and the page content, what should be your next interaction?
Respond ONLY with a valid JSON object in the following format:
{{
    "thought": "your reasoning here",
    "action": "click|type|navigate|done",
    "target": "link text or button text to click, OR text to type, OR URL to navigate to"
}}
"""
    
    payload = {
        "messages": [{"role": "user", "content": [{"text": prompt}]}],
        "inferenceConfig": {"maxTokens": 500, "temperature": 0.1}
    }

    try:
        response = client.invoke_model(
            modelId="amazon.nova-pro-v1:0",
            body=json.dumps(payload),
            accept="application/json",
            contentType="application/json"
        )
        response_body = json.loads(response.get('body').read())
        content = response_body["output"]["message"]["content"][0]["text"]
        
        # Strip markdown formatting if Nova adds it
        if content.startswith("```json"):
            content = content.replace("```json", "").replace("```", "").strip()
            
        return json.loads(content)
    except Exception as e:
        print(f"[Nova Error] Failed to generate action: {e}")
        return {"action": "done", "thought": "Error occurred, halting."}

def run_nova_act_web_agent():
    print("=== Amazon Nova Act: Web Execution Agent ===")
    
    try:
        bedrock_client = boto3.client('bedrock-runtime', region_name=os.getenv('AWS_REGION', 'us-east-1'))
    except Exception as e:
        print(f"Failed to initialize AWS Bedrock: {e}")
        return

    driver = initialize_browser()
    
    # Let's test Nova Act on Wikipedia
    start_url = "https://en.wikipedia.org/wiki/Amazon_(company)"
    objective = "Find out when Amazon was founded by reading the page."
    
    print(f"\n[Agent] Objective: {objective}")
    print(f"[Agent] Navigating to starting point: {start_url}")
    driver.get(start_url)
    
    steps = 0
    max_steps = 3 # Keep it small for the test
    
    while steps < max_steps:
        time.sleep(2) # Wait for page load
        current_url = driver.current_url
        page_text = driver.find_element(By.TAG_NAME, "body").text
        
        print(f"\n--- Step {steps + 1} ---")
        print("[Nova] Analyzing current page state...")
        
        action_plan = ask_nova_for_action(bedrock_client, current_url, page_text, objective)
        
        print(f"[Nova Thought]: {action_plan.get('thought', 'No thought')}")
        action = action_plan.get('action')
        target = action_plan.get('target', '')
        
        if action == 'navigate':
            print(f"[Action] Navigating to {target}")
            driver.get(target)
            
        elif action == 'click':
            print(f"[Action] Clicking on '{target}'")
            try:
                elem = driver.find_element(By.PARTIAL_LINK_TEXT, target)
                elem.click()
            except:
                print(f"[Warning] Could not find clickable element for '{target}'")
                
        elif action == 'done':
            print(f"[Action] Nova recognized objective is complete!")
            break
            
        else:
            print(f"[Warning] Unknown action: {action}")
            break
            
        steps += 1
        
    print("\n[Agent] Taking final screenshot preview of what Nova saw...")
    screenshot_path = os.path.join(os.path.dirname(__file__), "nova_act_preview.png")
    driver.save_screenshot(screenshot_path)
    print(f"[Agent] Saved visual preview to: {screenshot_path}")
    
    driver.quit()
    print("=== Execution Complete ===")

if __name__ == "__main__":
    run_nova_act_web_agent()
