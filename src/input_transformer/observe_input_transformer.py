import json
import boto3
import xmltodict
from urllib.parse import unquote_plus
import os

s3_client = boto3.client("s3")

# Configuration via environment variables
OUTPUT_PREFIX = os.environ.get("OUTPUT_PREFIX", "observe")
OUTPUT_BUCKET = os.environ.get("OUTPUT_BUCKET")  # If None, uses source bucket
DELETE_SOURCE = (
    os.environ.get("DELETE_SOURCE_AFTER_TRANSFORM", "false").lower() == "true"
)


def lambda_handler(event, context):
    """
    Transform XML files from S3 to JSON for Observe ingestion.
    Uses xmltodict for automatic XML->JSON conversion.

    This function is designed to be triggered exclusively by EventBridge events
    from S3 object creation. It extracts bucket and key information from the
    EventBridge event detail and processes the file accordingly.
    """
    # EventBridge format - extract S3 details from detail section
    detail = event.get("detail", {})
    bucket_name = detail.get("bucket", {}).get("name")
    object_key = detail.get("object", {}).get("key")

    if not bucket_name or not object_key:
        print("Missing bucket or object key in EventBridge event")
        return

    bucket = bucket_name
    key = unquote_plus(object_key)

    try:
        print(f"Processing s3://{bucket}/{key}")

        # Download file and check if it's XML content
        response = s3_client.get_object(Bucket=bucket, Key=key)
        content_type = response.get("ContentType", "")

        # Read content
        file_content = response["Body"].read().decode("utf-8")

        # Check if content is XML-like (either by content-type or by content inspection)
        if not is_xml_content(file_content, content_type):
            print(
                f"Skipping non-XML file: s3://{bucket}/{key} (content-type: {content_type})"
            )
            return

        # Convert XML to JSON
        json_data = xmltodict.parse(file_content)

        # Upload transformed file
        output_bucket = OUTPUT_BUCKET or bucket
        output_key = build_output_key(key)

        s3_client.put_object(
            Bucket=output_bucket,
            Key=output_key,
            Body=json.dumps(json_data, indent=2),
            ContentType="application/json",
        )

        print(f"✓ Transformed to s3://{output_bucket}/{output_key}")

        # Optionally delete source
        if DELETE_SOURCE:
            s3_client.delete_object(Bucket=bucket, Key=key)
            print(f"✓ Deleted source file")

    except Exception as e:
        print(f"✗ Error processing {bucket}/{key}: {str(e)}")
        # Don't raise - just log and continue


def is_xml_content(content: str, content_type: str = "") -> bool:
    """
    Check if content appears to be XML.
    Checks both content-type header and content inspection.
    """
    # Check content-type first
    if content_type and (
        "xml" in content_type.lower() or "text/xml" in content_type.lower()
    ):
        return True

    # Inspect content - look for XML declaration or root elements
    content_stripped = content.strip()

    # Check for XML declaration
    if content_stripped.startswith("<?xml"):
        return True

    return False


def build_output_key(input_key: str) -> str:
    """Build output S3 key with configured prefix."""
    filename = input_key.split("/")[-1]

    # Ensure .json extension
    if not filename.endswith(".json"):
        filename = filename.rsplit(".", 1)[0] + ".json"

    return f"{OUTPUT_PREFIX}/{filename}" if OUTPUT_PREFIX else filename


# For local testing
if __name__ == "__main__":
    test_xml = """<?xml version="1.0" encoding="UTF-8"?>
    <mtMessageResponse messageId="2fe6d7da-9772-4c53-95a6-53f9220f562c" receiptDate="2025-03-03T09:24:47.008-06:00">
        <type>Handset</type>
        <status isError="false">
            <description>MtMessage successfully delivered to the Handset</description>
        </status>
    </mtMessageResponse>"""

    result = xmltodict.parse(test_xml)
    print(json.dumps(result, indent=2))
