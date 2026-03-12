import subprocess
import time
from datetime import datetime

while True:
    try:
        result = subprocess.run(['vcgencmd', 'measure_volts', 'core'], capture_output=True, text=True)
        volt_core = result.stdout.strip()
        
        result2 = subprocess.run(['vcgencmd', 'measure_volts'], capture_output=True, text=True)
        volt_default = result2.stdout.strip()

        result3 = subprocess.run(['vcgencmd', 'measure_temp'], capture_output=True, text=True)
        temp = result3.stdout.strip()

        result4 = subprocess.run(['vcgencmd', 'get_throttled'], capture_output=True, text=True)
        throttled = result4.stdout.strip()

        ts = datetime.now().strftime('%H:%M:%S')
        print(f"[{ts}] core={volt_core} | default={volt_default} | {temp} | {throttled}")
    except Exception as e:
        print(f"Error: {e}")
    time.sleep(1)
