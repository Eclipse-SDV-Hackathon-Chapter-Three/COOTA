#!/usr/bin/env python3
import os
import sys
import time
from datetime import datetime

def log_message(message):
    """Write message to all available channels"""
    # Print to stdout
    print(message, flush=True)
    
    # Write to stderr as well
    print(message, file=sys.stderr, flush=True)
    
    # Write to log file
    with open('/tmp/fleet-app.log', 'a') as f:
        f.write(f"{message}\n")
        f.flush()
    
    # Force flush all streams
    sys.stdout.flush()
    sys.stderr.flush()

def main():
    # Get VIN from environment variable first, then from file, then default
    vin = os.getenv('VIN')
    
    if not vin:
        try:
            with open('/tmp/vehicle-vin', 'r') as f:
                vin = f.read().strip()
        except:
            vin = 'UNKNOWN_VIN'
    
    log_message(f"Fleet App Starting - VIN: {vin}")
    log_message("=" * 50)
    
    while True:
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_message(f"[{current_time}] Vehicle {vin} is running")
        time.sleep(5)

if __name__ == "__main__":
    main()
