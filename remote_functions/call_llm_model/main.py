import logging
import os
import functions_framework
from flask import jsonify
import concurrent.futures
from tenacity import retry, stop_after_attempt, wait_fixed
import openai
from vertexai.preview.language_models import ChatModel

# Environment variables
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# Setup logging
logging.basicConfig(level=logging.INFO)


class LLMModel:
  def __init__(self):
    pass

  def call(self, user_prompt, system_prompt) -> str:
    raise NotImplementedError


class OpenAIGPT4Model(LLMModel):
  def __init__(self):
    super().__init__()

    openai.api_key = OPENAI_API_KEY

  @retry(stop=stop_after_attempt(3), wait=wait_fixed(10))
  def call(self, user_prompt, system_prompt) -> str:
    response = openai.ChatCompletion.create(
      model="gpt-4",
      messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt},
      ]
    )

    return response.choices[0].message.content


class GoogleVertexAIPaLMModel(LLMModel):
  def __init__(self):
    super().__init__()

  @retry(stop=stop_after_attempt(3), wait=wait_fixed(10))
  def call(self, user_prompt, system_prompt) -> str:
    """Call Google Vertex AI PaLM model"""
    chat_model = ChatModel.from_pretrained("chat-bison@001")

    parameters = {
      "temperature": 0.2,
      "max_output_tokens": 256,
    }

    chat = chat_model.start_chat(
      context=system_prompt,
    )

    response = chat.send_message(user_prompt, **parameters)
    
    return response.text


def get_llm_model(model):
  """Factory function to get LLM model"""
  if model == "openai-gpt-4":
    return OpenAIGPT4Model()
  elif model == "vertexai-palm":
    return GoogleVertexAIPaLMModel()
  else:
    raise ValueError("Model not supported")


@functions_framework.http
def proces_calls(request):
  """Responds to any HTTP request"""
  try:
    # Get request parameters
    request_json = request.get_json()
    calls = request_json.get('calls', [])

    user_defined_context = request_json.get('userDefinedContext', {})
    model = user_defined_context.get('model', "gpt-4")
    system_prompt = user_defined_context.get('system_prompt', "")

    # Setup LLM model
    llm_model = get_llm_model(model)

    # Process calls in parallel
    with concurrent.futures.ThreadPoolExecutor() as executor:
      future_to_reply = {executor.submit(llm_model.call, call[0], system_prompt): call for call in calls}
      replies = [future.result() for future in concurrent.futures.as_completed(future_to_reply)]

    return jsonify({"replies": replies})

  except Exception as e:
    logging.exception("An error occurred while processing the request. Error: %s", e, exc_info=True)
    return jsonify({"errorMessage": str(e)}), 400
