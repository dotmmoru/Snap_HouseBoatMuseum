// @input Asset.RemoteServiceModule remoteServiceModule

// Import module
const Module = require("./HouseBoatMuseum API Module");
const ApiModule = new Module.ApiModule(script.remoteServiceModule);

var eventDone = false;

var MouthOpenedEvent = script.createEvent("MouthOpenedEvent");
MouthOpenedEvent.bind(function (eventData) {
    TriggerEvent()
});

var KissStartedEvent = script.createEvent("KissStartedEvent");
KissStartedEvent.bind(function (eventData) {
    TriggerEvent()
});

var SmileStartedEvent = script.createEvent("SmileStartedEvent");
SmileStartedEvent.bind(function (eventData) {
    TriggerEvent()
});

script.api.trigger = function(){
    TriggerEvent();
}

function TriggerEvent() {
    if (eventDone)
        return;
    eventDone = true;
    
    print('capture');

    delay_ResetEventDone.reset(1.0);

    // Example of calling an endpoint in ApiModule, replace with actual endpoint name
    ApiModule.event_triggered({
        // There might be required parameters
        parameters: {
            "parameter1": "12345"  // Replace with actual parameter names and values
        },
        // Body might be optional
        body: JSON.stringify({
            "additionalInfo": "Some info"  // Adjust based on the actual endpoint requirements
        })
    }).then((response) => {
        // Parse response as JSON string and log it
        print("Response metadata: " + JSON.stringify(response.metadata))
        print("Response body: " + response.bodyAsString());
    }).catch((error) => {
        print(error + "\n" + error.stack);
    });
}

var delay_ResetEventDone = script.createEvent("DelayedCallbackEvent");
delay_ResetEventDone.bind(function (eventData) {
    eventDone = false;
});