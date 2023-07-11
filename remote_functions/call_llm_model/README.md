# call_llm_model

This is a remote function that proxy calls to the LLM model

## Getting started

### Prerequisites

- Python 3.11
- GCP project with enabled Cloud Functions API, Vertex AI API, Secret Manager API and Resource Manager API

### Installation

Create a virtual environment:

```bash
python -m venv venv
source venv/bin/activate
```

Install dependencies:

```bash
pip install -r src/requirements.txt
```

Run the function locally:

```
functions-framework --target=proces_calls --source=main.py --debug
```

### Testing

Make sample calls to the function using `curl` or use `test.http` file in VSCode with [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension.

Curl example for calling the function with OpenAI API:

```bash
curl -X POST http://localhost:8080 -H "Content-Type: application/json" -d '{
    "calls": [
        [
            "How are you?"
        ]
    ],
    "userDefinedContext": {
        "model": "gpt-4",
        "system_prompt": "You are friendly assistant"
    }
}'
```

Curl example for calling the function with Vertex AI:

```bash
curl -X POST \
  http://localhost:8080 \
  -H 'Content-Type: application/json' \
  -d '{
    "calls": [
        [
            "How are you?"
        ]
    ],
    "userDefinedContext": {
        "model": "vertexai-palm",
        "system_prompt": "You are friendly assistant"
    }
}'
```


## Deployment

Depending on which model provider you want to use, you need to deploy the function with different setup

### Setup for OpenAI API

> Open AI API require setting up a secret for storing API key

Create secret for storing `OPENAI_API_KEY`:

```bash
gcloud secrets create openai-api-key --replication-policy=automatic
```

Set value of the secret in Cloud Console or using the CLI:

```bash
echo -n "this is my super secret data" | gcloud secrets versions add openai-api-key --data-file=-
```

Grant access to a secret to the Cloud Functions service account:

```bash
gcloud secrets add-iam-policy-binding openai-api-key --member=serviceAccount:${GOOGLE_CLOUD_PROJECT}@appspot.gserviceaccount.com --role=roles/secretmanager.secretAccessor
```

Deploy to Cloud Functions:

> Vertex AI require no extra setup for deployment

```bash
gcloud functions deploy call_llm_model --entry-point proces_calls --runtime python311 --trigger-http --allow-unauthenticated --set-secrets="OPENAI_API_KEY=openai-api-key:latest"
```