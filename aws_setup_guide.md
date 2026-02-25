# AWS Configuration Guide for Nova Models

To get the Django backend communicating with the actual Amazon Nova models via Bedrock, you need to configure your AWS credentials. 

The `BedrockClient` we built uses `boto3`, which automatically looks for credentials in your environment. Currently, your terminal shows you are trying to use the AWS CLI, but the correct CLI command to configure it is `aws configure`.

Here is the step-by-step guide on what you need to do in the AWS Console and locally.

## 1. Request Access to Nova Models in AWS Bedrock
Amazon Nova models might require explicit model access in your AWS account.
1. Log into your **AWS Management Console**.
2. Search for and open **Amazon Bedrock**.
3. In the left navigation pane, scroll down and click on **Model access**.
4. Click the **Manage model access** button.
5. Check the boxes next to the Amazon Nova models (e.g., Nova Lite, Nova Pro, Nova Micro, etc.) that you want to use.
6. Scroll down and click **Save changes**. *Note: It may take a few minutes for access to be granted.*

## 2. Create an IAM User with Bedrock Permissions
You need an IAM user (or role) that has permission to invoke Bedrock models.
1. In the AWS Console, search for **IAM** (Identity and Access Management).
2. Go to **Users** and click **Create user**. Name it something like `nova-demo-backend`.
3. For Permissions, choose **Attach policies directly**.
4. Search for and select the `AmazonBedrockFullAccess` policy. *(For production, you would create a custom policy restricting it only to `bedrock:InvokeModel` for specific Nova ARNs).*
5. Click **Next**, then **Create user**.
6. Click on the newly created user, go to the **Security credentials** tab.
7. Scroll down to **Access keys** and click **Create access key**.
8. Select **Local code** or **Command Line Interface (CLI)** as the use case.
9. Copy your **Access key ID** and **Secret access key**. Keep these safe!

## 3. Configure Local Credentials
Now that you have your keys, you need to provide them to the Django application. There are two ways to do this:

### Option A: Using AWS CLI (Recommended)
You tried `aws login`, but the correct command for setting up static keys is:

```bash
aws configure
```

It will prompt you for:
- **AWS Access Key ID**: Paste the key you generated.
- **AWS Secret Access Key**: Paste the secret key.
- **Default region name**: e.g., `us-east-1` (Make sure this is a region where Nova models are available in Bedrock).
- **Default output format**: `json`

Once this is done, `boto3` in our Django app will automatically find these credentials in `~/.aws/credentials`.

### Option B: Using a `.env` file in Django
Because we set up `python-dotenv` in the Django project, you can also pass them directly to the environment.
1. Navigate to the `nova_backend/nova_backend/` folder on your computer.
2. Create a file named `.env`
3. Add the following lines:
   ```env
   AWS_ACCESS_KEY_ID=your_access_key_here
   AWS_SECRET_ACCESS_KEY=your_secret_key_here
   AWS_REGION=us-east-1
   ```

## 4. Updating the Django Bedrock Client
Currently, the `BedrockClient` in `nova_backend/api/bedrock_client.py` is configured to return simulated mock responses instead of actually calling `boto3.client.invoke_model()` because we were waiting for the AWS setup.

**Once you have completed steps 1-3**, let me know, and I can update the backend code to remove the mocks and perform actual `invoke_model` API calls to Amazon Bedrock!
