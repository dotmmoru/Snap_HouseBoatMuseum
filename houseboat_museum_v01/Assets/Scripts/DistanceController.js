// @input SceneObject distanceHint
// @input Component.ObjectTracking3D track
// @input SceneObject head0
// @input SceneObject head1
// @input SceneObject manSuitTween
// @input SceneObject womanSuitTween
// @input Asset.Material suitMat
// @input float distThreshold


var isHint = false;
var wasStartHint = false;

var isTracked = false;
var countDownstarted = false;

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

    if (!isTracked && isFace0 && areFar && (script.track.isAttachmentPointTracking(rightLegKey) ||
        script.track.isAttachmentPointTracking(leftLegKey))) {
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

        setCostums(true);
    }
    else {
        if (isTracked && (!areFar || (!script.track.isAttachmentPointTracking(rightLegKey) &&
            !script.track.isAttachmentPointTracking(leftLegKey)))) {
            isTracked = false;
            setCostums(false);
        }
    }
}

var onUpdate = script.createEvent("UpdateEvent");
onUpdate.bind(checkTracking);