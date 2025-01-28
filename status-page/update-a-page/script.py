import requests
import json
import os
from dotenv import load_dotenv

load_dotenv()

def get_pagerduty_status_page(status_page_id):
    """
    Fetches an existing PagerDuty status page.

    Args:
        status_page_id (str): The ID of the status page.

    Returns:
        dict: The status page data, or None if an error occurred.
    """

    api_token = os.environ.get("PAGERDUTY_API_TOKEN")
    if not api_token:
      raise Exception("PAGERDUTY_API_TOKEN environment variable is not set")

    headers = {
        "Authorization": f"Token token={api_token}",
        "Content-Type": "application/json",
        "Accept": "application/vnd.pagerduty+json;version=2",
    }

    url = f"https://api.pagerduty.com/status_pages/{status_page_id}"

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json().get("status_page")
    except requests.exceptions.RequestException as e:
        print(f"Error getting status page: {e}")
        print(f"Response body: {response.text}")
        return None

def get_pagerduty_business_services():
    """
    Fetches all PagerDuty business services.

    Returns:
        list: A list of business services, or None if an error occurred.
    """
    api_token = os.environ.get("PAGERDUTY_API_TOKEN")
    if not api_token:
      raise Exception("PAGERDUTY_API_TOKEN environment variable is not set")

    headers = {
        "Authorization": f"Token token={api_token}",
        "Content-Type": "application/json",
        "Accept": "application/vnd.pagerduty+json;version=2",
    }

    url = "https://api.pagerduty.com/business_services"
    all_services = []
    try:
        while True:
            response = requests.get(url, headers=headers)
            response.raise_for_status()
            data = response.json()
            all_services.extend(data.get("business_services", []))
            if not data.get("more"):
                break
            url = data.get("next_url")    
        return all_services
    except requests.exceptions.RequestException as e:
        print(f"Error getting business services: {e}")
        print(f"Response body: {response.text}")
        return None
    
def get_pagerduty_business_service(business_service_id):
    """
    Fetches a PagerDuty business service.
    Args:
        business_service_id (str): The ID of the business service.
    Returns:
        dict: The business service data, or None if an error occurred.
    """
    api_token = os.environ.get("PAGERDUTY_API_TOKEN")
    if not api_token:
      raise Exception("PAGERDUTY_API_TOKEN environment variable is not set")

    headers = {
        "Authorization": f"Token token={api_token}",
        "Content-Type": "application/json",
        "Accept": "application/vnd.pagerduty+json;version=2",
    }

    url = f"https://api.pagerduty.com/business_services/{business_service_id}"

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json().get("business_service")
    except requests.exceptions.RequestException as e:
        print(f"Error getting business service: {e}")
        print(f"Response body: {response.text}")
        return None

def update_pagerduty_status_page_group(status_page_id, group_id, new_services):
    """
    Updates a PagerDuty status page group.

    Args:
        status_page_id (str): The ID of the status page.
        group_id (str): The ID of the group to update.
        new_services (list): A list of business service IDs to include in the group.

    Returns:
        bool: True if the update was successful, False otherwise.
    """
    api_token = os.environ.get("PAGERDUTY_API_TOKEN")
    if not api_token:
      raise Exception("PAGERDUTY_API_TOKEN environment variable is not set")

    headers = {
        "Authorization": f"Token token={api_token}",
        "Content-Type": "application/json",
        "Accept": "application/vnd.pagerduty+json;version=2",
    }

    url = f"https://api.pagerduty.com/status_pages/{status_page_id}/status_page_groups/{group_id}"

    data = {
        "status_page_group": {
            "business_services": [{"id": service_id} for service_id in new_services]
        }
    }

    try:
        response = requests.put(url, headers=headers, data=json.dumps(data))
        response.raise_for_status()
        print(f"Successfully updated status page group: {group_id}")
        return True
    except requests.exceptions.RequestException as e:
        print(f"Error updating status page group: {e}")
        print(f"Response body: {response.text}")
        return False


def update_status_page(status_page_id, source_group_name, dest_group_name, business_service_name):
    """
    Moves a business service from one group to another on a PagerDuty status page.

    Args:
       status_page_id (str): The ID of the status page
        source_group_name (str): The name of the source group.
        dest_group_name (str): The name of the destination group.
        business_service_name (str): The name of the business service to move.
    """
    status_page = get_pagerduty_status_page(status_page_id)
    if not status_page:
        return

    business_services = get_pagerduty_business_services()
    if not business_services:
        return
    
    business_service = next((service for service in business_services if service["name"] == business_service_name), None)
    if not business_service:
        print(f"Business service not found: {business_service_name}")
        return

    status_page_groups = status_page.get("status_page_groups", [])
    source_group = next((group for group in status_page_groups if group["name"] == source_group_name), None)
    dest_group = next((group for group in status_page_groups if group["name"] == dest_group_name), None)

    if not source_group:
        print(f"Source group not found: {source_group_name}")
        return

    if not dest_group:
        print(f"Destination group not found: {dest_group_name}")
        return
    
    source_group_services = [service["id"] for service in source_group.get("business_services", [])]
    dest_group_services = [service["id"] for service in dest_group.get("business_services", [])]

    if business_service['id'] not in source_group_services:
        print(f"Business service {business_service_name} not found in source group {source_group_name}")
        return

    # Remove from source group
    updated_source_services = [service_id for service_id in source_group_services if service_id != business_service['id']]
    if not update_pagerduty_status_page_group(status_page_id, source_group["id"], updated_source_services):
        return

    # Add to dest group
    updated_dest_services = dest_group_services + [business_service["id"]]
    if not update_pagerduty_status_page_group(status_page_id, dest_group["id"], updated_dest_services):
        return

    print("Status page groups updated successfully!")


if __name__ == "__main__":
    status_page_id = os.environ.get("STATUS_PAGE_ID")
    source_group_name = os.environ.get("SOURCE_GROUP_NAME")
    dest_group_name = os.environ.get("DEST_GROUP_NAME")
    business_service_name = os.environ.get("BUSINESS_SERVICE_NAME")

    if not status_page_id or not source_group_name or not dest_group_name or not business_service_name:
        print("Please set STATUS_PAGE_ID, SOURCE_GROUP_NAME, DEST_GROUP_NAME, and BUSINESS_SERVICE_NAME environment variables.")
    else:
        update_status_page(status_page_id, source_group_name, dest_group_name, business_service_name)
