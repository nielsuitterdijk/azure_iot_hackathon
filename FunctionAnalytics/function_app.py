import datetime
import json
import logging

import azure.functions as func

app = func.FunctionApp()


class DataEntity:
    def __init__(self):
        self.data_points = []

    def add_data_point(self, time: datetime, value: float):
        self.data_points.append((time, value))

    def remove_stale_data(self):
        current_timestamp = datetime.datetime.utcnow()
        self.data_points = [
            (t, v)
            for t, v in self.data_points
            if (current_timestamp - t).total_seconds() <= 10
        ]

    def get_average(self):
        self.remove_stale_data()
        return (
            sum([v for _, v in self.data_points]) / len(self.data_points)
            if self.data_points
            else 0
        )


data_entity = None


@app.function_name(name="EventHubTrigger1")
@app.event_hub_message_trigger(
    arg_name="myhub", event_hub_name="cctest3", connection="iothubowner"
)
@app.event_hub_output(
    arg_name="event", event_hub_name="analytics_output", connection="iot_hub_output"
)
def test_function(myhub: func.EventHubEvent, event: func.Out[str]):
    global data_entity
    logging.info("Python EventHub trigger processed an event")
    data = json.loads(myhub.get_body().decode("utf-8"))
    logging.info(data)

    if data_entity is None:
        logging.info("Initializing data entity.")
        data_entity = DataEntity()
    data_entity.add_data_point(
        datetime.datetime.fromtimestamp(data["ts"]), data["payload"]
    )
    event.set(
        json.dumps(
            {
                "ts": data["ts"],
                "payload": data_entity.get_average(),
                "count": len(data_entity.data_points),
            }
        )
    )
