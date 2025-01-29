// @input SceneObject distanceHint
// @input Component.ObjectTracking3D track
// @input SceneObject manSuitTween
// @input SceneObject womanSuitTween
// @input Asset.Material suitMat

var isHint = false;
var wasStartHint = false;

var isTracked = false;

function setCostums(status){
    var curColor = script.suitMat.mainPass.baseColor;
    
    global.tweenManager.setStartValue(script.manSuitTween, status ? "show" : "hide", curColor);
    global.tweenManager.setStartValue(script.womanSuitTween, status ? "show" : "hide", curColor);
    
    global.tweenManager.stopTween(script.manSuitTween, status ? "hide" : "show");
    global.tweenManager.stopTween(script.womanSuitTween, status ? "hide" : "show");
    
    global.tweenManager.startTween(script.manSuitTween, status ? "show" : "hide");
    global.tweenManager.startTween(script.womanSuitTween, status ? "show" : "hide");

}

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
    if (!isHint && !isTracked){
        global.tweenManager.stopTween(script.distanceHint, "hide");
        global.tweenManager.startTween(script.distanceHint, "show");
        isHint = true;
        wasStartHint = true;
        
        delayedHintOut.enabled = true;
        delayedHintOut.reset(5);
    }
}

var delayedHintIn = script.createEvent("DelayedCallbackEvent");
delayedHintIn.bind(hintIn);

function Start(){
    delayedHintIn.enabled = true;
    delayedHintIn.reset(2);
}

Start();

function checkTracking(){
    if (!isTracked && (script.track.isAttachmentPointTracking("RightLeg") ||
    script.track.isAttachmentPointTracking("LeftLeg"))){
        isTracked = true;
        wasStartHint = true;
        if (isHint){
            hintOut();
            delayedHintIn.cancel();
            delayedHintIn.cancel();
        }
    }
    else {
        if (isTracked && !script.track.isAttachmentPointTracking("RightLeg") &&
        !script.track.isAttachmentPointTracking("LeftLeg")){
            isTracked = false;
            if (wasStartHint && !isHint){
                delayedHintOut.cancel();
                delayedHintIn.enabled = true;
                delayedHintIn.reset(3);
            }
        }
    }
}

var onUpdate = script.createEvent("UpdateEvent");
onUpdate.bind(checkTracking);