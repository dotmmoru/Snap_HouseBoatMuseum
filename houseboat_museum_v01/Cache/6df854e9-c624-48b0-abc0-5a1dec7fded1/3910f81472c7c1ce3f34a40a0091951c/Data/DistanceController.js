// @input SceneObject distanceHint
// @input Component.ObjectTracking3D track
// @input SceneObject manSuitTween
// @input SceneObject womanSuitTween

function hintIn(){
    global.tweenManager.stopTween(script.distanceHint, "hide");
    global.tweenManager.startTween(script.distanceHint, "show");
}

var delayedHintIn = script.createEvent("DelayedCallbackEvent");
delayedHintIn.bind(hintIn);

function Start(){
    delayedHintIn.enabled = true;
    delayedHintIn.reset(2);
}

Start();