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

    This could be used by any kind of source object transformation to one of the Observe' supported formats (Parquet, JSON, CSV, or TEXT)
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

    # Safety check: Skip if file is already in the observe/ prefix (prevent recursion)
    if key.startswith(f"{OUTPUT_PREFIX}/"):
        print(f"Skipping file already in {OUTPUT_PREFIX}/ prefix: s3://{bucket}/{key}")
        return

    try:
        print(f"Processing s3://{bucket}/{key}")

        # Download file
        response = s3_client.get_object(Bucket=bucket, Key=key)
        content_type = response.get("ContentType", "")
        file_content = response["Body"].read()

        output_bucket = OUTPUT_BUCKET or bucket

        # Transform content if XML, otherwise keep as-is
        decoded_content = file_content.decode("utf-8")
        if is_xml_content(decoded_content, content_type):
            # Convert XML to JSON
            json_data = xmltodict.parse(decoded_content)
            output_content = json.dumps(json_data, indent=2)
            output_key = build_output_key(key, preserve_extension=False)
            output_content_type = "application/json"
            print(f"Transforming XML to JSON")
        else:
            # Keep file as-is
            output_content = file_content
            output_key = build_output_key(key, preserve_extension=True)
            output_content_type = content_type or "application/octet-stream"
            print(f"Non-XML file (content-type: {content_type}), copying as-is")

        # Upload to S3
        s3_client.put_object(
            Bucket=output_bucket,
            Key=output_key,
            Body=output_content,
            ContentType=output_content_type,
        )

        print(f"Uploaded to s3://{output_bucket}/{output_key}")

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


def build_output_key(input_key: str, preserve_extension: bool = False) -> str:
    """Build output S3 key with configured prefix."""
    # Preserve directory structure from input key
    path_parts = input_key.split("/")
    filename = path_parts[-1]
    subdirs = "/".join(path_parts[:-1]) if len(path_parts) > 1 else ""

    # Handle extension
    if not preserve_extension and not filename.endswith(".json"):
        filename = filename.rsplit(".", 1)[0] + ".json"

    # Build output key with prefix and subdirectories
    if OUTPUT_PREFIX:
        if subdirs:
            return f"{OUTPUT_PREFIX}/{subdirs}/{filename}"
        return f"{OUTPUT_PREFIX}/{filename}"

    return (
        input_key
        if preserve_extension
        else f"{subdirs}/{filename}" if subdirs else filename
    )


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
