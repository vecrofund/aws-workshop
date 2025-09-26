import json
import os
import base64

def _resp(status=200, body=None, headers=None):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json", **(headers or {})},
        "body": json.dumps(body if body is not None else {})
    }

def handlerone(event, context):
    # Demonstrate what we receive
    method = event.get("httpMethod")
    path = event.get("path")
    query = (event.get("queryStringParameters") or {})
    path_params = (event.get("pathParameters") or {})
    headers = (event.get("headers") or {})
    body_raw = event.get("body")
    if event.get("isBase64Encoded"):
        body_raw = base64.b64decode(body_raw or "").decode("utf-8")
    try:
        body_json = json.loads(body_raw) if body_raw else None
    except json.JSONDecodeError:
        body_json = None



    # Default: echo request for learning
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "message": "Hello from Lambda!",
            "method": method,
            "path": path,
            "query": query,
            "path_params": path_params,
            "headers": headers,
            "body_raw": body_raw,
            "body_parsed": body_json,
        })
    }