// @input SceneObject headPin0
// @input SceneObject headPin1
// @input SceneObject manCap
// @input SceneObject womanCap



var onFaceFound0 = script.createEvent("FaceFoundEvent");
onFaceFound0.faceIndex = 0;
onFaceFound0.bind(function(){
    
});

var onFaceLost0 = script.createEvent("FaceLostEvent");
onFaceLost0.faceIndex = 0;
onFaceLost0.bind(function(){
    script.manCap.enabled = false;
    script.womanCap.enabled = false;
});