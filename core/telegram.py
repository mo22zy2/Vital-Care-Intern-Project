import os
import logging
import html

import requests
from dotenv import load_dotenv

load_dotenv()

BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")


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


class TelegramLogHandler(logging.Handler):
    """Log handler that forwards records to the admin Telegram chat."""

    def emit(self, record):
        try:
            msg = self.format(record)
            if len(msg) > 3500:
                msg = msg[:3500] + "..."
            send_telegram(f"⚙️ <b>Log</b>\n{html.escape(msg)}")
        except Exception:
            pass
