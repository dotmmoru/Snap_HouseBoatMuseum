// @input SceneObject headBinding
// @input Asset.Material[] hatMats

var onUpdate = script.createEvent("UpdateEvent");
onUpdate.bind(function(){
    var pos = script.headBinding.getTransform().getWorldPosition();
    var forward = script.headBinding.getTransform().forward.z;
    //print(forward);
    
    for (var i = 0; i < script.hatMats.length; i++){
        script.hatMats[i].mainPass.headPos = pos;
        script.hatMats[i].mainPass.tiltOffset = forward;
    }
});