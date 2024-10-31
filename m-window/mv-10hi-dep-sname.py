#!/usr/bin/env python
###############################
#Example:
#python3 your script file.py \
#--api-key your PD key \
#--requester ami@your email.com \
#--service <Your service name> \
#--date 2024-11-02T04:00:00-0700 \
#--description "Scheduled weekly maintenance" \
#--duration 200 \#<Minutes>
#--period 168 \
#--number 1


##############################
# Python script to create recurring maintenance windows in PagerDuty with recursive dependency fetching

import argparse
import pdpyras
import sys
import json
from dateutil import parser as dateparser
from datetime import datetime, timedelta

def get_service_id_by_name(session, service_name):
    try:
        response = session.get('services', params={'query': service_name})
        services = response.json().get('services', [])
        for service in services:
            if service['name'].lower() == service_name.lower():
                return service['id']
        print(f"Warning: Service '{service_name}' not found.")
        return None
    except pdpyras.PDClientError as e:
        print(f"Error fetching service ID for '{service_name}': {e}")
        return None

def get_service_dependencies(session, service_ids, depth=0, max_depth=10, visited=None):
    if visited is None:
        visited = set()
    
    all_service_ids = set(service_ids)
    new_dependencies = set()

    for service_id in service_ids:
        if service_id in visited:
            continue
        visited.add(service_id)

        try:
            response = session.get(f'service_dependencies/technical_services/{service_id}')
            print(f"Raw API response for service {service_id}: {response.text}")
            
            if response.status_code == 404:
                print(f"Warning: Service {service_id} not found or no permissions to access its dependencies.")
                continue

            dependencies = response.json()
            if isinstance(dependencies, dict):
                for dep in dependencies.get('relationships', []):
                    dependent_service_id = dep.get('dependent_service', {}).get('id')
                    if dependent_service_id and dependent_service_id not in all_service_ids:
                        all_service_ids.add(dependent_service_id)
                        new_dependencies.add(dependent_service_id)
                        print(f"Added dependency: {dependent_service_id} for service {service_id} at depth {depth}")
            else:
                print(f"Unexpected response format for service {service_id}: {dependencies}")
        except pdpyras.PDClientError as e:
            print(f"Error fetching dependencies for service {service_id}: {e}")
        except json.JSONDecodeError as e:
            print(f"Error decoding JSON for service {service_id}: {e}")
            print(f"Raw response: {response.text}")
        except Exception as e:
            print(f"Unexpected error for service {service_id}: {e}")
    
    if new_dependencies and depth < max_depth:
        all_service_ids.update(get_service_dependencies(session, new_dependencies, depth + 1, max_depth, visited))
    
    return list(all_service_ids)

def create_recurring_maintenance_windows(args):
    sref = lambda s: {'type': 'service_reference', 'id':s}
    session = pdpyras.APISession(args.api_key, default_from=args.requester)

    # Map service names to IDs
    service_ids = []
    for service_name in args.services:
        service_id = get_service_id_by_name(session, service_name)
        if service_id:
            service_ids.append(service_id)
        else:
            print(f"Skipping service '{service_name}' as it could not be found.")

    if not service_ids:
        print("No valid services found. Exiting.")
        return

    # Get all service IDs including dependencies
    all_service_ids = get_service_dependencies(session, service_ids, max_depth=args.max_depth)
    print(f"Services to be included in maintenance window (including all dependencies): {all_service_ids}")

    start_date = dateparser.parse(args.first_maint_window_date)
    end_date = start_date + timedelta(minutes=args.duration_minutes)

    for iter in range(args.num_repetitions):
        print(f"Creating a {args.duration_minutes}-minute maintenance window starting {start_date}.")
        if not args.dry_run:
            try:
                mw = session.rpost('maintenance_windows', json={
                    'type': 'maintenance_window',
                    'start_time': start_date.isoformat(),
                    'end_time': end_date.isoformat(),
                    'description': args.description,
                    'services': [sref(s_id) for s_id in all_service_ids]
                })
                print(f"Maintenance window created successfully. ID: {mw['id']}")
            except pdpyras.PDClientError as e:
                msg = "API Error: "
                if e.response is not None:
                    msg += f"HTTP {e.response.status_code}: {e.response.text}"
                print(msg)
        start_date = start_date + timedelta(hours=args.period_hours)
        end_date = end_date + timedelta(hours=args.period_hours)
    if args.dry_run:
        print("(Note: no maintenance windows actually created because -n/--dry-run was given)")

def main():
    desc = "Create a series of recurring maintenance windows including service dependencies."
    ap = argparse.ArgumentParser(description=desc)

    ap.add_argument('-k', '--api-key', required=True, help="A REST API key")

    helptxt = "User login email address of the PagerDuty user to record as the agent who created the maintenance window."
    ap.add_argument('-r', '--requester', required=True, help=helptxt)

    helptxt = "Service name(s) for which to create the maintenance windows. Note, this may be given multiple times to specify more than one service."
    ap.add_argument('-s', '--service', dest='services', action='append', required=True, help=helptxt)

    helptxt = "Date of the first maintenance window in the series. It must be formatted as valid ISO8601, i.e. 2025-10-19T17:45:00-0700"
    ap.add_argument('-t', '--date', required=True, dest='first_maint_window_date', help=helptxt)

    helptxt = "Description of the maintenance window to create."
    ap.add_argument('-d', '--description', required=True, help=helptxt)

    helptxt = "Duration of the maintenance window in minutes"
    ap.add_argument('-l', '--duration', required=True, dest='duration_minutes', type=int, help=helptxt)

    helptxt = "Number of hours between the start of each successive maintenance window"
    ap.add_argument('-p', '--period', required=True, dest='period_hours', type=int, help=helptxt)

    helptxt = "Total number of maintenance windows to create"
    ap.add_argument('-m', '--number', default=1, dest='num_repetitions', type=int, help=helptxt)

    helptxt = "Maximum depth for fetching service dependencies"
    ap.add_argument('--max-depth', default=10, type=int, help=helptxt)

    ap.add_argument('-n', '--dry-run', default=False, action='store_true',
        help="Don't perform any action; instead, show the maintenance windows that would be created.")

    args = ap.parse_args()

    create_recurring_maintenance_windows(args)

if __name__ == '__main__':
    main()
