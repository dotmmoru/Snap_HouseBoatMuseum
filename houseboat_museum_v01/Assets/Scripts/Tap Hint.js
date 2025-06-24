//@input float animationDuration
/** @type {number} */
var animationDuration = script.animationDuration;
//@input float delayDuration
/** @type {number} */
var delayDuration = script.delayDuration;

var thisObj = script.getSceneObject();


function Start() {
    ShowAnimation(true);
    delay_HideAnimation.reset(animationDuration);
}

function ShowAnimation(value) {
    global.tweenManager.startTween(thisObj, value ? "show" : "hide");
}

var delay_HideAnimation = script.createEvent("DelayedCallbackEvent");
delay_HideAnimation.bind(function (eventData) {
    ShowAnimation(false);
    delay_ShowAnimation.reset(delayDuration);
});


var delay_ShowAnimation = script.createEvent("DelayedCallbackEvent");
delay_ShowAnimation.bind(function (eventData) {
    ShowAnimation(true);
    delay_HideAnimation.reset(animationDuration);
});


Start();