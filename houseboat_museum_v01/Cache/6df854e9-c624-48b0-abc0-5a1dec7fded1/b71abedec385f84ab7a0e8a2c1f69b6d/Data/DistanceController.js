// @input SceneObject distanceHint
// @input Component.ObjectTracking3D track
// @input SceneObject manSuitTween
// @input SceneObject womanSuitTween

var isHint = false;

function hintOut(){
    if (isHint){
        global.tweenManager.stopTween(script.distanceHint, "show");
        global.tweenManager.startTween(script.distanceHint, "hide");
        isHint = false;
    }
}

var delayedHintOut = script.createEvent("DelayedCallbackEvent");
delayedHintOut.bind(hintOut);

function hintIn(){
    if (!isHint){
        global.tweenManager.stopTween(script.distanceHint, "hide");
        global.tweenManager.startTween(script.distanceHint, "show");
        isHint = true;
        
        delayedHintOut.enabled = true;
        delayedHintOut.reset(3);
    }
}

var delayedHintIn = script.createEvent("DelayedCallbackEvent");
delayedHintIn.bind(hintIn);

function Start(){
    delayedHintIn.enabled = true;
    delayedHintIn.reset(2);
}

Start();