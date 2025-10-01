FROM python:alpine

# Create app directory
WORKDIR /app

# Copy the Python script
COPY fleet-app.py /app/fleet-app.py

# Make script executable
RUN chmod +x /app/fleet-app.py

# Run the script with unbuffered output
CMD ["python", "-u", "/app/fleet-app.py"]
