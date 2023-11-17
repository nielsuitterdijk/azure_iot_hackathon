1. First goal is to set up all infrastructure, publish and receive messages.
2. Make improvements on the setup to reduce latency to below 30ms.
3. Add a device ID to the message, and filter in the node server
4. Add an analytics layer that calculates the mean of the payload for a burst of messages.

First attempt latency ±27ms
Adding avro protocol still at ±30ms
Reducing payload still at ±32ms
Increasing payload goes to ±22ms (10 fields)
Adding even more payload goes to ±17ms (31 fields)

# Setup

- Create IoT Hub
- Create consumer group (`app_service`)
- Update AppServer Connection string (IoT Hub)
- Update Publisher connection string (Device)

## Step 2 - Analytics

- Create Stream Analytics Job

# Optimization

Streaming Analytics Partition > not an option due to aggregation
Streaming Analytics SUs > not bottleneck
Event Hub throughput units > not bottleneck
