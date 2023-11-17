/* eslint-disable max-classes-per-file */
/* eslint-disable no-restricted-globals */
/* eslint-disable no-undef */
function debounce(func, timeout = 300) {
  let timer;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => {
      func.apply(this, args);
    }, timeout);
  };
}

$(document).ready(() => {
  // if deployed to a site supporting SSL, use wss://
  const protocol = document.location.protocol.startsWith("https")
    ? "wss://"
    : "ws://";
  const webSocket = new WebSocket(protocol + location.host);

  // When a web socket message arrives:
  webSocket.onopen = () => {
    console.log("WebSocket connected!");
    retryCount = 0; // reset the retry count on a successful connection
  };

  webSocket.onerror = (err) => {
    console.error("WebSocket Error:", err);
  };

  webSocket.onclose = (event) => {
    if (event.wasClean) {
      console.log(
        `Connection closed cleanly, code=${event.code}, reason=${event.reason}`
      );
    } else {
      console.error("Connection died");
      retryCount++;
      setTimeout(initializeWebSocket, 5000 * retryCount); // increasing delay
    }
  };
  webSocket.onmessage = function onMessage(message) {
    try {
      console.log("Updating");
      const messageData = JSON.parse(message.data);

      // time and either temperature or humidity are required
      if (!messageData.MessageDate || !messageData.IotData.ts) {
        return;
      }

      // Update live latency
      const latency = new Date() - messageData.IotData.ts * 1000;
      latencyData[0].value = latency;
      Plotly.react("liveLatency", latencyData, layout);

      // Update session latency
      countData[0].value = messageData.IotData.count;
      Plotly.react("liveCount", countData, layout);
    } catch (err) {
      console.error(err);
    }
  };

  // Gauge
  var latencyData = [
    {
      domain: { x: [0, 1], y: [0, 1] },
      value: 50,
      title: { text: "Latency [ms]" },
      type: "indicator",
      mode: "gauge+number",
      gauge: {
        axis: { range: [0, 500] },
      },
    },
  ];
  var countData = [
    {
      domain: { x: [0, 1], y: [0, 1] },
      value: 50,
      title: { text: "Count" },
      type: "indicator",
      mode: "gauge+number",
      gauge: {
        axis: { range: [0, 200] },
      },
    },
  ];
  const layout = { width: 600, height: 500, margin: { t: 0, b: 0 } };
  Plotly.newPlot("liveLatency", latencyData, layout);
  Plotly.newPlot("liveCount", countData, layout);
});
