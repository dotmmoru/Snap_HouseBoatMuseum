// @input SceneObject headPin0
// @input SceneObject headPin1
// @input SceneObject manCap
// @input SceneObject womanCap

var isFace0 = false;
var isFace1 = false;

var state = true;

var onFaceFound0 = script.createEvent("FaceFoundEvent");
onFaceFound0.faceIndex = 0;
onFaceFound0.bind(function(){
    isFace0 = true;
});

var onFaceLost0 = script.createEvent("FaceLostEvent");
onFaceLost0.faceIndex = 0;
onFaceLost0.bind(function(){
    isFace0 = false;
    
    script.manCap.enabled = false;
    script.womanCap.enabled = false;
});


var onFaceFound1 = script.createEvent("FaceFoundEvent");
onFaceFound1.faceIndex = 1;
onFaceFound1.bind(function(){
    isFace1 = true;
    
    script.manCap.enabled = true;
    script.womanCap.enabled = true;
});

var onFaceLost1 = script.createEvent("FaceLostEvent");
onFaceLost1.faceIndex = 1;
onFaceLost1.bind(function(){
    isFace1 = false;
    
    script.manCap.enabled = false;
    script.womanCap.enabled = false;
});

function hatsBind(){
    //print(isFace1);
    var headPos0 = script.headPin0.getTransform().getWorldPosition();
    var headRot0 = script.headPin0.getTransform().getWorldRotation();
    
    var headPos1 = script.headPin1.getTransform().getWorldPosition();
    var headRot1 = script.headPin1.getTransform().getWorldRotation();
    
    if (isFace1){
        script.manCap.getTransform().setWorldPosition(state ? headPos0 : headPos1);
        script.manCap.getTransform().setWorldRotation(state ? headRot0 : headRot1);
        
        script.womanCap.getTransform().setWorldPosition(state ? headPos1 : headPos0);
        script.womanCap.getTransform().setWorldRotation(state ? headRot1 : headRot0);
    }
    else {
        if (isFace0){
            script.manCap.getTransform().setWorldPosition(headPos0);
            script.manCap.getTransform().setWorldRotation(headRot0);
            
            script.womanCap.getTransform().setWorldPosition(headPos0);
            script.womanCap.getTransform().setWorldRotation(headRot0);
            
            script.manCap.enabled = state;
            script.womanCap.enabled = !state;
        }
    }
}


var onUpdate = script.createEvent("UpdateEvent");
onUpdate.bind(hatsBind);

var onTap = script.createEvent("TapEvent");
onTap.bind(function(){
    state = !state;
});