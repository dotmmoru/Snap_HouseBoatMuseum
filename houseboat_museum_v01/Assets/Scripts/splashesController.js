// @input SceneObject splashesTween
// @input float splashDuration
// @input float splashInterval

function ShowWaterSplash() {
	delay_ShowWaterSplash.reset(1);
}
///////////////	DELAY	////////////////////
var delay_ShowWaterSplash = script.createEvent("DelayedCallbackEvent");
delay_ShowWaterSplash.bind(function (eventData) {
	global.tweenManager.startTween(script.splashesTween, "show");
    delay_HideWaterSplash.reset(script.splashDuration);
});

var delay_HideWaterSplash = script.createEvent("DelayedCallbackEvent");
delay_HideWaterSplash.bind(function (eventData) {
	global.tweenManager.startTween(script.splashesTween, "hide");
	delay_ShowWaterSplash.reset(script.splashInterval);
});

ShowWaterSplash();