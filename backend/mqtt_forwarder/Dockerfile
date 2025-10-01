FROM python:3-alpine

COPY requirements.txt requirements.txt

RUN pip install -r requirements.txt

COPY forwarder.py forwarder.py

CMD ["python", "./forwarder.py"]
