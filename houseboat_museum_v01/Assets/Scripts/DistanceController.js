// @input SceneObject distanceHint
// @input Component.ObjectTracking3D bodytrack0
// @input Component.ObjectTracking3D bodytrack1
// @input SceneObject head0
// @input SceneObject head1
// @input SceneObject manSuitTween
// @input SceneObject womanSuitTween
// @input Asset.Material suitMat
// @input float distThreshold

// @input Asset.Material bodyOccluderMat0

// @input Asset.Material bodyOccluderMat1

// @input Asset.Texture neckMask
// @input Asset.Texture bodyMask


var isHint = false;
var wasStartHint = false;

var isTracked = false;
var countDownstarted = false;
var isFullBody0 = false;
var isFullBody1 = false;

var bodyBoneNames = ["LeftArm", "LeftForeArm", "LeftHand",
    "RightArm", "RightForeArm", "RightHand"];

function initHands0(){    
    script.bodyOccluderMat0.mainPass.bodyMask = script.neckMask;
}

function initHands1(){    
    script.bodyOccluderMat1.mainPass.bodyMask = script.neckMask;
}

initHands0();
initHands1();


var isFace0 = false;
var isFace1 = false;

var onFaceFound0 = script.createEvent("FaceFoundEvent");
onFaceFound0.faceIndex = 0;
onFaceFound0.bind(function () {
    isFace0 = true;
});

var onFaceLost0 = script.createEvent("FaceLostEvent");
onFaceLost0.faceIndex = 0;
onFaceLost0.bind(function () {
    isFace0 = false;
    isFace1 = false;
});

var onFaceFound1 = script.createEvent("FaceFoundEvent");
onFaceFound1.faceIndex = 1;
onFaceFound1.bind(function () {
    isFace1 = true;
});

var onFaceLost1 = script.createEvent("FaceLostEvent");
onFaceLost1.faceIndex = 1;
onFaceLost1.bind(function () {
    isFace1 = false;
});

function setCostums(status) {
    var curColor = script.suitMat.mainPass.baseColor;

    global.tweenManager.setStartValue(script.manSuitTween, status ? "show" : "hide", curColor);
    global.tweenManager.setStartValue(script.womanSuitTween, status ? "show" : "hide", curColor);

    global.tweenManager.stopTween(script.manSuitTween, status ? "hide" : "show");
    global.tweenManager.stopTween(script.womanSuitTween, status ? "hide" : "show");

    global.tweenManager.startTween(script.manSuitTween, status ? "show" : "hide");
    global.tweenManager.startTween(script.womanSuitTween, status ? "show" : "hide");

}

function hintOut() {
    if (isHint) {
        global.tweenManager.stopTween(script.distanceHint, "show");
        global.tweenManager.startTween(script.distanceHint, "hide", function () {
            if (!countDownstarted) {
                global.countdownController.startCountdown();
                countDownstarted = true;
            }
        });
        isHint = false;
    }
}

var delayedHintOut = script.createEvent("DelayedCallbackEvent");
delayedHintOut.bind(hintOut);

function hintIn() {
    if (!isHint && !isTracked) {
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

function Start() {
    delayedHintIn.enabled = true;
    delayedHintIn.reset(2);
}

Start();

function checkTracking() {
    
    //print(isFullBody1);    
    
    var camPos = new vec3(0, 0, 40);
    var headDist0 = script.head0.getTransform().getWorldPosition().distance(camPos);
    var headDist1 = script.head1.getTransform().getWorldPosition().distance(camPos);

    var areFar = false;
    if (isFace1) {
        areFar = Math.min(headDist0, headDist1) > script.distThreshold;
    }
    else {
        if (isFace0) {
            areFar = headDist0 > script.distThreshold;
        }
    }

    var rightLegKey = "RightUpLeg";
    var leftLegKey = "LeftUpLeg";

    if (!isTracked && isFace0 && areFar && (script.bodytrack0.isAttachmentPointTracking(rightLegKey) ||
        script.bodytrack0.isAttachmentPointTracking(leftLegKey))) {
        isTracked = true;
        wasStartHint = true;
        if (isHint) {
            hintOut();
            delayedHintIn.cancel();
            delayedHintIn.cancel();
        }
        else {
            if (!countDownstarted) {
                global.countdownController.startCountdown();
                countDownstarted = true;
            }
        }

        //setCostums(true);
    }
    else {
        if (isTracked && (!areFar || (!script.bodytrack0.isAttachmentPointTracking(rightLegKey) &&
            !script.bodytrack0.isAttachmentPointTracking(leftLegKey)))) {
            isTracked = false;
            //setCostums(false);
        }
    }
    
    
    if (!isFullBody0 && (script.bodytrack0.isAttachmentPointTracking("LeftLeg") ||
        script.bodytrack0.isAttachmentPointTracking("RightLeg"))){
        isFullBody0 = true;
        
        script.bodyOccluderMat0.mainPass.bodyMask = script.bodyMask;
    }
    else {
        if (isFullBody0 && !script.bodytrack0.isAttachmentPointTracking("LeftLeg") &&
            !script.bodytrack0.isAttachmentPointTracking("RightLeg")){
            isFullBody0 = false;
            
            initHands0();
        }
    }
    
    if (isFace1){
        if (!isFullBody1 && (script.bodytrack1.isAttachmentPointTracking("LeftLeg") ||
            script.bodytrack1.isAttachmentPointTracking("RightLeg"))){
            isFullBody1 = true;
        
            script.bodyOccluderMat1.mainPass.bodyMask = script.bodyMask;
        }
        else {
            if (isFullBody1 && !script.bodytrack1.isAttachmentPointTracking("LeftLeg") &&
                !script.bodytrack1.isAttachmentPointTracking("RightLeg")){
                isFullBody1 = false;
            
                initHands1();
            }
        }
    }
}

var onUpdate = script.createEvent("UpdateEvent");
onUpdate.bind(checkTracking);