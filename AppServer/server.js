const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const path = require("path");
const EventHubReader = require("./scripts/event-hub-reader.js");

// const iotHubConnectionString =
//   "HostName=cctest2.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=4EXuafxACqTvg0YPb5VadJw3Wsmh2fPRyAIoTPsKsqU=";
// const eventHubConsumerGroup = "app_service";

const iotHubConnectionString =
  "Endpoint=sb://eventhubnamespacepoiu12.servicebus.windows.net/;SharedAccessKeyName=web-hook;SharedAccessKey=qfrz6ziyBGH8o4WGjMPQvAYlSrMPB+nYy+AEhGS+sWg=;EntityPath=eventhubpoiu12";
const eventHubConsumerGroup = "$Default";

// Redirect requests to the public subdirectory to the root
const app = express();
app.use(express.static(path.join(__dirname, "public")));
app.use((req, res /* , next */) => {
  res.redirect("/");
});

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

wss.on("connection", (ws) => {
  console.log("Client connected");
  ws.on("message", (message) => {
    console.log(`Received message: ${message}`);
  });
  ws.on("close", () => {
    console.log("Client disconnected");
  });
});
wss.broadcast = (data) => {
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      try {
        console.log(`Broadcasting data ${data}`);
        client.send(data);
      } catch (e) {
        console.error(e);
      }
    }
  });
};

server.listen(process.env.PORT || "3000", () => {
  console.log("Listening on %d.", server.address().port);
});

const eventHubReader = new EventHubReader(
  iotHubConnectionString,
  eventHubConsumerGroup
);

(async () => {
  await eventHubReader.startReadMessage((message, date, deviceId) => {
    try {
      const payload = {
        IotData: message,
        MessageDate: date || Date.now().toISOString(),
        DeviceId: deviceId,
      };

      wss.broadcast(JSON.stringify(payload));
    } catch (err) {
      console.error("Error broadcasting: [%s] from [%s].", err, message);
    }
  });
})().catch();
