import json
import os
import requests
from datetime import datetime, timedelta

def get_service_id(api_key, service_name):
    services = fetch_services(api_key)
    for service in services:
        if service.get("name") == service_name:
            return service.get("id")
    return None

def fetch_services(api_key):
    base_url = "https://api.pagerduty.com/services"
    headers = {
        "Authorization": f"Token token={api_key}",
        "Content-Type": "application/json",
    }

    try:
        response = requests.get(base_url, headers=headers)
        response.raise_for_status()
        response_data = response.json()
        return response_data.get("services", [])
    except Exception as e:
        print(f"Error fetching service data: {e}")
        return []

def list_services(api_key):
    services = fetch_services(api_key)
    if not services:
        print("No services found.")
    else:
        print("Available services:")
        for service in services:
            print(f"Name: {service.get('name')}, ID: {service.get('id')}")

def get_next_weekday(weekday):
    today = datetime.now()
    days_ahead = weekday - today.weekday()
    if days_ahead <= 0:
        days_ahead += 7
    return today + timedelta(days=days_ahead)

def create_maintenance(api_key, requester, service_name, description, start_time, duration_hours, recurring, weekday=None):
    service_id = get_service_id(api_key, service_name)
    if not service_id:
        print(f"Service '{service_name}' not found.")
        list_services(api_key)
        return

    if recurring:
        maintenance_start = get_next_weekday(weekday)
    else:
        maintenance_start = datetime.now()

    maintenance_start = maintenance_start.replace(hour=start_time.hour, minute=start_time.minute, second=0, microsecond=0)
    end_time = maintenance_start + timedelta(hours=duration_hours)

    maintenance_payload = {
        "maintenance_window": {
            "type": "maintenance_window",
            "start_time": maintenance_start.isoformat(),
            "end_time": end_time.isoformat(),
            "description": description,
            "service_ids": [service_id]
        }
    }

    base_url = "https://api.pagerduty.com/maintenance_windows"
    headers = {
        "Authorization": f"Token token={api_key}",
        "Content-Type": "application/json",
        "From": requester
    }

    try:
        response = requests.post(base_url, headers=headers, data=json.dumps(maintenance_payload))
        response.raise_for_status()
        print("Maintenance window created successfully.")
    except Exception as e:
        print(f"Error creating maintenance window: {e}")

def main():
    # Read parameters from input.json file
    with open('input.json') as f:
        parameters = json.load(f)

    pagerDutyApiKey = parameters["pagerDutyApiKey"]
    requester_email = parameters["requesterEmail"]
    service_name = parameters["serviceName"]
    maintenance_description = parameters.get("maintenanceDescription", "Scheduled maintenance")
    weekday = parameters.get("weekday", 0)
    start_time = parameters.get("startTime", "14:00")
    duration_hours = parameters.get("durationHours", 2)
    maintenance_type = parameters.get("maintenanceType", "one-time")

    try:
        start_time = datetime.strptime(start_time, "%H:%M")
    except ValueError:
        print("Invalid start time format. Please use HH:MM format.")
        return

    recurring = maintenance_type == 'recurring'

    create_maintenance(pagerDutyApiKey, requester_email, service_name, maintenance_description, start_time, duration_hours, recurring, weekday if recurring else None)

if __name__ == "__main__":
    main()
