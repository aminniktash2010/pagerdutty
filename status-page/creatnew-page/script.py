import requests
import json
import os
import uuid

def create_pagerduty_status_page(api_key, name, business_service_ids, status='operational'):
    """
    Creates a new PagerDuty status page.

    Args:
      api_key (str): Your PagerDuty API key.
      name (str): The name of the status page.
      business_service_ids (list): A list of business service IDs associated with the status page.
      status (str): The initial status of the page (e.g., 'operational').

    Returns:
        dict or None: A JSON response if successful, None if an error occurs.
    """
    # Generate a unique subdomain from the name + UUID
    subdomain_base = "".join(x for x in name.lower() if x.isalnum())
    subdomain = f"{subdomain_base}-{uuid.uuid4().hex[:8]}"

    url = "https://api.pagerduty.com/status_pages"
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/vnd.pagerduty+json;version=2",
        "Authorization": f"Token token={api_key}",
    }
    data = {
        "status_page": {
            "name": name,
            "subdomain": subdomain,
            "business_service_ids": business_service_ids,
            "status": status
        }
    }

    try:
      response = requests.post(url, headers=headers, json=data)
      response.raise_for_status() # Raise HTTPError for bad responses (4xx or 5xx)
      return response.json()
    except requests.exceptions.RequestException as e:
      print(f"Error creating status page: {e}")
      if hasattr(e, 'response') and e.response is not None:
           print(f"Response status code: {e.response.status_code}")
           print(f"Response message: {e.response.text}")
      return None


if __name__ == '__main__':
    # Read configuration from environment variables
    api_key = os.environ.get('PAGERDUTY_API_KEY')
    status_page_name = os.environ.get('STATUS_PAGE_NAME')
    business_service_ids_str = os.environ.get('BUSINESS_SERVICE_IDS')
    business_service_ids = json.loads(business_service_ids_str) if business_service_ids_str else []
    

    if not api_key or not status_page_name:
        print("Error: Missing environment variables. Please ensure that PAGERDUTY_API_KEY and STATUS_PAGE_NAME are set.")
        exit(1)


    new_page = create_pagerduty_status_page(
        api_key,
        status_page_name,
        business_service_ids,
        )

    if new_page:
        print(f"Successfully created status page: {new_page}")
        print(f"Status Page Subdomain: {new_page['status_page']['subdomain']}")
    else:
        print("Status page creation failed.")
