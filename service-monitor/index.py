import requests
import os
import base64
from slack_sdk import WebClient


def notify_slack(msg):
  slack_token = os.getenv('SLACK_API_TOKEN')
  if slack_token == None:
    print('SLACK_API_TOKEN environment variable is not set')
    exit(1)
  client = WebClient(token=slack_token)

  channel = os.getenv('SLACK_CHANNEL')
  if channel == None:
    print('SLACK_CHANNEL environment variable is not set')
    exit(1)
  client.chat_postMessage(channel=channel, text='Alert Manager is down! :fire:\n```' + msg + '```')


def check(path):
  timeout = os.getenv('CHECK_TIMEOUT') or '3'
  try:
    res = requests.get(path, timeout=float(timeout))
  except requests.exceptions.ConnectTimeout:
    return False, 'Connection timed out'
  if res.status_code == 200:
    if res.text != 'OK':
      return False, 'Response is not OK: ' + res.text
    return True, None
  else:
    return False, res.text


def handler(*_):
  path = os.getenv('HEALTH_CHECK_URL')
  if path == None:
    print('HEALTH_CHECK_URL environment variable is not set')
    exit(1)

  check_count = int(os.getenv('CHECK_COUNT') or '3')
  ok = False

  print('Checking health of service...')
  for _ in range(check_count):
    ok, msg = check(path)
    if ok:
      break

  if ok:
    print("Service is up and running")
  else:
    notify_slack(msg)
    print('Service is down. Alert sent to slack')
