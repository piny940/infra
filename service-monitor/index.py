import requests
import os
from slack_sdk import WebClient


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


def check(path):
  res = requests.get(path)
  if res.status_code == 200:
    return True
  else:
    return False


def handler(*_):
  path = os.getenv('HEALTH_CHECK_URL')
  if path == None:
    print('HEALTH_CHECK_URL environment variable is not set')
    exit(1)

  check_count = int(os.getenv('CHECK_COUNT') or '3')
  ok = False

  print('Checking health of service...')
  for _ in range(check_count):
    ok = check(path)
    if ok:
      break

  if ok:
    print("Service is up and running")
  else:
    notify_slack()
    print('Service is down. Alert sent to slack')
