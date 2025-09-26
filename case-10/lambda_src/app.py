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
    print("Received event:", json.dumps(event, indent=2))

    # Default: echo request for learning
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Hello from Lambda!",
            "input": event
        })
    }