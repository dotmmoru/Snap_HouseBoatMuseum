// CountdownController.js
// Version: 1.0.0
// Event: On Awake
// Description: 3..2..1 countdown that triggers a custom event when the countdown ends

// To control the countdown from external scripts:
// Option 1 -----------------------------------------
// Start the countdown via the Script component:
// script.startCountdown();

// Option 2 -----------------------------------------
// Start the countdown via the global function:
// global.countdownController.startCountdown();

//@input bool playOnStart
//@ui{"widget":"separator"}
//@input Component.Text numberText
//@ui{"widget":"separator"}
//@input int startNumber = 3
//@input int startSize = 100
//@input int endSize = 350
//@input float interval = 1
//@ui{"widget":"separator"}
//@input vec4 startColor {"widget":"color"}
//@input vec4 endColor {"widget":"color"}
//@ui {"widget": "separator"}
//@input bool useBehavior
//@input string onCompleteTrigger = "ON_COMPLETE" {"showIf" : "useBehavior"}
//@ui {"widget":"separator"}
//@input bool callApiFunc
//@input Component.ScriptComponent scriptWithApi  {"showIf" : "callApiFunc"}
//@input string onCompleteFunction = "onComplete" {"showIf" : "callApiFunc"}
// @input float delayNextCountdown

var timer;
var number;
var countdownStarted;

var isFace = false;
var waitToStart = false;

var onFaceFound = script.createEvent("FaceFoundEvent");
onFaceFound.bind(function(){
    isFace = true;
    if (waitToStart){
        start();
        waitToStart = false;
    }
});

var onFaceLost = script.createEvent("FaceLostEvent");
onFaceLost.bind(function(){
    isFace = false;
});

function onUpdate() {    
    
    if (!countdownStarted) {
        return;
    }
    
    var t = timer / script.interval;
    updateSize(t);
    updateColor(t);
    
    if (timer >= script.interval) {
        changeNumber();
        timer = 0;
    }
    
    if (number < 1) {
        completeCountdown();
    }    
    
    timer += getDeltaTime();        
}

function start() {
    if (isFace){
        countdownStarted = true;
        script.numberText.enabled = true;
    }
    else {
        waitToStart = true;
    }
}

var delayedCountDown = script.createEvent("DelayedCallbackEvent");
delayedCountDown.bind(function(){
    reset();
    start();
});

function stop() {
    countdownStarted = false;
}

function reset() {
    countdownStarted = false;
    timer = 0;
    number = script.startNumber;
    script.numberText.text = number.toString();
    script.numberText.size = script.startSize;
    script.numberText.textFill.color = script.startColor;
}

function completeCountdown() {
    countdownStarted = false;
    script.numberText.enabled = false; 
    onComplete();  
    
    delayedCountDown.enabled = true;
    delayedCountDown.reset(script.delayNextCountdown);
}

function onComplete() {
    if (script.callApiFunc && script.scriptWithApi && script.onCompleteFunction && script.scriptWithApi.api[script.onCompleteFunction]) {
        script.scriptWithApi.api[script.onCompleteFunction]();
    }
    if (script.useBehavior && global.behaviorSystem && script.onCompleteTrigger) {
        global.behaviorSystem.sendCustomTrigger(script.onCompleteTrigger);
    }
}

function updateSize(t) {
    var newSize = (script.endSize - script.startSize) * t + script.startSize;
    script.numberText.size = newSize;   
}

function updateColor(t) {
    var newColor = vec4.lerp(script.startColor, script.endColor, t);
    script.numberText.textFill.color = newColor;
}

function changeNumber() {
    number--;
    script.numberText.text = number.toString();
}

function checkInitialized() {
    if (!script.numberText) {
        print("Error: Please set Number Text");
        return false;
    }
    
    if (!script.startSize || script.startSize < 0) {
        print("Error: Please set Start Size");
        return false;
    }
    
    if (!script.endSize || script.endSize < 0) {
        print("Error: Please set End Size");
        return false;
    }
    
    if (!script.startColor) {
        print("Error: Please set Start Color");
        return false;
    }
    
    if (!script.startColor) {
        print("Error: Please set End Color");
        return false;
    }
    
    if (!script.interval || script.interval <= 0) {
        print("Error: Please set Interval");
        return false;
    }

    if (script.useBehavior && !global.behaviorSystem) {
        print("Error: Behavior script is missing from project");
        return;
    }    
    
    if (script.useBehavior && !script.onCompleteTrigger) {
        print("Warning: On Complete trigger is not set");
    }
    
    if (script.callApiFunc && !script.countdownCompletion) {
        print("Warning: Countdown Completion script is not set");
    }
    
    reset();
    
    if(script.playOnStart) {
        start();        
    }
    
    return true;
}

function initialize() {
    var initialized = checkInitialized();

    if (!initialized) {
        return;
    }
    
    script.createEvent("UpdateEvent").bind(onUpdate);
}

initialize();

script.startCountdown = start;
script.stopCountdown = stop;
script.resetCountdown = reset;
global.countdownController = script;