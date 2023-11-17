import asyncio
import json
import os
import random
import time
from datetime import datetime

from azure.iot.device.aio import IoTHubDeviceClient
from dotenv import load_dotenv

load_dotenv()


messages_per_second = 1  # Doing more than 10Hz is challenging without batching
total_duration_in_seconds = 3600


async def main():
    # Create instance of the device client using the authentication provider
    device_client = IoTHubDeviceClient.create_from_connection_string(
        os.getenv("DEVICE_CONNECTION_STRING")
    )
    payload_mean = random.random() * 100

    # Connect to the IoT Hub
    await device_client.connect()
    start_time = time.time()

    # Loop through total messages
    for i in range(int(messages_per_second * total_duration_in_seconds)):
        current_time = time.time()
        elapsed_time = current_time - start_time

        # Send message
        msg = json.dumps(
            {
                "ts": time.time(),
                "payload": payload_mean + random.random(),
            }
        )
        print("[%s] Send message" % datetime.now().strftime("%H:%M:%S"))
        await device_client.send_message(msg)

        # Sleep
        sleep_time = max((i + 1) / messages_per_second - elapsed_time, 0)
        await asyncio.sleep(sleep_time)

    # Finally, disconnect
    await device_client.disconnect()


asyncio.run(main())
