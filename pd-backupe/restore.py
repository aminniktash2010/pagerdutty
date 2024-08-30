import requests
import json
import os
import sys

# Get API key from environment variable
API_KEY = os.environ.get('PAGERDUTY_API_KEY')

# Function to restore PagerDuty configuration data
def restore_pagerduty_data(filename):
    headers = {
        'Authorization': f'Token token={API_KEY}',
        'Accept': 'application/vnd.pagerduty+json;version=2',
        'Content-Type': 'application/json'
    }

    with open(filename, 'r') as f:
        data = json.load(f)

    entities = ['services', 'schedules', 'users', 'escalation_policies']

    for entity in entities:
        if entity in data:
            for item in data[entity]:
                response = requests.post(f'https://api.pagerduty.com/{entity}', headers=headers, json=item)
                if response.status_code == 201:
                    print(f"Successfully restored {entity} item: {item.get('name', item.get('id'))}")
                else:
                    print(f"Failed to restore {entity} item: {item.get('name', item.get('id'))} - {response.status_code} - {response.text}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        restore_file = sys.argv[1]
        restore_pagerduty_data(restore_file)
    else:
        print("Error: No restore file specified.")
        sys.exit(1)
