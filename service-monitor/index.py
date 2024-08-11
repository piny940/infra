import requests
import os
from slack_sdk import WebClient
import sys
import dotenv


def notify_slack():
  slack_token = os.getenv('SLACK_API_TOKEN')
  if slack_token == None:
    print('SLACK_API_TOKEN environment variable is not set')
    exit(1)
  client = WebClient(token=slack_token)

  channel = os.getenv('SLACK_CHANNEL')
  if channel == None:
    print('SLACK_CHANNEL environment variable is not set')
    exit(1)
  client.chat_postMessage(channel=channel, text='Alert Manager is down! :fire:')


if '--dev' in sys.argv:
  dotenv.load_dotenv(dotenv.find_dotenv('.env'))

path = os.getenv('HEALTH_CHECK_URL')
if path == None:
  print('HEALTH_CHECK_URL environment variable is not set')
  exit(1)
print('Checking health of service...')
res = requests.get(path)

if res.status_code == 200:
  print("Service is up and running")
else:
  notify_slack()
  print('Service is down. Alert sent to slack')
