import os
import requests
from dotenv import load_dotenv

load_dotenv()

BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

_bot_username = None


def get_bot_username() -> str:
    global _bot_username
    if _bot_username is not None:
        return _bot_username
    _bot_username = ""
    if not BOT_TOKEN:
        return ""
    try:
        r = requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/getMe", timeout=5)
        data = r.json()
        if data.get("ok"):
            _bot_username = data["result"].get("username", "")
    except Exception:
        pass
    return _bot_username


def send_telegram(message: str) -> bool:
    if not BOT_TOKEN or not CHAT_ID:
        return False
    return send_telegram_to(CHAT_ID, message)


def send_telegram_to(chat_id: str, message: str) -> bool:
    if not BOT_TOKEN or not chat_id:
        return False
    try:
        r = requests.post(
            f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage",
            json={"chat_id": chat_id, "text": message, "parse_mode": "HTML"},
            timeout=5,
        )
        return r.status_code == 200
    except Exception:
        return False
