import asyncio
import json
import os
import time

from azure.iot.device.aio import IoTHubDeviceClient
from dotenv import load_dotenv

load_dotenv()


messages_per_second = 100
total_duration_in_seconds = 1


async def main():
    # Create instance of the device client using the authentication provider
    device_client = IoTHubDeviceClient.create_from_connection_string(
        os.getenv("CONNECTION_STRING")
    )

    # Connect to the IoT Hub
    await device_client.connect()
    start_time = time.time()

    # Loop through total messages
    for i in range(messages_per_second * total_duration_in_seconds):
        current_time = time.time()
        elapsed_time = current_time - start_time

        # Send message
        msg = json.dumps(
            {
                "ts": time.time(),
            }
        )
        await device_client.send_message(msg)

        # Sleep
        sleep_time = max((i + 1) / messages_per_second - elapsed_time, 0)
        await asyncio.sleep(sleep_time)

    # Finally, disconnect
    await device_client.disconnect()


asyncio.run(main())
