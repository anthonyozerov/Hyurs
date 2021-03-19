from __future__ import print_function
import datetime
import pickle
import os.path
import argparse
import hy
import data
import ask_mapping
import download
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from dateutil.parser import parse as dateparse

# If modifying these scopes, delete the file token.pickle.
SCOPES = ['https://www.googleapis.com/auth/calendar.readonly']

if __name__ == '__main__':
    argp = argparse.ArgumentParser(description="Link wth Google Calendar and download events")
    argp.add_argument('-c', '--calendars', nargs="*")
    argp.add_argument('-t', '--starttime', default="2021-01-01T00:00")
    argp.add_argument('-n', '--items', default=1024)
    argp.add_argument('-i', '--ics',action='store_const',const=1,default=0)

    args = argp.parse_args()

    calendar_names = args.calendars
    start_time = dateparse(args.starttime)
    n = int(args.items)

    if len(calendar_names) == 0:
        print("WARNING: No calendars specified")

    if args.ics:
        event_objs=download.events_from_ics(calendar_names, start_time, n)
    else:
        event_objs = download.events_from_calendars(calendar_names, start_time, n)
    data.save_json("data/imported.json", event_objs)

    if not os.path.isfile("data/mapping.json"):
        data.save_json("data/mapping.json", {})

    data.save_json("data/state.json",
                  {'time_updated': datetime.datetime.utcnow().isoformat() + 'Z',
                   'calendars': calendar_names})

    if input('Press enter to define the event name -> tag mapping now, anything else to quit') == '':
        ask_mapping.ask()

    print("All unknown event names are now associated with tags, exiting.")
