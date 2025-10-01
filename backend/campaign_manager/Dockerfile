FROM python:3-alpine

COPY requirements.txt requirements.txt

RUN pip install -r requirements.txt

EXPOSE 5000

COPY campaignManager.py campaignManager.py

CMD ["python", "./campaignManager.py"]
