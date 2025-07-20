// @input SceneObject headPin0
// @input SceneObject headPin1
// @input SceneObject manCap
// @input SceneObject womanCap
// @input SceneObject headShadow0
// @input SceneObject headShadow1
// @input Asset.Material manShadowMat
// @input Asset.Material womanShadowMat

// @input SceneObject[] mansuitObjs0
// @input SceneObject[] mansuitObjs1
// @input SceneObject[] womansuitObjs0
// @input SceneObject[] womansuitObjs1



var isFace0 = false;
var isFace1 = false;

var state = true;

var shadowMesh0 = script.headShadow0.getComponents("Component.RenderMeshVisual")[1];
var shadowMesh1 = script.headShadow1.getComponents("Component.RenderMeshVisual")[1];

var onFaceFound0 = script.createEvent("FaceFoundEvent");
onFaceFound0.faceIndex = 0;
onFaceFound0.bind(function(){
    isFace0 = true;
    
    shadowMesh0.enabled = true;
});

var onFaceLost0 = script.createEvent("FaceLostEvent");
onFaceLost0.faceIndex = 0;
onFaceLost0.bind(function(){
    isFace0 = false;
    
    script.manCap.enabled = false;
    script.womanCap.enabled = false;
    
    shadowMesh0.enabled = false;
    shadowMesh1.enabled = false;
    
    for (var i = 0; i < script.mansuitObjs0.length; i++){
        script.mansuitObjs0[i].enabled = false;
    }
    
    for (var i = 0; i < script.mansuitObjs1.length; i++){
        script.mansuitObjs1[i].enabled = false;
    }
    
    for (var i = 0; i < script.womansuitObjs0.length; i++){
        script.womansuitObjs0[i].enabled = false;
    }
    
    for (var i = 0; i < script.womansuitObjs1.length; i++){
        script.womansuitObjs1[i].enabled = false;
    }
});


var onFaceFound1 = script.createEvent("FaceFoundEvent");
onFaceFound1.faceIndex = 1;
onFaceFound1.bind(function(){
    isFace1 = true;
    
    script.manCap.enabled = true;
    script.womanCap.enabled = true;
    
    shadowMesh0.enabled = true;
    shadowMesh1.enabled = true;
});

var onFaceLost1 = script.createEvent("FaceLostEvent");
onFaceLost1.faceIndex = 1;
onFaceLost1.bind(function(){
    isFace1 = false;
    
    script.manCap.enabled = false;
    script.womanCap.enabled = false;
    
    shadowMesh1.enabled = false;
    
    for (var i = 0; i < script.mansuitObjs1.length; i++){
        script.mansuitObjs1[i].enabled = false;
    }
    
    for (var i = 0; i < script.womansuitObjs1.length; i++){
        script.womansuitObjs1[i].enabled = false;
    }
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
        
        shadowMesh0.mainMaterial = state ? script.manShadowMat : script.womanShadowMat;
        shadowMesh1.mainMaterial = state ? script.womanShadowMat : script.manShadowMat;

        for (var i = 0; i < script.mansuitObjs0.length; i++){
            script.mansuitObjs0[i].enabled = state;
        }
    
        for (var i = 0; i < script.mansuitObjs1.length; i++){
            script.mansuitObjs1[i].enabled = !state;
        }
    
        for (var i = 0; i < script.womansuitObjs0.length; i++){
            script.womansuitObjs0[i].enabled = !state;
        }
    
        for (var i = 0; i < script.womansuitObjs1.length; i++){
            script.womansuitObjs1[i].enabled = state;
        }
        
    }
    else {
        if (isFace0){

            script.manCap.getTransform().setWorldPosition(headPos0);
            script.manCap.getTransform().setWorldRotation(headRot0);
            
            script.womanCap.getTransform().setWorldPosition(headPos0);
            script.womanCap.getTransform().setWorldRotation(headRot0);
            
            script.manCap.enabled = state;
            script.womanCap.enabled = !state;
            
            shadowMesh0.mainMaterial = state ? script.manShadowMat : script.womanShadowMat;
            
            for (var i = 0; i < script.mansuitObjs0.length; i++){
                script.mansuitObjs0[i].enabled = state;
            }
            
            for (var i = 0; i < script.womansuitObjs0.length; i++){
                script.womansuitObjs0[i].enabled = !state;
            }
        }
    }
}


var onUpdate = script.createEvent("UpdateEvent");
onUpdate.bind(hatsBind);

var onTap = script.createEvent("TapEvent");
onTap.bind(function(){
    state = !state;
    print("TAP");
});