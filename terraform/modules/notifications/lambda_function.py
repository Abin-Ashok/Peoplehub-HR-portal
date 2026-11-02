import json
import os
import boto3

ses = boto3.client("ses", region_name=os.environ["AWS_REGION"])
SENDER_EMAIL = os.environ["SENDER_EMAIL"]


def lambda_handler(event, context):
    for record in event.get("Records", []):
        message = json.loads(record["body"])

        recipient = message["to"]
        subject = message["subject"]
        body = message["body"]

        ses.send_email(
            Source=SENDER_EMAIL,
            Destination={"ToAddresses": [recipient]},
            Message={
                "Subject": {"Data": subject},
                "Body": {"Text": {"Data": body}},
            },
        )

    return {"statusCode": 200}