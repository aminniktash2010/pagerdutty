import requests
import json
from datetime import datetime
import os

API_KEY = "your  key"
BASE_URL = 'https://api.pagerduty.com'

headers = {
    'Authorization': f'Token token={API_KEY}',
    'Accept': 'application/vnd.pagerduty+json;version=2'
}

def get_available_entities():
    return [
        'services',
        'schedules',
        'users',
        'escalation_policies',
        'teams',
        'incidents',
        'business_services',
        'priorities',
        'response_plays',
        'addons',
        'vendors',
        'extensions',
        'maintenance_windows',
        'dependencies',
        'event_orchestrations',
        'service_event_rules'
    ]

def fetch_pagerduty_data():
    data = {}
    available_entities = get_available_entities()
    
    for entity in available_entities:
        print(f"Fetching {entity}...")
        if entity == 'dependencies':
            business_services_response = requests.get(f'{BASE_URL}/business_services', headers=headers)
            if business_services_response.status_code == 200:
                business_services = business_services_response.json().get('business_services', [])
                dependencies = []
                for bs in business_services:
                    dep_response = requests.get(f'{BASE_URL}/service_dependencies/business_services/{bs["id"]}', headers=headers)
                    if dep_response.status_code == 200:
                        dependencies.append(dep_response.json())
                data['dependencies'] = dependencies
            else:
                print(f"Failed to fetch business services: {business_services_response.status_code} - {business_services_response.text}")
        elif entity == 'event_orchestrations':
            orchestrations_list_response = requests.get(f'{BASE_URL}/event_orchestrations', headers=headers)
            if orchestrations_list_response.status_code == 200:
                orchestrations_list = orchestrations_list_response.json().get('orchestrations', [])
                orchestrations = []
                for orch in orchestrations_list:
                    orch_response = requests.get(f'{BASE_URL}/event_orchestrations/{orch["id"]}', headers=headers)
                    if orch_response.status_code == 200:
                        orchestrations.append(orch_response.json())
                data['event_orchestrations'] = orchestrations
            else:
                print(f"Failed to fetch event orchestrations list: {orchestrations_list_response.status_code} - {orchestrations_list_response.text}")
        elif entity == 'service_event_rules':
            services_response = requests.get(f'{BASE_URL}/services', headers=headers)
            if services_response.status_code == 200:
                services = services_response.json().get('services', [])
                service_event_rules = []
                for service in services:
                    rules_response = requests.get(f'{BASE_URL}/services/{service["id"]}/event_rules', headers=headers)
                    if rules_response.status_code == 200:
                        service_event_rules.extend(rules_response.json().get('event_rules', []))
                data['service_event_rules'] = service_event_rules
            else:
                print(f"Failed to fetch services: {services_response.status_code} - {services_response.text}")
        else:
            response = requests.get(f'{BASE_URL}/{entity}', headers=headers)
            if response.status_code == 200:
                entity_data = response.json()
                if entity in entity_data:
                    data[entity] = entity_data[entity]
                else:
                    print(f"Warning: '{entity}' key not found in response for {entity}")
            else:
                print(f"Failed to fetch {entity}: {response.status_code} - {response.text}")
    
    return data

if __name__ == "__main__":
    data = fetch_pagerduty_data()
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"pagerduty_backup_{timestamp}.json"
    
    full_path = os.path.abspath(filename)
    print(f"Backup file path: {full_path}")
    print(f"##vso[task.setvariable variable=BackupFilePath;]{full_path}")
    with open(filename, 'w') as f:
        json.dump(data, f, indent=2)
    print(f"Backup saved to {filename}")
