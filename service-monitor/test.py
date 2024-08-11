import dotenv
from index import handler

dotenv.load_dotenv(dotenv.find_dotenv('.env'))
handler()
