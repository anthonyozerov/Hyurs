from __future__ import print_function
import datetime
import pickle
import os.path
import argparse
import hy
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from dateutil.parser import parse as dateparse

# If modifying these scopes, delete the file token.pickle.
SCOPES = ['https://www.googleapis.com/auth/calendar.readonly']


def events_from_calendars(calendar_names, start_time, n):
    # Much of this function is taken directly from Google Calendar quickstart documentation 
    creds = None
    # The file token.pickle stores the user's access and refresh tokens, and is
    # created automatically when the authorization flow completes for the first
    # time.
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        # Save the credentials for the next run
        with open('token.pickle', 'wb') as token:
            pickle.dump(creds, token)

    service = build('calendar', 'v3', credentials=creds)

    event_objs = []

    # Call the Calendar API
    print('Getting calendars ...')
    all_calendars = service.calendarList().list().execute()["items"]
    start_time_formatted = start_time.isoformat() + 'Z'
    print(start_time_formatted)
    for name in calendar_names:
        calendar_id = None
        for cal in all_calendars:
                if cal["summary"] == name:
                    calendar_id = cal["id"]
        print(f'Getting events for calendar with name {name} and id {calendar_id}...')
        events_result = service.events().list(calendarId=calendar_id,
                                              timeMin=start_time_formatted,
                                              maxResults=n,
                                              singleEvents=True,
                                              orderBy='startTime').execute()
        events = events_result.get('items', [])

        for event in events:
            start = event['start'].get('dateTime', event['start'].get('date'))
            end = event['end'].get('dateTime', event['end'].get('date'))
            print(start, event['summary'])
            event_objs.append({'start': start,
                               'end': end,
                               'summary': event['summary'],
                               'calendar_name': name,
                               'fullname': name + '/' + event['summary']})

    return event_objs
