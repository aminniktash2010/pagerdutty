import requests
import json
from datetime import datetime
import os

# Get API key from pipeline environment variable
API_KEY = os.environ.get('PAGERDUTY_API_KEY')

# Function to fetch PagerDuty configuration data
def fetch_pagerduty_data():
    headers = {
        'Authorization': f'Token token={API_KEY}',
        'Accept': 'application/vnd.pagerduty+json;version=2'
    }

    entities = ['services', 'schedules', 'users', 'escalation_policies']
    data = {}

    for entity in entities:
        response = requests.get(f'https://api.pagerduty.com/{entity}', headers=headers)
        if response.status_code == 200:
            data[entity] = response.json()[entity]
        else:
            print(f"Failed to fetch {entity}: {response.status_code} - {response.text}")
    
    return data
# Updated function to save data to a file with timestamp
def save_backup(data, filename_prefix='pagerduty_backup'):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{filename_prefix}_{timestamp}.json"
    with open(filename, 'w') as f:
        json.dump(data, f, indent=4)
    print(f"Backup saved to {filename}")

if __name__ == "__main__":
    data = fetch_pagerduty_data()
    save_backup(data)
