from flask import Flask
import logging


app = Flask(__name__)


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

console_handler = logging.StreamHandler()
console_handler.setLevel(logging.DEBUG)

formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
console_handler.setFormatter(formatter)

logger.addHandler(console_handler)


@app.route("/")
def home():
    logger.debug("Hello World!")
    return "Hello, World!"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)
