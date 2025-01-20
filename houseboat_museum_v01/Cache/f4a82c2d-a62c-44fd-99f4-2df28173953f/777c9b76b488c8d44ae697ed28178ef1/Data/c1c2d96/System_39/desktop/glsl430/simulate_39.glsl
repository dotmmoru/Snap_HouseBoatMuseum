#version 430
//#include <required.glsl> // [HACK 4/6/2023] See SCC shader_merger.cpp
//SG_REFLECTION_BEGIN(100)
//attribute vec4 boneData 5
//attribute vec3 blendShape0Pos 6
//attribute vec3 blendShape0Normal 12
//attribute vec3 blendShape1Pos 7
//attribute vec3 blendShape1Normal 13
//attribute vec3 blendShape2Pos 8
//attribute vec3 blendShape2Normal 14
//attribute vec3 blendShape3Pos 9
//attribute vec3 blendShape4Pos 10
//attribute vec3 blendShape5Pos 11
//attribute vec4 position 0
//attribute vec3 normal 1
//attribute vec4 tangent 2
//attribute vec2 texture0 3
//attribute vec2 texture1 4
//attribute vec3 positionNext 15
//attribute vec3 positionPrevious 16
//attribute vec4 strandProperties 17
//sampler sampler Tweak_N49SmpSC 2:20
//sampler sampler renderTarget0SmpSC 2:22
//sampler sampler renderTarget1SmpSC 2:23
//sampler sampler renderTarget2SmpSC 2:24
//sampler sampler renderTarget3SmpSC 2:25
//texture texture3D Tweak_N49 2:0:2:20
//texture texture2D renderTarget0 2:2:2:22
//texture texture2D renderTarget1 2:3:2:23
//texture texture2D renderTarget2 2:4:2:24
//texture texture2D renderTarget3 2:5:2:25
//texture texture2DArray renderTarget0ArrSC 2:34:2:22
//texture texture2DArray renderTarget1ArrSC 2:35:2:23
//texture texture2DArray renderTarget2ArrSC 2:36:2:24
//texture texture2DArray renderTarget3ArrSC 2:37:2:25
//SG_REFLECTION_END
#if defined VERTEX_SHADER
#define SC_DISABLE_FRUSTUM_CULLING
#define SC_ALLOW_16_TEXTURES
#define SC_ENABLE_INSTANCED_RENDERING
#define sc_StereoRendering_Disabled 0
#define sc_StereoRendering_InstancedClipped 1
#define sc_StereoRendering_Multiview 2
#ifdef GL_ES
    #define SC_GLES_VERSION_20 2000
    #define SC_GLES_VERSION_30 3000
    #define SC_GLES_VERSION_31 3100
    #define SC_GLES_VERSION_32 3200
#endif
#ifdef VERTEX_SHADER
    #define scOutPos(clipPosition) gl_Position=clipPosition
    #define MAIN main
#endif
#ifdef SC_ENABLE_INSTANCED_RENDERING
    #ifndef sc_EnableInstancing
        #define sc_EnableInstancing 1
    #endif
#endif
#define mod(x,y) (x-y*floor((x+1e-6)/y))
#if defined(GL_ES)&&(__VERSION__<300)&&!defined(GL_OES_standard_derivatives)
#define dFdx(A) (A)
#define dFdy(A) (A)
#define fwidth(A) (A)
#endif
#if __VERSION__<300
#define isinf(x) (x!=0.0&&x*2.0==x ? true : false)
#define isnan(x) (x>0.0||x<0.0||x==0.0 ? false : true)
#endif
#ifdef sc_EnableFeatureLevelES3
    #ifdef sc_EnableStereoClipDistance
        #if defined(GL_APPLE_clip_distance)
            #extension GL_APPLE_clip_distance : require
        #elif defined(GL_EXT_clip_cull_distance)
            #extension GL_EXT_clip_cull_distance : require
        #else
            #error Clip distance is requested but not supported by this device.
        #endif
    #endif
#else
    #ifdef sc_EnableStereoClipDistance
        #error Clip distance is requested but not supported by this device.
    #endif
#endif
#ifdef sc_EnableFeatureLevelES3
    #ifdef VERTEX_SHADER
        #define attribute in
        #define varying out
    #endif
    #ifdef FRAGMENT_SHADER
        #define varying in
    #endif
    #define gl_FragColor sc_FragData0
    #define texture2D texture
    #define texture2DLod textureLod
    #define texture2DLodEXT textureLod
    #define textureCubeLodEXT textureLod
    #define sc_CanUseTextureLod 1
#else
    #ifdef FRAGMENT_SHADER
        #if defined(GL_EXT_shader_texture_lod)
            #extension GL_EXT_shader_texture_lod : require
            #define sc_CanUseTextureLod 1
            #define texture2DLod texture2DLodEXT
        #endif
    #endif
#endif
#if defined(sc_EnableMultiviewStereoRendering)
    #define sc_StereoRenderingMode sc_StereoRendering_Multiview
    #define sc_NumStereoViews 2
    #extension GL_OVR_multiview2 : require
    #ifdef VERTEX_SHADER
        #ifdef sc_EnableInstancingFallback
            #define sc_GlobalInstanceID (sc_FallbackInstanceID*2+gl_InstanceID)
        #else
            #define sc_GlobalInstanceID gl_InstanceID
        #endif
        #define sc_LocalInstanceID sc_GlobalInstanceID
        #define sc_StereoViewID int(gl_ViewID_OVR)
    #endif
#elif defined(sc_EnableInstancedClippedStereoRendering)
    #ifndef sc_EnableInstancing
        #error Instanced-clipped stereo rendering requires enabled instancing.
    #endif
    #ifndef sc_EnableStereoClipDistance
        #define sc_StereoRendering_IsClipDistanceEnabled 0
    #else
        #define sc_StereoRendering_IsClipDistanceEnabled 1
    #endif
    #define sc_StereoRenderingMode sc_StereoRendering_InstancedClipped
    #define sc_NumStereoClipPlanes 1
    #define sc_NumStereoViews 2
    #ifdef VERTEX_SHADER
        #ifdef sc_EnableInstancingFallback
            #define sc_GlobalInstanceID (sc_FallbackInstanceID*2+gl_InstanceID)
        #else
            #define sc_GlobalInstanceID gl_InstanceID
        #endif
        #ifdef sc_EnableFeatureLevelES3
            #define sc_LocalInstanceID (sc_GlobalInstanceID/2)
            #define sc_StereoViewID (sc_GlobalInstanceID%2)
        #else
            #define sc_LocalInstanceID int(sc_GlobalInstanceID/2.0)
            #define sc_StereoViewID int(mod(sc_GlobalInstanceID,2.0))
        #endif
    #endif
#else
    #define sc_StereoRenderingMode sc_StereoRendering_Disabled
#endif
#ifdef VERTEX_SHADER
    #ifdef sc_EnableInstancing
        #ifdef GL_ES
            #if defined(sc_EnableFeatureLevelES2)&&!defined(GL_EXT_draw_instanced)
                #define gl_InstanceID (0)
            #endif
        #else
            #if defined(sc_EnableFeatureLevelES2)&&!defined(GL_EXT_draw_instanced)&&!defined(GL_ARB_draw_instanced)&&!defined(GL_EXT_gpu_shader4)
                #define gl_InstanceID (0)
            #endif
        #endif
        #ifdef GL_ARB_draw_instanced
            #extension GL_ARB_draw_instanced : require
            #define gl_InstanceID gl_InstanceIDARB
        #endif
        #ifdef GL_EXT_draw_instanced
            #extension GL_EXT_draw_instanced : require
            #define gl_InstanceID gl_InstanceIDEXT
        #endif
        #ifndef sc_InstanceID
            #define sc_InstanceID gl_InstanceID
        #endif
        #ifndef sc_GlobalInstanceID
            #ifdef sc_EnableInstancingFallback
                #define sc_GlobalInstanceID (sc_FallbackInstanceID)
                #define sc_LocalInstanceID (sc_FallbackInstanceID)
            #else
                #define sc_GlobalInstanceID gl_InstanceID
                #define sc_LocalInstanceID gl_InstanceID
            #endif
        #endif
    #endif
#endif
#ifdef VERTEX_SHADER
    #if (__VERSION__<300)&&!defined(GL_EXT_gpu_shader4)
        #define gl_VertexID (0)
    #endif
#endif
#ifndef GL_ES
        #extension GL_EXT_gpu_shader4 : enable
    #extension GL_ARB_shader_texture_lod : enable
    #ifndef texture2DLodEXT
        #define texture2DLodEXT texture2DLod
    #endif
    #ifndef sc_CanUseTextureLod
    #define sc_CanUseTextureLod 1
    #endif
    #define precision
    #define lowp
    #define mediump
    #define highp
    #define sc_FragmentPrecision
#endif
#ifdef sc_EnableFeatureLevelES3
    #define sc_CanUseSampler2DArray 1
#endif
#if defined(sc_EnableFeatureLevelES2)&&defined(GL_ES)
    #ifdef FRAGMENT_SHADER
        #ifdef GL_OES_standard_derivatives
            #extension GL_OES_standard_derivatives : require
            #define sc_CanUseStandardDerivatives 1
        #endif
    #endif
    #ifdef GL_EXT_texture_array
        #extension GL_EXT_texture_array : require
        #define sc_CanUseSampler2DArray 1
    #else
        #define sc_CanUseSampler2DArray 0
    #endif
#endif
#ifdef GL_ES
    #ifdef sc_FramebufferFetch
        #if defined(GL_EXT_shader_framebuffer_fetch)
            #extension GL_EXT_shader_framebuffer_fetch : require
        #elif defined(GL_ARM_shader_framebuffer_fetch)
            #extension GL_ARM_shader_framebuffer_fetch : require
        #else
            #error Framebuffer fetch is requested but not supported by this device.
        #endif
    #endif
    #ifdef GL_FRAGMENT_PRECISION_HIGH
        #define sc_FragmentPrecision highp
    #else
        #define sc_FragmentPrecision mediump
    #endif
    #ifdef FRAGMENT_SHADER
        precision highp int;
        precision highp float;
    #endif
#endif
#ifdef VERTEX_SHADER
    #ifdef sc_EnableMultiviewStereoRendering
        layout(num_views=sc_NumStereoViews) in;
    #endif
#endif
#if __VERSION__>100
    #define SC_INT_FALLBACK_FLOAT int
    #define SC_INTERPOLATION_FLAT flat
    #define SC_INTERPOLATION_CENTROID centroid
#else
    #define SC_INT_FALLBACK_FLOAT float
    #define SC_INTERPOLATION_FLAT
    #define SC_INTERPOLATION_CENTROID
#endif
#ifndef sc_NumStereoViews
    #define sc_NumStereoViews 1
#endif
#ifndef sc_CanUseSampler2DArray
    #define sc_CanUseSampler2DArray 0
#endif
    #if __VERSION__==100||defined(SCC_VALIDATION)
        #define sampler2DArray vec2
        #define sampler3D vec3
        #define samplerCube vec4
        vec4 texture3D(vec3 s,vec3 uv)                       { return vec4(0.0); }
        vec4 texture3D(vec3 s,vec3 uv,float bias)           { return vec4(0.0); }
        vec4 texture3DLod(vec3 s,vec3 uv,float bias)        { return vec4(0.0); }
        vec4 texture3DLodEXT(vec3 s,vec3 uv,float lod)      { return vec4(0.0); }
        vec4 texture2DArray(vec2 s,vec3 uv)                  { return vec4(0.0); }
        vec4 texture2DArray(vec2 s,vec3 uv,float bias)      { return vec4(0.0); }
        vec4 texture2DArrayLod(vec2 s,vec3 uv,float lod)    { return vec4(0.0); }
        vec4 texture2DArrayLodEXT(vec2 s,vec3 uv,float lod) { return vec4(0.0); }
        vec4 textureCube(vec4 s,vec3 uv)                     { return vec4(0.0); }
        vec4 textureCube(vec4 s,vec3 uv,float lod)          { return vec4(0.0); }
        vec4 textureCubeLod(vec4 s,vec3 uv,float lod)       { return vec4(0.0); }
        vec4 textureCubeLodEXT(vec4 s,vec3 uv,float lod)    { return vec4(0.0); }
        #if defined(VERTEX_SHADER)||!sc_CanUseTextureLod
            #define texture2DLod(s,uv,lod)      vec4(0.0)
            #define texture2DLodEXT(s,uv,lod)   vec4(0.0)
        #endif
    #elif __VERSION__>=300
        #define texture3D texture
        #define textureCube texture
        #define texture2DArray texture
        #define texture2DLod textureLod
        #define texture3DLod textureLod
        #define texture2DLodEXT textureLod
        #define texture3DLodEXT textureLod
        #define textureCubeLod textureLod
        #define textureCubeLodEXT textureLod
        #define texture2DArrayLod textureLod
        #define texture2DArrayLodEXT textureLod
    #endif
    #ifndef sc_TextureRenderingLayout_Regular
        #define sc_TextureRenderingLayout_Regular 0
        #define sc_TextureRenderingLayout_StereoInstancedClipped 1
        #define sc_TextureRenderingLayout_StereoMultiview 2
    #endif
    #define depthToGlobal   depthScreenToViewSpace
    #define depthToLocal    depthViewToScreenSpace
    #ifndef quantizeUV
        #define quantizeUV sc_QuantizeUV
        #define sc_platformUVFlip sc_PlatformFlipV
        #define sc_PlatformFlipUV sc_PlatformFlipV
    #endif
    #ifndef sc_texture2DLod
        #define sc_texture2DLod sc_InternalTextureLevel
        #define sc_textureLod sc_InternalTextureLevel
        #define sc_textureBias sc_InternalTextureBiasOrLevel
        #define sc_texture sc_InternalTexture
    #endif
struct ssParticle
{
vec3 Position;
vec3 Velocity;
vec4 Color;
float Size;
float Age;
float Life;
float Mass;
mat3 Matrix;
bool Dead;
vec4 Quaternion;
float SpawnOffset;
float Seed;
vec2 Seed2000;
float TimeShift;
int Index1D;
int Index1DPerCopy;
float Coord1D;
float Ratio1D;
float Ratio1DPerCopy;
ivec2 Index2D;
vec2 Coord2D;
vec2 Ratio2D;
vec3 Force;
bool Spawned;
float CopyId;
};
struct ssGlobals
{
float gTimeElapsed;
float gTimeDelta;
float gTimeElapsedShifted;
};
#ifndef sc_CanUseTextureLod
#define sc_CanUseTextureLod 0
#elif sc_CanUseTextureLod==1
#undef sc_CanUseTextureLod
#define sc_CanUseTextureLod 1
#endif
#ifndef sc_StereoRenderingMode
#define sc_StereoRenderingMode 0
#endif
#ifndef sc_StereoViewID
#define sc_StereoViewID 0
#endif
#ifndef sc_StereoRendering_IsClipDistanceEnabled
#define sc_StereoRendering_IsClipDistanceEnabled 0
#endif
#ifndef sc_NumStereoViews
#define sc_NumStereoViews 1
#endif
#ifndef sc_SkinBonesCount
#define sc_SkinBonesCount 0
#endif
struct sc_Camera_t
{
vec3 position;
float aspect;
vec2 clipPlanes;
};
#ifndef SC_DEVICE_CLASS
#define SC_DEVICE_CLASS -1
#endif
#ifndef SC_GL_FRAGMENT_PRECISION_HIGH
#define SC_GL_FRAGMENT_PRECISION_HIGH 0
#elif SC_GL_FRAGMENT_PRECISION_HIGH==1
#undef SC_GL_FRAGMENT_PRECISION_HIGH
#define SC_GL_FRAGMENT_PRECISION_HIGH 1
#endif
#ifndef renderTarget0HasSwappedViews
#define renderTarget0HasSwappedViews 0
#elif renderTarget0HasSwappedViews==1
#undef renderTarget0HasSwappedViews
#define renderTarget0HasSwappedViews 1
#endif
#ifndef renderTarget0Layout
#define renderTarget0Layout 0
#endif
#ifndef renderTarget1HasSwappedViews
#define renderTarget1HasSwappedViews 0
#elif renderTarget1HasSwappedViews==1
#undef renderTarget1HasSwappedViews
#define renderTarget1HasSwappedViews 1
#endif
#ifndef renderTarget1Layout
#define renderTarget1Layout 0
#endif
#ifndef renderTarget2HasSwappedViews
#define renderTarget2HasSwappedViews 0
#elif renderTarget2HasSwappedViews==1
#undef renderTarget2HasSwappedViews
#define renderTarget2HasSwappedViews 1
#endif
#ifndef renderTarget2Layout
#define renderTarget2Layout 0
#endif
#ifndef renderTarget3HasSwappedViews
#define renderTarget3HasSwappedViews 0
#elif renderTarget3HasSwappedViews==1
#undef renderTarget3HasSwappedViews
#define renderTarget3HasSwappedViews 1
#endif
#ifndef renderTarget3Layout
#define renderTarget3Layout 0
#endif
#ifndef SC_USE_UV_TRANSFORM_renderTarget0
#define SC_USE_UV_TRANSFORM_renderTarget0 0
#elif SC_USE_UV_TRANSFORM_renderTarget0==1
#undef SC_USE_UV_TRANSFORM_renderTarget0
#define SC_USE_UV_TRANSFORM_renderTarget0 1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_U_renderTarget0
#define SC_SOFTWARE_WRAP_MODE_U_renderTarget0 -1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_V_renderTarget0
#define SC_SOFTWARE_WRAP_MODE_V_renderTarget0 -1
#endif
#ifndef SC_USE_UV_MIN_MAX_renderTarget0
#define SC_USE_UV_MIN_MAX_renderTarget0 0
#elif SC_USE_UV_MIN_MAX_renderTarget0==1
#undef SC_USE_UV_MIN_MAX_renderTarget0
#define SC_USE_UV_MIN_MAX_renderTarget0 1
#endif
#ifndef SC_USE_CLAMP_TO_BORDER_renderTarget0
#define SC_USE_CLAMP_TO_BORDER_renderTarget0 0
#elif SC_USE_CLAMP_TO_BORDER_renderTarget0==1
#undef SC_USE_CLAMP_TO_BORDER_renderTarget0
#define SC_USE_CLAMP_TO_BORDER_renderTarget0 1
#endif
#ifndef SC_USE_UV_TRANSFORM_renderTarget1
#define SC_USE_UV_TRANSFORM_renderTarget1 0
#elif SC_USE_UV_TRANSFORM_renderTarget1==1
#undef SC_USE_UV_TRANSFORM_renderTarget1
#define SC_USE_UV_TRANSFORM_renderTarget1 1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_U_renderTarget1
#define SC_SOFTWARE_WRAP_MODE_U_renderTarget1 -1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_V_renderTarget1
#define SC_SOFTWARE_WRAP_MODE_V_renderTarget1 -1
#endif
#ifndef SC_USE_UV_MIN_MAX_renderTarget1
#define SC_USE_UV_MIN_MAX_renderTarget1 0
#elif SC_USE_UV_MIN_MAX_renderTarget1==1
#undef SC_USE_UV_MIN_MAX_renderTarget1
#define SC_USE_UV_MIN_MAX_renderTarget1 1
#endif
#ifndef SC_USE_CLAMP_TO_BORDER_renderTarget1
#define SC_USE_CLAMP_TO_BORDER_renderTarget1 0
#elif SC_USE_CLAMP_TO_BORDER_renderTarget1==1
#undef SC_USE_CLAMP_TO_BORDER_renderTarget1
#define SC_USE_CLAMP_TO_BORDER_renderTarget1 1
#endif
#ifndef SC_USE_UV_TRANSFORM_renderTarget2
#define SC_USE_UV_TRANSFORM_renderTarget2 0
#elif SC_USE_UV_TRANSFORM_renderTarget2==1
#undef SC_USE_UV_TRANSFORM_renderTarget2
#define SC_USE_UV_TRANSFORM_renderTarget2 1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_U_renderTarget2
#define SC_SOFTWARE_WRAP_MODE_U_renderTarget2 -1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_V_renderTarget2
#define SC_SOFTWARE_WRAP_MODE_V_renderTarget2 -1
#endif
#ifndef SC_USE_UV_MIN_MAX_renderTarget2
#define SC_USE_UV_MIN_MAX_renderTarget2 0
#elif SC_USE_UV_MIN_MAX_renderTarget2==1
#undef SC_USE_UV_MIN_MAX_renderTarget2
#define SC_USE_UV_MIN_MAX_renderTarget2 1
#endif
#ifndef SC_USE_CLAMP_TO_BORDER_renderTarget2
#define SC_USE_CLAMP_TO_BORDER_renderTarget2 0
#elif SC_USE_CLAMP_TO_BORDER_renderTarget2==1
#undef SC_USE_CLAMP_TO_BORDER_renderTarget2
#define SC_USE_CLAMP_TO_BORDER_renderTarget2 1
#endif
#ifndef SC_USE_UV_TRANSFORM_renderTarget3
#define SC_USE_UV_TRANSFORM_renderTarget3 0
#elif SC_USE_UV_TRANSFORM_renderTarget3==1
#undef SC_USE_UV_TRANSFORM_renderTarget3
#define SC_USE_UV_TRANSFORM_renderTarget3 1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_U_renderTarget3
#define SC_SOFTWARE_WRAP_MODE_U_renderTarget3 -1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_V_renderTarget3
#define SC_SOFTWARE_WRAP_MODE_V_renderTarget3 -1
#endif
#ifndef SC_USE_UV_MIN_MAX_renderTarget3
#define SC_USE_UV_MIN_MAX_renderTarget3 0
#elif SC_USE_UV_MIN_MAX_renderTarget3==1
#undef SC_USE_UV_MIN_MAX_renderTarget3
#define SC_USE_UV_MIN_MAX_renderTarget3 1
#endif
#ifndef SC_USE_CLAMP_TO_BORDER_renderTarget3
#define SC_USE_CLAMP_TO_BORDER_renderTarget3 0
#elif SC_USE_CLAMP_TO_BORDER_renderTarget3==1
#undef SC_USE_CLAMP_TO_BORDER_renderTarget3
#define SC_USE_CLAMP_TO_BORDER_renderTarget3 1
#endif
#ifndef sc_PointLightsCount
#define sc_PointLightsCount 0
#endif
#ifndef sc_DirectionalLightsCount
#define sc_DirectionalLightsCount 0
#endif
#ifndef sc_AmbientLightsCount
#define sc_AmbientLightsCount 0
#endif
struct sc_PointLight_t
{
bool falloffEnabled;
float falloffEndDistance;
float negRcpFalloffEndDistance4;
float angleScale;
float angleOffset;
vec3 direction;
vec3 position;
vec4 color;
};
struct sc_DirectionalLight_t
{
vec3 direction;
vec4 color;
};
struct sc_AmbientLight_t
{
vec3 color;
float intensity;
};
struct sc_SphericalGaussianLight_t
{
vec3 color;
float sharpness;
vec3 axis;
};
struct sc_LightEstimationData_t
{
sc_SphericalGaussianLight_t sg[12];
vec3 ambientLight;
};
uniform vec4 sc_EnvmapDiffuseDims;
uniform vec4 sc_EnvmapSpecularDims;
uniform vec4 sc_ScreenTextureDims;
uniform mat4 sc_ModelMatrix;
uniform mat4 sc_ProjectorMatrix;
uniform vec4 sc_StereoClipPlanes[sc_NumStereoViews];
uniform vec4 sc_BoneMatrices[(sc_SkinBonesCount*3)+1];
uniform mat3 sc_SkinBonesNormalMatrices[sc_SkinBonesCount+1];
uniform vec4 weights0;
uniform vec4 weights1;
uniform mat4 sc_ViewProjectionMatrixArray[sc_NumStereoViews];
uniform mat4 sc_ModelViewProjectionMatrixArray[sc_NumStereoViews];
uniform mat4 sc_ModelViewMatrixArray[sc_NumStereoViews];
uniform sc_Camera_t sc_Camera;
uniform mat4 sc_ProjectionMatrixInverseArray[sc_NumStereoViews];
uniform mat4 sc_ViewMatrixArray[sc_NumStereoViews];
uniform float sc_DisableFrustumCullingMarker;
uniform mat4 sc_ProjectionMatrixArray[sc_NumStereoViews];
uniform mat3 sc_NormalMatrix;
uniform vec2 sc_TAAJitterOffset;
uniform vec4 intensityTextureDims;
uniform vec4 renderTarget0Dims;
uniform vec4 renderTarget1Dims;
uniform vec4 renderTarget2Dims;
uniform vec4 renderTarget3Dims;
uniform int overrideTimeEnabled;
uniform float overrideTimeElapsed;
uniform vec4 sc_Time;
uniform int vfxOffsetInstancesRead;
uniform int vfxTargetWidth;
uniform vec2 vfxTargetSizeRead;
uniform mat3 renderTarget0Transform;
uniform vec4 renderTarget0UvMinMax;
uniform vec4 renderTarget0BorderColor;
uniform bool vfxBatchEnable[32];
uniform mat3 renderTarget1Transform;
uniform vec4 renderTarget1UvMinMax;
uniform vec4 renderTarget1BorderColor;
uniform mat3 renderTarget2Transform;
uniform vec4 renderTarget2UvMinMax;
uniform vec4 renderTarget2BorderColor;
uniform mat3 renderTarget3Transform;
uniform vec4 renderTarget3UvMinMax;
uniform vec4 renderTarget3BorderColor;
uniform int vfxNumCopies;
uniform float Port_Min_N223;
uniform float Port_Max_N223;
uniform float Port_Input1_N224;
uniform float Port_Import_N209;
uniform vec3 Port_Import_N210;
uniform vec3 Port_Input1_N146;
uniform float Port_Input1_N225;
uniform float Port_Input2_N225;
uniform float Port_Value2_N226;
uniform float Port_Value3_N226;
uniform vec3 Port_Import_N203;
uniform float Port_Input1_N233;
uniform float Port_Multiplier_N147;
uniform float Port_RangeMinA_N152;
uniform float Port_RangeMaxA_N152;
uniform float Port_RangeMinB_N152;
uniform float Port_RangeMaxB_N152;
uniform float Port_Value1_N154;
uniform float Port_Value3_N154;
uniform float Port_Input1_N151;
uniform float Port_RangeMinA_N153;
uniform float Port_RangeMaxA_N153;
uniform float Port_RangeMinB_N153;
uniform float Port_RangeMaxB_N153;
uniform float Port_Value1_N155;
uniform float Port_Value3_N155;
uniform vec3 Port_Input1_N090;
uniform float Port_Input1_N229;
uniform float Port_Multiplier_N156;
uniform float Port_RangeMinA_N161;
uniform float Port_RangeMaxA_N161;
uniform float Port_RangeMinB_N161;
uniform float Port_RangeMaxB_N161;
uniform vec3 Port_Input0_N157;
uniform vec3 Port_Input1_N157;
uniform float Port_Input1_N162;
uniform float Port_RangeMinA_N164;
uniform float Port_RangeMaxA_N164;
uniform float Port_RangeMinB_N164;
uniform float Port_RangeMaxB_N164;
uniform vec3 Port_Input0_N159;
uniform vec3 Port_Input1_N159;
uniform float amount;
uniform float Port_Import_N267;
uniform float Port_Import_N268;
uniform float Port_Import_N132;
uniform float Port_Import_N133;
uniform float Port_Input1_N089;
uniform float Port_RangeMinA_N091;
uniform float Port_RangeMaxA_N091;
uniform float Port_RangeMinB_N091;
uniform float Port_RangeMaxB_N091;
uniform float Port_Input1_N031;
uniform float Port_Min_N030;
uniform float Port_Max_N030;
uniform float Port_Input1_N230;
uniform float Port_Input2_N230;
uniform vec4 Port_Import_N117;
uniform vec4 Port_Import_N118;
uniform float Port_Min_N119;
uniform float Port_Max_N119;
uniform vec3 Port_Input1_N165;
uniform vec3 Port_Input2_N165;
uniform float Port_Import_N105;
uniform vec3 Port_Import_N110;
uniform vec3 Port_Import_N112;
uniform vec3 Port_Import_N306;
uniform float Port_Multiplier_N307;
uniform vec3 Port_Import_N310;
uniform vec2 Port_Input1_N314;
uniform vec2 Port_Scale_N315;
uniform vec2 Port_Input1_N317;
uniform vec2 Port_Scale_N318;
uniform vec2 Port_Input1_N320;
uniform vec2 Port_Scale_N321;
uniform vec3 Port_Input1_N323;
uniform float Port_Import_N142;
uniform float Port_Import_N143;
uniform float Port_Min_N175;
uniform float Port_Max_N175;
uniform mat4 vfxModelMatrix[32];
uniform float overrideTimeDelta;
uniform float Port_Import_N009;
uniform float Port_Import_N010;
uniform float Port_Import_N012;
uniform float Port_Input0_N214;
uniform float Port_Input1_N076;
uniform float Port_Input2_N076;
uniform float Port_Import_N064;
uniform float Port_Input0_N079;
uniform float Port_Input1_N081;
uniform float Port_Input2_N081;
uniform float Port_Import_N017;
uniform float Port_Input2_N024;
uniform vec3 Port_Input1_N067;
uniform float Port_Input1_N072;
uniform vec3 Port_Input2_N072;
uniform float Port_Min_N096;
uniform float Port_Max_N096;
uniform float Port_RangeMinA_N095;
uniform float Port_RangeMaxA_N095;
uniform float Port_RangeMinB_N095;
uniform float Port_RangeMaxB_N095;
uniform vec2 vfxTargetSizeWrite;
uniform int vfxOffsetInstancesWrite;
uniform sc_PointLight_t sc_PointLights[sc_PointLightsCount+1];
uniform sc_DirectionalLight_t sc_DirectionalLights[sc_DirectionalLightsCount+1];
uniform sc_AmbientLight_t sc_AmbientLights[sc_AmbientLightsCount+1];
uniform sc_LightEstimationData_t sc_LightEstimationData;
uniform vec4 sc_EnvmapDiffuseSize;
uniform vec4 sc_EnvmapDiffuseView;
uniform vec4 sc_EnvmapSpecularSize;
uniform vec4 sc_EnvmapSpecularView;
uniform vec3 sc_EnvmapRotation;
uniform float sc_EnvmapExposure;
uniform vec3 sc_Sh[9];
uniform float sc_ShIntensity;
uniform vec4 sc_UniformConstants;
uniform vec4 sc_GeometryInfo;
uniform mat4 sc_ModelViewProjectionMatrixInverseArray[sc_NumStereoViews];
uniform mat4 sc_ViewProjectionMatrixInverseArray[sc_NumStereoViews];
uniform mat4 sc_ModelViewMatrixInverseArray[sc_NumStereoViews];
uniform mat3 sc_ViewNormalMatrixArray[sc_NumStereoViews];
uniform mat3 sc_ViewNormalMatrixInverseArray[sc_NumStereoViews];
uniform mat4 sc_ViewMatrixInverseArray[sc_NumStereoViews];
uniform mat4 sc_PrevFrameViewProjectionMatrixArray[sc_NumStereoViews];
uniform mat4 sc_ModelMatrixInverse;
uniform mat3 sc_NormalMatrixInverse;
uniform mat4 sc_PrevFrameModelMatrix;
uniform mat4 sc_PrevFrameModelMatrixInverse;
uniform vec3 sc_LocalAabbMin;
uniform vec3 sc_LocalAabbMax;
uniform vec3 sc_WorldAabbMin;
uniform vec3 sc_WorldAabbMax;
uniform vec4 sc_WindowToViewportTransform;
uniform vec4 sc_CurrentRenderTargetDims;
uniform float sc_ShadowDensity;
uniform vec4 sc_ShadowColor;
uniform float _sc_GetFramebufferColorInvalidUsageMarker;
uniform float shaderComplexityValue;
uniform vec4 weights2;
uniform int sc_FallbackInstanceID;
uniform float _sc_framebufferFetchMarker;
uniform float strandWidth;
uniform float strandTaper;
uniform vec4 sc_StrandDataMapTextureSize;
uniform float clumpInstanceCount;
uniform float clumpRadius;
uniform float clumpTipScale;
uniform float hairstyleInstanceCount;
uniform float hairstyleNoise;
uniform vec4 sc_ScreenTextureSize;
uniform vec4 sc_ScreenTextureView;
uniform float correctedIntensity;
uniform vec4 intensityTextureSize;
uniform vec4 intensityTextureView;
uniform mat3 intensityTextureTransform;
uniform vec4 intensityTextureUvMinMax;
uniform vec4 intensityTextureBorderColor;
uniform float reflBlurWidth;
uniform float reflBlurMinRough;
uniform float reflBlurMaxRough;
uniform vec4 renderTarget0Size;
uniform vec4 renderTarget0View;
uniform vec4 renderTarget1Size;
uniform vec4 renderTarget1View;
uniform vec4 renderTarget2Size;
uniform vec4 renderTarget2View;
uniform vec4 renderTarget3Size;
uniform vec4 renderTarget3View;
uniform vec3 vfxLocalAabbMin;
uniform vec3 vfxLocalAabbMax;
uniform float vfxCameraAspect;
uniform float vfxCameraNear;
uniform float vfxCameraFar;
uniform vec3 vfxCameraUp;
uniform vec3 vfxCameraForward;
uniform vec3 vfxCameraRight;
uniform mat4 vfxProjectionMatrix;
uniform mat4 vfxProjectionMatrixInverse;
uniform mat4 vfxViewMatrix;
uniform mat4 vfxViewMatrixInverse;
uniform mat4 vfxViewProjectionMatrix;
uniform mat4 vfxViewProjectionMatrixInverse;
uniform int vfxFrame;
uniform vec4 Tweak_N49Size;
uniform vec2 Tweak_N49Depth;
uniform float Port_Import_N053;
uniform vec3 Port_Import_N054;
uniform vec3 Port_Import_N103;
uniform float Port_Import_N075;
uniform float Port_Import_N213;
uniform float Port_Import_N078;
uniform sampler2D renderTarget0;
uniform sampler2DArray renderTarget0ArrSC;
uniform sampler2D renderTarget1;
uniform sampler2DArray renderTarget1ArrSC;
uniform sampler2D renderTarget2;
uniform sampler2DArray renderTarget2ArrSC;
uniform sampler2D renderTarget3;
uniform sampler2DArray renderTarget3ArrSC;
uniform sampler3D Tweak_N49;
out float varClipDistance;
flat out int varStereoViewID;
in vec4 boneData;
in vec3 blendShape0Pos;
in vec3 blendShape0Normal;
in vec3 blendShape1Pos;
in vec3 blendShape1Normal;
in vec3 blendShape2Pos;
in vec3 blendShape2Normal;
in vec3 blendShape3Pos;
in vec3 blendShape4Pos;
in vec3 blendShape5Pos;
in vec4 position;
in vec3 normal;
in vec4 tangent;
in vec2 texture0;
in vec2 texture1;
out vec3 varPos;
out vec3 varNormal;
out vec4 varTangent;
out vec4 varPackedTex;
out vec4 varScreenPos;
out vec2 varScreenTexturePos;
out vec2 varShadowTex;
out float varViewSpaceDepth;
flat out int Interp_Particle_Index;
out vec2 Interp_Particle_Coord;
out vec3 Interp_Particle_Force;
out vec3 Interp_Particle_Position;
out vec3 Interp_Particle_Velocity;
out float Interp_Particle_Life;
out float Interp_Particle_Age;
out float Interp_Particle_Size;
out vec4 Interp_Particle_Color;
out vec4 Interp_Particle_Quaternion;
out float Interp_Particle_Mass;
in vec3 positionNext;
in vec3 positionPrevious;
in vec4 strandProperties;
out vec4 varColor;
ssParticle gParticle;
int sc_GetLocalInstanceID()
{
#ifdef sc_LocalInstanceID
    return sc_LocalInstanceID;
#else
    return 0;
#endif
}
void ssCalculateParticleSeed(inout ssParticle Particle)
{
float l9_0;
if (overrideTimeEnabled==1)
{
l9_0=overrideTimeElapsed;
}
else
{
l9_0=sc_Time.x;
}
Particle.Seed=(Particle.Ratio1D*0.97637898)+0.151235;
Particle.Seed+=(floor(((((l9_0-Particle.SpawnOffset)-0.0)+0.0)+6.0)/3.0)*4.32723);
Particle.Seed=fract(abs(Particle.Seed));
Particle.Seed2000=(vec2(ivec2(Particle.Index1D%400,Particle.Index1D/400))+vec2(1.0))/vec2(399.0);
}
int sc_GetStereoViewIndex()
{
int l9_0;
#if (sc_StereoRenderingMode==0)
{
l9_0=0;
}
#else
{
l9_0=sc_StereoViewID;
}
#endif
return l9_0;
}
int renderTarget0GetStereoViewIndex()
{
int l9_0;
#if (renderTarget0HasSwappedViews)
{
l9_0=1-sc_GetStereoViewIndex();
}
#else
{
l9_0=sc_GetStereoViewIndex();
}
#endif
return l9_0;
}
void sc_SoftwareWrapEarly(inout float uv,int softwareWrapMode)
{
if (softwareWrapMode==1)
{
uv=fract(uv);
}
else
{
if (softwareWrapMode==2)
{
float l9_0=fract(uv);
uv=mix(l9_0,1.0-l9_0,clamp(step(0.25,fract((uv-l9_0)*0.5)),0.0,1.0));
}
}
}
void sc_ClampUV(inout float value,float minValue,float maxValue,bool useClampToBorder,inout float clampToBorderFactor)
{
float l9_0=clamp(value,minValue,maxValue);
float l9_1=step(abs(value-l9_0),9.9999997e-06);
clampToBorderFactor*=(l9_1+((1.0-float(useClampToBorder))*(1.0-l9_1)));
value=l9_0;
}
vec2 sc_TransformUV(vec2 uv,bool useUvTransform,mat3 uvTransform)
{
if (useUvTransform)
{
uv=vec2((uvTransform*vec3(uv,1.0)).xy);
}
return uv;
}
void sc_SoftwareWrapLate(inout float uv,int softwareWrapMode,bool useClampToBorder,inout float clampToBorderFactor)
{
if ((softwareWrapMode==0)||(softwareWrapMode==3))
{
sc_ClampUV(uv,0.0,1.0,useClampToBorder,clampToBorderFactor);
}
}
vec3 sc_SamplingCoordsViewToGlobal(vec2 uv,int renderingLayout,int viewIndex)
{
vec3 l9_0;
if (renderingLayout==0)
{
l9_0=vec3(uv,0.0);
}
else
{
vec3 l9_1;
if (renderingLayout==1)
{
l9_1=vec3(uv.x,(uv.y*0.5)+(0.5-(float(viewIndex)*0.5)),0.0);
}
else
{
l9_1=vec3(uv,float(viewIndex));
}
l9_0=l9_1;
}
return l9_0;
}
vec4 sc_SampleViewLevel(vec2 texSize,vec2 uv,int renderingLayout,int viewIndex,float level_,sampler2D texsmp)
{
return textureLod(texsmp,sc_SamplingCoordsViewToGlobal(uv,renderingLayout,viewIndex).xy,level_);
}
vec4 sc_SampleTextureLevel(vec2 samplerDims,int renderingLayout,int viewIndex,vec2 uv,bool useUvTransform,mat3 uvTransform,ivec2 softwareWrapModes,bool useUvMinMax,vec4 uvMinMax,bool useClampToBorder,vec4 borderColor,float level_,sampler2D texture_sampler_)
{
bool l9_0=useClampToBorder;
bool l9_1=useUvMinMax;
bool l9_2=l9_0&&(!l9_1);
sc_SoftwareWrapEarly(uv.x,softwareWrapModes.x);
sc_SoftwareWrapEarly(uv.y,softwareWrapModes.y);
float l9_3;
if (useUvMinMax)
{
bool l9_4=useClampToBorder;
bool l9_5;
if (l9_4)
{
l9_5=softwareWrapModes.x==3;
}
else
{
l9_5=l9_4;
}
float param_8=1.0;
sc_ClampUV(uv.x,uvMinMax.x,uvMinMax.z,l9_5,param_8);
float l9_6=param_8;
bool l9_7=useClampToBorder;
bool l9_8;
if (l9_7)
{
l9_8=softwareWrapModes.y==3;
}
else
{
l9_8=l9_7;
}
float param_13=l9_6;
sc_ClampUV(uv.y,uvMinMax.y,uvMinMax.w,l9_8,param_13);
l9_3=param_13;
}
else
{
l9_3=1.0;
}
uv=sc_TransformUV(uv,useUvTransform,uvTransform);
float param_20=l9_3;
sc_SoftwareWrapLate(uv.x,softwareWrapModes.x,l9_2,param_20);
sc_SoftwareWrapLate(uv.y,softwareWrapModes.y,l9_2,param_20);
float l9_9=param_20;
vec4 l9_10=sc_SampleViewLevel(samplerDims,uv,renderingLayout,viewIndex,level_,texture_sampler_);
vec4 l9_11;
if (useClampToBorder)
{
l9_11=mix(borderColor,l9_10,vec4(l9_9));
}
else
{
l9_11=l9_10;
}
return l9_11;
}
vec4 sc_InternalTextureLevel(vec3 uv,float level_,sampler2DArray texsmp)
{
vec4 l9_0;
#if (sc_CanUseTextureLod)
{
l9_0=textureLod(texsmp,uv,level_);
}
#else
{
l9_0=vec4(0.0);
}
#endif
return l9_0;
}
vec4 sc_SampleViewLevel(vec2 texSize,vec2 uv,int renderingLayout,int viewIndex,float level_,sampler2DArray texsmp)
{
return sc_InternalTextureLevel(sc_SamplingCoordsViewToGlobal(uv,renderingLayout,viewIndex),level_,texsmp);
}
vec4 sc_SampleTextureLevel(vec2 samplerDims,int renderingLayout,int viewIndex,vec2 uv,bool useUvTransform,mat3 uvTransform,ivec2 softwareWrapModes,bool useUvMinMax,vec4 uvMinMax,bool useClampToBorder,vec4 borderColor,float level_,sampler2DArray texture_sampler_)
{
bool l9_0=useClampToBorder;
bool l9_1=useUvMinMax;
bool l9_2=l9_0&&(!l9_1);
sc_SoftwareWrapEarly(uv.x,softwareWrapModes.x);
sc_SoftwareWrapEarly(uv.y,softwareWrapModes.y);
float l9_3;
if (useUvMinMax)
{
bool l9_4=useClampToBorder;
bool l9_5;
if (l9_4)
{
l9_5=softwareWrapModes.x==3;
}
else
{
l9_5=l9_4;
}
float param_8=1.0;
sc_ClampUV(uv.x,uvMinMax.x,uvMinMax.z,l9_5,param_8);
float l9_6=param_8;
bool l9_7=useClampToBorder;
bool l9_8;
if (l9_7)
{
l9_8=softwareWrapModes.y==3;
}
else
{
l9_8=l9_7;
}
float param_13=l9_6;
sc_ClampUV(uv.y,uvMinMax.y,uvMinMax.w,l9_8,param_13);
l9_3=param_13;
}
else
{
l9_3=1.0;
}
uv=sc_TransformUV(uv,useUvTransform,uvTransform);
float param_20=l9_3;
sc_SoftwareWrapLate(uv.x,softwareWrapModes.x,l9_2,param_20);
sc_SoftwareWrapLate(uv.y,softwareWrapModes.y,l9_2,param_20);
float l9_9=param_20;
vec4 l9_10=sc_SampleViewLevel(samplerDims,uv,renderingLayout,viewIndex,level_,texture_sampler_);
vec4 l9_11;
if (useClampToBorder)
{
l9_11=mix(borderColor,l9_10,vec4(l9_9));
}
else
{
l9_11=l9_10;
}
return l9_11;
}
int renderTarget1GetStereoViewIndex()
{
int l9_0;
#if (renderTarget1HasSwappedViews)
{
l9_0=1-sc_GetStereoViewIndex();
}
#else
{
l9_0=sc_GetStereoViewIndex();
}
#endif
return l9_0;
}
int renderTarget2GetStereoViewIndex()
{
int l9_0;
#if (renderTarget2HasSwappedViews)
{
l9_0=1-sc_GetStereoViewIndex();
}
#else
{
l9_0=sc_GetStereoViewIndex();
}
#endif
return l9_0;
}
int renderTarget3GetStereoViewIndex()
{
int l9_0;
#if (renderTarget3HasSwappedViews)
{
l9_0=1-sc_GetStereoViewIndex();
}
#else
{
l9_0=sc_GetStereoViewIndex();
}
#endif
return l9_0;
}
float DecodeFloat32(vec4 rgba,bool Quantize)
{
if (Quantize)
{
rgba=floor((rgba*255.0)+vec4(0.5))/vec4(255.0);
}
return dot(rgba,vec4(1.0,0.0039215689,1.53787e-05,6.0308629e-08));
}
float DecodeFloat16(vec2 rg,bool Quantize)
{
if (Quantize)
{
rg=floor((rg*255.0)+vec2(0.5))/vec2(255.0);
}
return dot(rg,vec2(1.0,0.0039215689));
}
float DecodeFloat8(float r,bool Quantize)
{
if (Quantize)
{
r=floor((r*255.0)+0.5)/255.0;
}
return r;
}
bool ssDecodeParticle(int InstanceID)
{
gParticle.Position=vec3(0.0);
gParticle.Velocity=vec3(0.0);
gParticle.Color=vec4(0.0);
gParticle.Size=0.0;
gParticle.Age=0.0;
gParticle.Life=0.0;
gParticle.Mass=1.0;
gParticle.Matrix=mat3(vec3(1.0,0.0,0.0),vec3(0.0,1.0,0.0),vec3(0.0,0.0,1.0));
gParticle.Quaternion=vec4(0.0,0.0,0.0,1.0);
int l9_0=InstanceID%6000;
ivec2 l9_1=ivec2(InstanceID%682,InstanceID/682);
float l9_2=float(InstanceID);
vec2 l9_3=vec2(l9_1);
float l9_4=l9_2/5999.0;
ssParticle l9_5=ssParticle(gParticle.Position,gParticle.Velocity,gParticle.Color,gParticle.Size,gParticle.Age,gParticle.Life,gParticle.Mass,gParticle.Matrix,false,gParticle.Quaternion,l9_4*3.0,0.0,gParticle.Seed2000,float(((InstanceID*((InstanceID*1471343)+101146501))+1559861749)&2147483647)*4.6566129e-10,InstanceID,l9_0,(l9_2+0.5)/6000.0,l9_4,float(l9_0)/5999.0,l9_1,(l9_3+vec2(0.5))/vec2(682.0,9.0),l9_3/vec2(681.0,8.0),vec3(0.0),false,float(InstanceID/6000));
ssCalculateParticleSeed(l9_5);
gParticle=l9_5;
int l9_6=InstanceID;
int l9_7=(vfxOffsetInstancesRead+l9_6)*3;
int l9_8=l9_7/vfxTargetWidth;
vec2 l9_9=(vec2(ivec2(l9_7-(l9_8*vfxTargetWidth),l9_8))+vec2(0.5))/vec2(2048.0,vfxTargetSizeRead.y);
vec2 l9_10=l9_9+vec2(0.0);
vec4 l9_11;
#if (renderTarget0Layout==2)
{
l9_11=sc_SampleTextureLevel(renderTarget0Dims.xy,renderTarget0Layout,renderTarget0GetStereoViewIndex(),l9_10,(int(SC_USE_UV_TRANSFORM_renderTarget0)!=0),renderTarget0Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget0,SC_SOFTWARE_WRAP_MODE_V_renderTarget0),(int(SC_USE_UV_MIN_MAX_renderTarget0)!=0),renderTarget0UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget0)!=0),renderTarget0BorderColor,0.0,renderTarget0ArrSC);
}
#else
{
l9_11=sc_SampleTextureLevel(renderTarget0Dims.xy,renderTarget0Layout,renderTarget0GetStereoViewIndex(),l9_10,(int(SC_USE_UV_TRANSFORM_renderTarget0)!=0),renderTarget0Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget0,SC_SOFTWARE_WRAP_MODE_V_renderTarget0),(int(SC_USE_UV_MIN_MAX_renderTarget0)!=0),renderTarget0UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget0)!=0),renderTarget0BorderColor,0.0,renderTarget0);
}
#endif
vec4 l9_12=abs(l9_11);
bool l9_13=dot(l9_12,vec4(1.0))<9.9999997e-06;
bool l9_14;
if (!l9_13)
{
l9_14=!vfxBatchEnable[sc_GetLocalInstanceID()/6000];
}
else
{
l9_14=l9_13;
}
if (l9_14)
{
return false;
}
vec4 l9_15;
#if (renderTarget1Layout==2)
{
l9_15=sc_SampleTextureLevel(renderTarget1Dims.xy,renderTarget1Layout,renderTarget1GetStereoViewIndex(),l9_10,(int(SC_USE_UV_TRANSFORM_renderTarget1)!=0),renderTarget1Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget1,SC_SOFTWARE_WRAP_MODE_V_renderTarget1),(int(SC_USE_UV_MIN_MAX_renderTarget1)!=0),renderTarget1UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget1)!=0),renderTarget1BorderColor,0.0,renderTarget1ArrSC);
}
#else
{
l9_15=sc_SampleTextureLevel(renderTarget1Dims.xy,renderTarget1Layout,renderTarget1GetStereoViewIndex(),l9_10,(int(SC_USE_UV_TRANSFORM_renderTarget1)!=0),renderTarget1Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget1,SC_SOFTWARE_WRAP_MODE_V_renderTarget1),(int(SC_USE_UV_MIN_MAX_renderTarget1)!=0),renderTarget1UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget1)!=0),renderTarget1BorderColor,0.0,renderTarget1);
}
#endif
vec4 l9_16;
#if (renderTarget2Layout==2)
{
l9_16=sc_SampleTextureLevel(renderTarget2Dims.xy,renderTarget2Layout,renderTarget2GetStereoViewIndex(),l9_10,(int(SC_USE_UV_TRANSFORM_renderTarget2)!=0),renderTarget2Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget2,SC_SOFTWARE_WRAP_MODE_V_renderTarget2),(int(SC_USE_UV_MIN_MAX_renderTarget2)!=0),renderTarget2UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget2)!=0),renderTarget2BorderColor,0.0,renderTarget2ArrSC);
}
#else
{
l9_16=sc_SampleTextureLevel(renderTarget2Dims.xy,renderTarget2Layout,renderTarget2GetStereoViewIndex(),l9_10,(int(SC_USE_UV_TRANSFORM_renderTarget2)!=0),renderTarget2Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget2,SC_SOFTWARE_WRAP_MODE_V_renderTarget2),(int(SC_USE_UV_MIN_MAX_renderTarget2)!=0),renderTarget2UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget2)!=0),renderTarget2BorderColor,0.0,renderTarget2);
}
#endif
vec4 l9_17;
#if (renderTarget3Layout==2)
{
l9_17=sc_SampleTextureLevel(renderTarget3Dims.xy,renderTarget3Layout,renderTarget3GetStereoViewIndex(),l9_10,(int(SC_USE_UV_TRANSFORM_renderTarget3)!=0),renderTarget3Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget3,SC_SOFTWARE_WRAP_MODE_V_renderTarget3),(int(SC_USE_UV_MIN_MAX_renderTarget3)!=0),renderTarget3UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget3)!=0),renderTarget3BorderColor,0.0,renderTarget3ArrSC);
}
#else
{
l9_17=sc_SampleTextureLevel(renderTarget3Dims.xy,renderTarget3Layout,renderTarget3GetStereoViewIndex(),l9_10,(int(SC_USE_UV_TRANSFORM_renderTarget3)!=0),renderTarget3Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget3,SC_SOFTWARE_WRAP_MODE_V_renderTarget3),(int(SC_USE_UV_MIN_MAX_renderTarget3)!=0),renderTarget3UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget3)!=0),renderTarget3BorderColor,0.0,renderTarget3);
}
#endif
gParticle.Position.x=(-1000.0)+(((DecodeFloat32(l9_11,true)-0.0)*(1000.0-(-1000.0)))/(0.99998999-0.0));
gParticle.Position.y=(-1000.0)+(((DecodeFloat32(l9_15,true)-0.0)*(1000.0-(-1000.0)))/(0.99998999-0.0));
gParticle.Position.z=(-1000.0)+(((DecodeFloat32(l9_16,true)-0.0)*(1000.0-(-1000.0)))/(0.99998999-0.0));
gParticle.Velocity.x=(-1000.0)+(((DecodeFloat32(l9_17,true)-0.0)*(1000.0-(-1000.0)))/(0.99998999-0.0));
vec2 l9_18=l9_9+vec2(0.00048828125,0.0);
vec4 l9_19;
#if (renderTarget0Layout==2)
{
l9_19=sc_SampleTextureLevel(renderTarget0Dims.xy,renderTarget0Layout,renderTarget0GetStereoViewIndex(),l9_18,(int(SC_USE_UV_TRANSFORM_renderTarget0)!=0),renderTarget0Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget0,SC_SOFTWARE_WRAP_MODE_V_renderTarget0),(int(SC_USE_UV_MIN_MAX_renderTarget0)!=0),renderTarget0UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget0)!=0),renderTarget0BorderColor,0.0,renderTarget0ArrSC);
}
#else
{
l9_19=sc_SampleTextureLevel(renderTarget0Dims.xy,renderTarget0Layout,renderTarget0GetStereoViewIndex(),l9_18,(int(SC_USE_UV_TRANSFORM_renderTarget0)!=0),renderTarget0Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget0,SC_SOFTWARE_WRAP_MODE_V_renderTarget0),(int(SC_USE_UV_MIN_MAX_renderTarget0)!=0),renderTarget0UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget0)!=0),renderTarget0BorderColor,0.0,renderTarget0);
}
#endif
vec4 l9_20;
#if (renderTarget1Layout==2)
{
l9_20=sc_SampleTextureLevel(renderTarget1Dims.xy,renderTarget1Layout,renderTarget1GetStereoViewIndex(),l9_18,(int(SC_USE_UV_TRANSFORM_renderTarget1)!=0),renderTarget1Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget1,SC_SOFTWARE_WRAP_MODE_V_renderTarget1),(int(SC_USE_UV_MIN_MAX_renderTarget1)!=0),renderTarget1UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget1)!=0),renderTarget1BorderColor,0.0,renderTarget1ArrSC);
}
#else
{
l9_20=sc_SampleTextureLevel(renderTarget1Dims.xy,renderTarget1Layout,renderTarget1GetStereoViewIndex(),l9_18,(int(SC_USE_UV_TRANSFORM_renderTarget1)!=0),renderTarget1Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget1,SC_SOFTWARE_WRAP_MODE_V_renderTarget1),(int(SC_USE_UV_MIN_MAX_renderTarget1)!=0),renderTarget1UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget1)!=0),renderTarget1BorderColor,0.0,renderTarget1);
}
#endif
vec4 l9_21;
#if (renderTarget2Layout==2)
{
l9_21=sc_SampleTextureLevel(renderTarget2Dims.xy,renderTarget2Layout,renderTarget2GetStereoViewIndex(),l9_18,(int(SC_USE_UV_TRANSFORM_renderTarget2)!=0),renderTarget2Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget2,SC_SOFTWARE_WRAP_MODE_V_renderTarget2),(int(SC_USE_UV_MIN_MAX_renderTarget2)!=0),renderTarget2UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget2)!=0),renderTarget2BorderColor,0.0,renderTarget2ArrSC);
}
#else
{
l9_21=sc_SampleTextureLevel(renderTarget2Dims.xy,renderTarget2Layout,renderTarget2GetStereoViewIndex(),l9_18,(int(SC_USE_UV_TRANSFORM_renderTarget2)!=0),renderTarget2Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget2,SC_SOFTWARE_WRAP_MODE_V_renderTarget2),(int(SC_USE_UV_MIN_MAX_renderTarget2)!=0),renderTarget2UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget2)!=0),renderTarget2BorderColor,0.0,renderTarget2);
}
#endif
vec4 l9_22;
#if (renderTarget3Layout==2)
{
l9_22=sc_SampleTextureLevel(renderTarget3Dims.xy,renderTarget3Layout,renderTarget3GetStereoViewIndex(),l9_18,(int(SC_USE_UV_TRANSFORM_renderTarget3)!=0),renderTarget3Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget3,SC_SOFTWARE_WRAP_MODE_V_renderTarget3),(int(SC_USE_UV_MIN_MAX_renderTarget3)!=0),renderTarget3UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget3)!=0),renderTarget3BorderColor,0.0,renderTarget3ArrSC);
}
#else
{
l9_22=sc_SampleTextureLevel(renderTarget3Dims.xy,renderTarget3Layout,renderTarget3GetStereoViewIndex(),l9_18,(int(SC_USE_UV_TRANSFORM_renderTarget3)!=0),renderTarget3Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget3,SC_SOFTWARE_WRAP_MODE_V_renderTarget3),(int(SC_USE_UV_MIN_MAX_renderTarget3)!=0),renderTarget3UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget3)!=0),renderTarget3BorderColor,0.0,renderTarget3);
}
#endif
gParticle.Velocity.y=(-1000.0)+(((DecodeFloat32(l9_19,true)-0.0)*(1000.0-(-1000.0)))/(0.99998999-0.0));
gParticle.Velocity.z=(-1000.0)+(((DecodeFloat32(l9_20,true)-0.0)*(1000.0-(-1000.0)))/(0.99998999-0.0));
gParticle.Life=0.0+(((DecodeFloat32(l9_21,true)-0.0)*(3.0-0.0))/(0.99998999-0.0));
gParticle.Age=0.0+(((DecodeFloat32(l9_22,true)-0.0)*(3.0-0.0))/(0.99998999-0.0));
vec2 l9_23=l9_9+vec2(0.0009765625,0.0);
vec4 l9_24;
#if (renderTarget0Layout==2)
{
l9_24=sc_SampleTextureLevel(renderTarget0Dims.xy,renderTarget0Layout,renderTarget0GetStereoViewIndex(),l9_23,(int(SC_USE_UV_TRANSFORM_renderTarget0)!=0),renderTarget0Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget0,SC_SOFTWARE_WRAP_MODE_V_renderTarget0),(int(SC_USE_UV_MIN_MAX_renderTarget0)!=0),renderTarget0UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget0)!=0),renderTarget0BorderColor,0.0,renderTarget0ArrSC);
}
#else
{
l9_24=sc_SampleTextureLevel(renderTarget0Dims.xy,renderTarget0Layout,renderTarget0GetStereoViewIndex(),l9_23,(int(SC_USE_UV_TRANSFORM_renderTarget0)!=0),renderTarget0Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget0,SC_SOFTWARE_WRAP_MODE_V_renderTarget0),(int(SC_USE_UV_MIN_MAX_renderTarget0)!=0),renderTarget0UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget0)!=0),renderTarget0BorderColor,0.0,renderTarget0);
}
#endif
vec4 l9_25;
#if (renderTarget1Layout==2)
{
l9_25=sc_SampleTextureLevel(renderTarget1Dims.xy,renderTarget1Layout,renderTarget1GetStereoViewIndex(),l9_23,(int(SC_USE_UV_TRANSFORM_renderTarget1)!=0),renderTarget1Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget1,SC_SOFTWARE_WRAP_MODE_V_renderTarget1),(int(SC_USE_UV_MIN_MAX_renderTarget1)!=0),renderTarget1UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget1)!=0),renderTarget1BorderColor,0.0,renderTarget1ArrSC);
}
#else
{
l9_25=sc_SampleTextureLevel(renderTarget1Dims.xy,renderTarget1Layout,renderTarget1GetStereoViewIndex(),l9_23,(int(SC_USE_UV_TRANSFORM_renderTarget1)!=0),renderTarget1Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget1,SC_SOFTWARE_WRAP_MODE_V_renderTarget1),(int(SC_USE_UV_MIN_MAX_renderTarget1)!=0),renderTarget1UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget1)!=0),renderTarget1BorderColor,0.0,renderTarget1);
}
#endif
vec4 l9_26;
#if (renderTarget2Layout==2)
{
l9_26=sc_SampleTextureLevel(renderTarget2Dims.xy,renderTarget2Layout,renderTarget2GetStereoViewIndex(),l9_23,(int(SC_USE_UV_TRANSFORM_renderTarget2)!=0),renderTarget2Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget2,SC_SOFTWARE_WRAP_MODE_V_renderTarget2),(int(SC_USE_UV_MIN_MAX_renderTarget2)!=0),renderTarget2UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget2)!=0),renderTarget2BorderColor,0.0,renderTarget2ArrSC);
}
#else
{
l9_26=sc_SampleTextureLevel(renderTarget2Dims.xy,renderTarget2Layout,renderTarget2GetStereoViewIndex(),l9_23,(int(SC_USE_UV_TRANSFORM_renderTarget2)!=0),renderTarget2Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget2,SC_SOFTWARE_WRAP_MODE_V_renderTarget2),(int(SC_USE_UV_MIN_MAX_renderTarget2)!=0),renderTarget2UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget2)!=0),renderTarget2BorderColor,0.0,renderTarget2);
}
#endif
vec4 l9_27;
#if (renderTarget3Layout==2)
{
l9_27=sc_SampleTextureLevel(renderTarget3Dims.xy,renderTarget3Layout,renderTarget3GetStereoViewIndex(),l9_23,(int(SC_USE_UV_TRANSFORM_renderTarget3)!=0),renderTarget3Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget3,SC_SOFTWARE_WRAP_MODE_V_renderTarget3),(int(SC_USE_UV_MIN_MAX_renderTarget3)!=0),renderTarget3UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget3)!=0),renderTarget3BorderColor,0.0,renderTarget3ArrSC);
}
#else
{
l9_27=sc_SampleTextureLevel(renderTarget3Dims.xy,renderTarget3Layout,renderTarget3GetStereoViewIndex(),l9_23,(int(SC_USE_UV_TRANSFORM_renderTarget3)!=0),renderTarget3Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget3,SC_SOFTWARE_WRAP_MODE_V_renderTarget3),(int(SC_USE_UV_MIN_MAX_renderTarget3)!=0),renderTarget3UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget3)!=0),renderTarget3BorderColor,0.0,renderTarget3);
}
#endif
gParticle.Size=0.0+(((DecodeFloat16(vec2(l9_24.xy),true)-0.0)*(100.0-0.0))/(0.99998999-0.0));
gParticle.Quaternion.x=(-1.0)+(((DecodeFloat16(vec2(l9_24.zw),true)-0.0)*(1.0-(-1.0)))/(0.99998999-0.0));
gParticle.Quaternion.y=(-1.0)+(((DecodeFloat16(vec2(l9_25.xy),true)-0.0)*(1.0-(-1.0)))/(0.99998999-0.0));
gParticle.Quaternion.z=(-1.0)+(((DecodeFloat16(vec2(l9_25.zw),true)-0.0)*(1.0-(-1.0)))/(0.99998999-0.0));
gParticle.Quaternion.w=(-1.0)+(((DecodeFloat16(vec2(l9_26.xy),true)-0.0)*(1.0-(-1.0)))/(0.99998999-0.0));
gParticle.Mass=0.0+(((DecodeFloat16(vec2(l9_26.zw),true)-0.0)*(100.0-0.0))/(0.99998999-0.0));
gParticle.Color.x=0.0+(((DecodeFloat8(l9_27.x,true)-0.0)*(1.00001-0.0))/(1.0-0.0));
gParticle.Color.y=0.0+(((DecodeFloat8(l9_27.y,true)-0.0)*(1.00001-0.0))/(1.0-0.0));
gParticle.Color.z=0.0+(((DecodeFloat8(l9_27.z,true)-0.0)*(1.00001-0.0))/(1.0-0.0));
gParticle.Color.w=0.0+(((DecodeFloat8(l9_27.w,true)-0.0)*(1.00001-0.0))/(1.0-0.0));
vec4 l9_28=normalize(gParticle.Quaternion.yzwx);
float l9_29=l9_28.x;
float l9_30=l9_29*l9_29;
float l9_31=l9_28.y;
float l9_32=l9_31*l9_31;
float l9_33=l9_28.z;
float l9_34=l9_33*l9_33;
float l9_35=l9_29*l9_33;
float l9_36=l9_29*l9_31;
float l9_37=l9_31*l9_33;
float l9_38=l9_28.w;
float l9_39=l9_38*l9_29;
float l9_40=l9_38*l9_31;
float l9_41=l9_38*l9_33;
gParticle.Matrix=mat3(vec3(1.0-(2.0*(l9_32+l9_34)),2.0*(l9_36+l9_41),2.0*(l9_35-l9_40)),vec3(2.0*(l9_36-l9_41),1.0-(2.0*(l9_30+l9_34)),2.0*(l9_37+l9_39)),vec3(2.0*(l9_35+l9_40),2.0*(l9_37-l9_39),1.0-(2.0*(l9_30+l9_32))));
gParticle.Velocity=floor((gParticle.Velocity*2000.0)+vec3(0.5))*0.00050000002;
gParticle.Position=floor((gParticle.Position*2000.0)+vec3(0.5))*0.00050000002;
gParticle.Color=floor((gParticle.Color*2000.0)+vec4(0.5))*0.00050000002;
gParticle.Size=floor((gParticle.Size*2000.0)+0.5)*0.00050000002;
gParticle.Mass=floor((gParticle.Mass*2000.0)+0.5)*0.00050000002;
gParticle.Life=floor((gParticle.Life*2000.0)+0.5)*0.00050000002;
return true;
}
vec4 ssRandVec4(int seed)
{
return vec4(float(((seed*((seed*1471343)+101146501))+1559861749)&2147483647)*4.6566129e-10,float((((seed*1399)*((seed*2058408857)+101146501))+1559861749)&2147483647)*4.6566129e-10,float((((seed*7177)*((seed*1969894119)+101146501))+1559861749)&2147483647)*4.6566129e-10,float((((seed*18919)*((seed*2066534441)+101146501))+1559861749)&2147483647)*4.6566129e-10);
}
vec3 ssRandVec3(int seed)
{
return vec3(float(((seed*((seed*1471343)+101146501))+1559861749)&2147483647)*4.6566129e-10,float((((seed*1399)*((seed*2058408857)+101146501))+1559861749)&2147483647)*4.6566129e-10,float((((seed*7177)*((seed*1969894119)+101146501))+1559861749)&2147483647)*4.6566129e-10);
}
vec2 ssRandVec2(int seed)
{
return vec2(float(((seed*((seed*1471343)+101146501))+1559861749)&2147483647)*4.6566129e-10,float((((seed*1399)*((seed*2058408857)+101146501))+1559861749)&2147483647)*4.6566129e-10);
}
vec4 ssGetParticleRandom(int Dimension,bool UseTime,bool UseNodeID,bool UseParticleID,float NodeID,ssParticle Particle,float ExtraSeed,float Time)
{
vec4 l9_0;
if (UseTime)
{
vec4 l9_1=vec4(0.0);
l9_1.x=floor(fract(Time)*1000.0);
l9_0=l9_1;
}
else
{
l9_0=vec4(0.0);
}
vec4 l9_2;
if (UseParticleID)
{
vec4 l9_3=l9_0;
l9_3.y=float(Particle.Index1D^((Particle.Index1D*15299)+Particle.Index1D));
l9_2=l9_3;
}
else
{
l9_2=l9_0;
}
vec4 l9_4;
if (UseNodeID)
{
vec4 l9_5=l9_2;
l9_5.z=NodeID;
l9_4=l9_5;
}
else
{
l9_4=l9_2;
}
float l9_6=ExtraSeed;
int l9_7=(((int(l9_4.x)*15299)^(int(l9_4.y)*30133))^(int(l9_4.z)*17539))^(int(l9_6*1000.0)*12113);
vec4 l9_8;
if (Dimension==1)
{
vec4 l9_9=vec4(0.0);
l9_9.x=float(((l9_7*((l9_7*1471343)+101146501))+1559861749)&2147483647)*4.6566129e-10;
l9_8=l9_9;
}
else
{
vec4 l9_10;
if (Dimension==2)
{
vec2 l9_11=ssRandVec2(l9_7);
l9_10=vec4(l9_11.x,l9_11.y,vec4(0.0).z,vec4(0.0).w);
}
else
{
vec4 l9_12;
if (Dimension==3)
{
vec3 l9_13=ssRandVec3(l9_7);
l9_12=vec4(l9_13.x,l9_13.y,l9_13.z,vec4(0.0).w);
}
else
{
l9_12=ssRandVec4(l9_7);
}
l9_10=l9_12;
}
l9_8=l9_10;
}
return l9_8;
}
void Node222_Particle_Random(vec3 Min,vec3 Max,out vec3 Random,ssGlobals Globals)
{
Random=mix(Min,Max,ssGetParticleRandom(3,false,true,true,222.0,gParticle,0.0,Globals.gTimeElapsed).xyz);
}
void Node223_Particle_Random(float Min,float Max,out float Random,ssGlobals Globals)
{
Random=mix(Min,Max,ssGetParticleRandom(1,false,true,true,223.0,gParticle,0.0,Globals.gTimeElapsed).x);
}
void Node225_Conditional(float Input0,float Input1,float Input2,out float Output,ssGlobals Globals)
{
float param_2;
Node223_Particle_Random(Port_Min_N223,Port_Max_N223,param_2,Globals);
Input0=float(param_2>Port_Input1_N224);
if ((Input0*1.0)!=0.0)
{
Output=Input1;
}
else
{
Output=Input2;
}
}
vec4 sc_InternalTextureLevel(vec3 uv,float level_,sampler3D texsmp)
{
vec4 l9_0;
#if (sc_CanUseTextureLod)
{
l9_0=textureLod(texsmp,uv,level_);
}
#else
{
l9_0=vec4(0.0);
}
#endif
return l9_0;
}
void Node91_Remap(vec4 ValueIn,out vec4 ValueOut,float RangeMinA,float RangeMaxA,float RangeMinB,float RangeMaxB,ssGlobals Globals)
{
ValueOut=(((ValueIn-vec4(RangeMinA))/vec4(RangeMaxA-RangeMinA))*(RangeMaxB-RangeMinB))+vec4(RangeMinB);
vec4 l9_0;
if (RangeMaxB>RangeMinB)
{
l9_0=clamp(ValueOut,vec4(RangeMinB),vec4(RangeMaxB));
}
else
{
l9_0=clamp(ValueOut,vec4(RangeMaxB),vec4(RangeMinB));
}
ValueOut=l9_0;
}
float snoise(vec2 v)
{
#if ((SC_DEVICE_CLASS>=2)&&SC_GL_FRAGMENT_PRECISION_HIGH)
{
vec2 l9_0=floor(v+vec2(dot(v,vec2(0.36602542))));
vec2 l9_1=(v-l9_0)+vec2(dot(l9_0,vec2(0.21132487)));
float l9_2=l9_1.x;
float l9_3=l9_1.y;
bvec2 l9_4=bvec2(l9_2>l9_3);
vec2 l9_5=vec2(l9_4.x ? vec2(1.0,0.0).x : vec2(0.0,1.0).x,l9_4.y ? vec2(1.0,0.0).y : vec2(0.0,1.0).y);
vec2 l9_6=(l9_1+vec2(0.21132487))-l9_5;
vec2 l9_7=l9_1+vec2(-0.57735026);
vec2 l9_8=l9_0-(floor(l9_0*0.0034602077)*289.0);
vec3 l9_9=vec3(l9_8.y)+vec3(0.0,l9_5.y,1.0);
vec3 l9_10=((l9_9*34.0)+vec3(1.0))*l9_9;
vec3 l9_11=((l9_10-(floor(l9_10*0.0034602077)*289.0))+vec3(l9_8.x))+vec3(0.0,l9_5.x,1.0);
vec3 l9_12=((l9_11*34.0)+vec3(1.0))*l9_11;
vec3 l9_13=max(vec3(0.5)-vec3(dot(l9_1,l9_1),dot(l9_6,l9_6),dot(l9_7,l9_7)),vec3(0.0));
vec3 l9_14=l9_13*l9_13;
vec3 l9_15=(fract((l9_12-(floor(l9_12*0.0034602077)*289.0))*vec3(0.024390243))*2.0)-vec3(1.0);
vec3 l9_16=abs(l9_15)-vec3(0.5);
vec3 l9_17=l9_15-floor(l9_15+vec3(0.5));
vec3 l9_18=vec3(0.0);
l9_18.x=(l9_17.x*l9_2)+(l9_16.x*l9_3);
vec2 l9_19=(l9_17.yz*vec2(l9_6.x,l9_7.x))+(l9_16.yz*vec2(l9_6.y,l9_7.y));
return 130.0*dot((l9_14*l9_14)*(vec3(1.7928429)-(((l9_17*l9_17)+(l9_16*l9_16))*0.85373473)),vec3(l9_18.x,l9_19.x,l9_19.y));
}
#else
{
return 0.0;
}
#endif
}
void SpawnParticle(ssGlobals Globals)
{
ssCalculateParticleSeed(gParticle);
float l9_1=floor(sqrt(6000.0*float(vfxNumCopies+1)));
int l9_2=int(l9_1);
gParticle.Position=(vec3(((float(gParticle.Index1D-((gParticle.Index1D/l9_2)*l9_2))/l9_1)*2.0)-1.0,((float(gParticle.Index1D/l9_2)/l9_1)*2.0)-1.0,0.0)*20.0)+vec3(1.0,1.0,0.0);
gParticle.Velocity=vec3(0.0);
gParticle.Color=vec4(1.0);
gParticle.Age=0.0;
gParticle.Life=3.0;
gParticle.Size=1.0;
gParticle.Mass=1.0;
gParticle.Matrix=mat3(vec3(1.0,0.0,0.0),vec3(0.0,1.0,0.0),vec3(0.0,0.0,1.0));
gParticle.Quaternion=vec4(0.0,0.0,0.0,1.0);
vec3 l9_3=vec3(Port_Import_N209,Port_Import_N210.yz)*Port_Input1_N146;
vec3 param_2;
Node222_Particle_Random(l9_3,Port_Import_N210,param_2,Globals);
vec3 l9_4=param_2;
float param_7;
Node225_Conditional(1.0,Port_Input1_N225,Port_Input2_N225,param_7,Globals);
float l9_5=param_7;
vec3 l9_6;
Node222_Particle_Random(l9_3,Port_Import_N210,l9_6,Globals);
float l9_7;
Node225_Conditional(1.0,Port_Input1_N225,Port_Input2_N225,l9_7,Globals);
vec3 l9_8;
if ((float(((l9_6*vec3(l9_7,Port_Value2_N226,Port_Value3_N226))+Port_Import_N203).x<=Port_Input1_N233)*1.0)!=0.0)
{
float l9_9=(((sin(Globals.gTimeElapsedShifted*Port_Multiplier_N147)-Port_RangeMinA_N152)/(Port_RangeMaxA_N152-Port_RangeMinA_N152))*(Port_RangeMaxB_N152-Port_RangeMinB_N152))+Port_RangeMinB_N152;
float l9_10;
if (Port_RangeMaxB_N152>Port_RangeMinB_N152)
{
l9_10=clamp(l9_9,Port_RangeMinB_N152,Port_RangeMaxB_N152);
}
else
{
l9_10=clamp(l9_9,Port_RangeMaxB_N152,Port_RangeMinB_N152);
}
l9_8=vec3(Port_Value1_N154,l9_10,Port_Value3_N154);
}
else
{
float l9_11=(((sin((Globals.gTimeElapsedShifted*Port_Multiplier_N147)+Port_Input1_N151)-Port_RangeMinA_N153)/(Port_RangeMaxA_N153-Port_RangeMinA_N153))*(Port_RangeMaxB_N153-Port_RangeMinB_N153))+Port_RangeMinB_N153;
float l9_12;
if (Port_RangeMaxB_N153>Port_RangeMinB_N153)
{
l9_12=clamp(l9_11,Port_RangeMinB_N153,Port_RangeMaxB_N153);
}
else
{
l9_12=clamp(l9_11,Port_RangeMaxB_N153,Port_RangeMinB_N153);
}
l9_8=vec3(Port_Value1_N155,l9_12,Port_Value3_N155)+Port_Input1_N090;
}
gParticle.Position=((l9_4*vec3(l9_5,Port_Value2_N226,Port_Value3_N226))+Port_Import_N203)+l9_8;
gParticle.Size=mix(Port_Import_N267,Port_Import_N268,ssGetParticleRandom(1,false,true,true,269.0,gParticle,0.0,Globals.gTimeElapsed).x);
gParticle.Mass=mix(Port_Import_N132,Port_Import_N133,ssGetParticleRandom(1,false,true,true,134.0,gParticle,0.0,Globals.gTimeElapsed).x);
gParticle.Mass=max(9.9999997e-06,gParticle.Mass);
vec4 param_10;
Node91_Remap(sc_InternalTextureLevel(gParticle.Position*vec3(Port_Input1_N089),0.0,Tweak_N49),param_10,Port_RangeMinA_N091,Port_RangeMaxA_N091,Port_RangeMinB_N091,Port_RangeMaxB_N091,Globals);
vec4 l9_13=param_10;
vec4 l9_14=ssGetParticleRandom(1,false,true,true,30.0,gParticle,0.0,Globals.gTimeElapsed);
float l9_15;
if ((float(gParticle.Position.x<=Port_Input1_N229)*1.0)!=0.0)
{
l9_15=Port_Input1_N230;
}
else
{
l9_15=Port_Input2_N230;
}
vec4 l9_16=vec4(l9_15);
vec3 l9_17;
if ((float(gParticle.Position.x<=Port_Input1_N229)*1.0)!=0.0)
{
float l9_18=(((sin(Globals.gTimeElapsedShifted*Port_Multiplier_N156)-Port_RangeMinA_N161)/(Port_RangeMaxA_N161-Port_RangeMinA_N161))*(Port_RangeMaxB_N161-Port_RangeMinB_N161))+Port_RangeMinB_N161;
float l9_19;
if (Port_RangeMaxB_N161>Port_RangeMinB_N161)
{
l9_19=clamp(l9_18,Port_RangeMinB_N161,Port_RangeMaxB_N161);
}
else
{
l9_19=clamp(l9_18,Port_RangeMaxB_N161,Port_RangeMinB_N161);
}
l9_17=mix(Port_Input0_N157,Port_Input1_N157,vec3(l9_19));
}
else
{
float l9_20=(((sin((Globals.gTimeElapsedShifted*Port_Multiplier_N156)+Port_Input1_N162)-Port_RangeMinA_N164)/(Port_RangeMaxA_N164-Port_RangeMinA_N164))*(Port_RangeMaxB_N164-Port_RangeMinB_N164))+Port_RangeMinB_N164;
float l9_21;
if (Port_RangeMaxB_N164>Port_RangeMinB_N164)
{
l9_21=clamp(l9_20,Port_RangeMinB_N164,Port_RangeMaxB_N164);
}
else
{
l9_21=clamp(l9_20,Port_RangeMaxB_N164,Port_RangeMinB_N164);
}
l9_17=mix(Port_Input0_N159,Port_Input1_N159,vec3(l9_21));
}
vec3 l9_22=gParticle.Position;
vec3 l9_23=l9_17-l9_22;
float l9_24=dot(l9_23,l9_23);
float l9_25;
if (l9_24>0.0)
{
l9_25=1.0/sqrt(l9_24);
}
else
{
l9_25=0.0;
}
gParticle.Force+=(vec3((((l9_13*vec4(Port_Input1_N031))*vec4(mix(Port_Min_N030,Port_Max_N030,l9_14.x)))*l9_16).x)*(l9_23*l9_25));
gParticle.Color=mix(Port_Import_N117,Port_Import_N118,vec4(mix(Port_Min_N119,Port_Max_N119,ssGetParticleRandom(1,false,true,true,119.0,gParticle,0.0,Globals.gTimeElapsed).x)));
vec3 l9_26;
if ((float(gParticle.Position.x<=Port_Input1_N229)*1.0)!=0.0)
{
l9_26=Port_Input1_N165;
}
else
{
l9_26=Port_Input2_N165;
}
float l9_27=dot(l9_26,l9_26);
float l9_28;
if (l9_27>0.0)
{
l9_28=1.0/sqrt(l9_27);
}
else
{
l9_28=0.0;
}
gParticle.Force+=((l9_26*l9_28)*vec3(Port_Import_N105));
vec3 l9_29=((gParticle.Position+Port_Import_N112)+(Port_Import_N306*vec3(Globals.gTimeElapsedShifted*Port_Multiplier_N307)))*(vec3(1.0)/Port_Import_N310);
vec2 l9_30=vec2(l9_29.xy)+Port_Input1_N314;
vec2 l9_31=vec2(l9_29.yz)+Port_Input1_N317;
vec2 l9_32=vec2(l9_29.zx)+Port_Input1_N320;
gParticle.Force+=(Port_Import_N110*((vec3(floor(((snoise(vec2(floor(l9_30.x*10000.0)*9.9999997e-05,floor(l9_30.y*10000.0)*9.9999997e-05)*(Port_Scale_N315*0.5))*0.5)+0.5)*10000.0)*9.9999997e-05,floor(((snoise(vec2(floor(l9_31.x*10000.0)*9.9999997e-05,floor(l9_31.y*10000.0)*9.9999997e-05)*(Port_Scale_N318*0.5))*0.5)+0.5)*10000.0)*9.9999997e-05,floor(((snoise(vec2(floor(l9_32.x*10000.0)*9.9999997e-05,floor(l9_32.y*10000.0)*9.9999997e-05)*(Port_Scale_N321*0.5))*0.5)+0.5)*10000.0)*9.9999997e-05)*Port_Input1_N323)-vec3(1.0)));
gParticle.Life=mix(Port_Import_N142,Port_Import_N143,ssGetParticleRandom(1,false,true,true,144.0,gParticle,0.0,Globals.gTimeElapsed).x);
gParticle.Life=clamp(gParticle.Life,0.1,3.0);
if ((step(amount,mix(Port_Min_N175,Port_Max_N175,ssGetParticleRandom(1,false,true,true,175.0,gParticle,0.0,Globals.gTimeElapsed).x))*1.0)!=0.0)
{
gParticle.Dead=true;
}
gParticle.Velocity+=((gParticle.Force/vec3(gParticle.Mass))*0.033330001);
gParticle.Force=vec3(0.0);
gParticle.Position=(vfxModelMatrix[sc_GetLocalInstanceID()/6000]*vec4(gParticle.Position,1.0)).xyz;
int l9_33=sc_GetLocalInstanceID()/6000;
gParticle.Velocity=mat3(vfxModelMatrix[l9_33][0].xyz,vfxModelMatrix[l9_33][1].xyz,vfxModelMatrix[l9_33][2].xyz)*gParticle.Velocity;
int l9_34=sc_GetLocalInstanceID()/6000;
gParticle.Force=mat3(vfxModelMatrix[l9_34][0].xyz,vfxModelMatrix[l9_34][1].xyz,vfxModelMatrix[l9_34][2].xyz)*gParticle.Force;
int l9_35=sc_GetLocalInstanceID()/6000;
gParticle.Matrix=mat3(vfxModelMatrix[l9_35][0].xyz,vfxModelMatrix[l9_35][1].xyz,vfxModelMatrix[l9_35][2].xyz)*gParticle.Matrix;
gParticle.Size=max(length(vfxModelMatrix[sc_GetLocalInstanceID()/6000][0].xyz),max(length(vfxModelMatrix[sc_GetLocalInstanceID()/6000][1].xyz),length(vfxModelMatrix[sc_GetLocalInstanceID()/6000][2].xyz)))*gParticle.Size;
}
void sc_SetClipDistancePlatform(float dstClipDistance)
{
    #if sc_StereoRenderingMode==sc_StereoRendering_InstancedClipped&&sc_StereoRendering_IsClipDistanceEnabled
        gl_ClipDistance[0]=dstClipDistance;
    #endif
}
void sc_SetClipDistance(float dstClipDistance)
{
#if (sc_StereoRendering_IsClipDistanceEnabled==1)
{
sc_SetClipDistancePlatform(dstClipDistance);
}
#else
{
varClipDistance=dstClipDistance;
}
#endif
}
void sc_SetClipDistance(vec4 clipPosition)
{
#if (sc_StereoRenderingMode==1)
{
sc_SetClipDistance(dot(clipPosition,sc_StereoClipPlanes[sc_StereoViewID]));
}
#endif
}
void sc_SetClipPosition(vec4 clipPosition)
{
#if (sc_StereoRenderingMode>0)
{
varStereoViewID=sc_StereoViewID;
}
#endif
sc_SetClipDistance(clipPosition);
gl_Position=clipPosition;
}
vec4 matrixToQuaternion(mat3 m)
{
float l9_0=m[0].x;
float l9_1=m[1].y;
float l9_2=m[2].z;
float l9_3=(l9_0-l9_1)-l9_2;
float l9_4=m[1].y;
float l9_5=m[0].x;
float l9_6=m[2].z;
float l9_7=(l9_4-l9_5)-l9_6;
float l9_8=m[2].z;
float l9_9=m[0].x;
float l9_10=m[1].y;
float l9_11=(l9_8-l9_9)-l9_10;
float l9_12=m[0].x;
float l9_13=m[1].y;
float l9_14=m[2].z;
float l9_15=(l9_12+l9_13)+l9_14;
float l9_16;
int l9_17;
if (l9_3>l9_15)
{
l9_17=1;
l9_16=l9_3;
}
else
{
l9_17=0;
l9_16=l9_15;
}
float l9_18;
int l9_19;
if (l9_7>l9_16)
{
l9_19=2;
l9_18=l9_7;
}
else
{
l9_19=l9_17;
l9_18=l9_16;
}
float l9_20;
int l9_21;
if (l9_11>l9_18)
{
l9_21=3;
l9_20=l9_11;
}
else
{
l9_21=l9_19;
l9_20=l9_18;
}
float l9_22=l9_20+1.0;
float l9_23=sqrt(l9_22)*0.5;
float l9_24=0.25/l9_23;
if (l9_21==0)
{
return vec4(l9_23,(m[1].z-m[2].y)*l9_24,(m[2].x-m[0].z)*l9_24,(m[0].y-m[1].x)*l9_24);
}
else
{
if (l9_21==1)
{
return vec4((m[1].z-m[2].y)*l9_24,l9_23,(m[0].y+m[1].x)*l9_24,(m[2].x+m[0].z)*l9_24);
}
else
{
if (l9_21==2)
{
return vec4((m[2].x-m[0].z)*l9_24,(m[0].y+m[1].x)*l9_24,l9_23,(m[1].z+m[2].y)*l9_24);
}
else
{
if (l9_21==3)
{
return vec4((m[0].y-m[1].x)*l9_24,(m[2].x+m[0].z)*l9_24,(m[1].z+m[2].y)*l9_24,l9_23);
}
else
{
return vec4(1.0,0.0,0.0,0.0);
}
}
}
}
}
void main()
{
bool l9_0=ssDecodeParticle(sc_GetLocalInstanceID());
bool l9_1=overrideTimeEnabled==1;
float l9_2;
if (l9_1)
{
l9_2=overrideTimeElapsed;
}
else
{
l9_2=sc_Time.x;
}
float l9_3;
if (l9_1)
{
l9_3=overrideTimeDelta;
}
else
{
l9_3=max(sc_Time.y,0.0);
}
float l9_4=gParticle.TimeShift;
float l9_5=l9_4*l9_3;
float l9_6=l9_2-l9_5;
float l9_7=l9_6-0.0;
gParticle.Age=mod((l9_7-gParticle.SpawnOffset)+0.0,3.0);
float l9_8=gParticle.SpawnOffset;
float l9_9=l9_2-l9_8;
bool l9_10=l9_9<(0.0-0.0);
bool l9_11;
if (!l9_10)
{
l9_11=gParticle.Age>3.0;
}
else
{
l9_11=l9_10;
}
bool l9_12=l9_11 ? true : false;
bool l9_13=!l9_12;
bool l9_14;
if (l9_13)
{
l9_14=gParticle.Life<=9.9999997e-05;
}
else
{
l9_14=l9_13;
}
bool l9_15;
if (!l9_14)
{
l9_15=mod(((l9_2-gParticle.SpawnOffset)-0.0)+0.0,3.0)<=l9_3;
}
else
{
l9_15=l9_14;
}
if (l9_15)
{
SpawnParticle(ssGlobals(l9_2,l9_3,l9_7));
gParticle.Spawned=true;
}
if (gParticle.Dead)
{
sc_SetClipPosition(vec4(4334.0,4334.0,4334.0,0.0));
return;
}
float l9_16=clamp(gParticle.Age/gParticle.Life,0.0,1.0);
float l9_17=gParticle.Life+1.234e-06;
vec4 l9_18=vec4(gParticle.Color.x,gParticle.Color.y,gParticle.Color.z,vec4(0.0).w);
l9_18.w=mix(Port_Import_N009,Port_Import_N010,(clamp((l9_16*(Port_Input0_N214/((Port_Import_N012/l9_17)+1.234e-06)))+0.001,Port_Input1_N076+0.001,Port_Input2_N076+0.001)-0.001)*(clamp(((1.0-l9_16)*(Port_Input0_N079/((Port_Import_N064/l9_17)+1.234e-06)))+0.001,Port_Input1_N081+0.001,Port_Input2_N081+0.001)-0.001));
gParticle.Color=l9_18;
gParticle.Force+=vec3(0.0,(Port_Import_N017*gParticle.Mass)*Port_Input2_N024,0.0);
vec4 param_4;
Node91_Remap(sc_InternalTextureLevel(gParticle.Position*vec3(Port_Input1_N089),0.0,Tweak_N49),param_4,Port_RangeMinA_N091,Port_RangeMaxA_N091,Port_RangeMinB_N091,Port_RangeMaxB_N091,ssGlobals(l9_2,l9_3,l9_7));
gParticle.Force+=(((param_4.xyz-Port_Input1_N067)*vec3(Port_Input1_N072))*Port_Input2_N072);
vec4 l9_19=ssGetParticleRandom(1,false,true,true,96.0,gParticle,0.0,l9_2);
float l9_20=gParticle.Age;
float l9_21=gParticle.Life;
float l9_22=(((clamp(l9_20/l9_21,0.0,1.0)-Port_RangeMinA_N095)/(Port_RangeMaxA_N095-Port_RangeMinA_N095))*(Port_RangeMaxB_N095-Port_RangeMinB_N095))+Port_RangeMinB_N095;
float l9_23;
if (Port_RangeMaxB_N095>Port_RangeMinB_N095)
{
l9_23=clamp(l9_22,Port_RangeMinB_N095,Port_RangeMaxB_N095);
}
else
{
l9_23=clamp(l9_22,Port_RangeMaxB_N095,Port_RangeMinB_N095);
}
gParticle.Size=mix(Port_Min_N096,Port_Max_N096,l9_19.x)*l9_23;
gParticle.Quaternion=matrixToQuaternion(gParticle.Matrix);
if (gParticle.Dead)
{
sc_SetClipPosition(vec4(4334.0,4334.0,4334.0,0.0));
return;
}
float l9_24=clamp(l9_3,9.9999997e-05,0.5);
float l9_25;
if (abs(gParticle.Force.x)<0.0049999999)
{
l9_25=0.0;
}
else
{
l9_25=gParticle.Force.x;
}
gParticle.Force.x=l9_25;
float l9_26;
if (abs(gParticle.Force.y)<0.0049999999)
{
l9_26=0.0;
}
else
{
l9_26=gParticle.Force.y;
}
gParticle.Force.y=l9_26;
float l9_27;
if (abs(gParticle.Force.z)<0.0049999999)
{
l9_27=0.0;
}
else
{
l9_27=gParticle.Force.z;
}
gParticle.Force.z=l9_27;
gParticle.Mass=max(0.0049999999,gParticle.Mass);
gParticle.Velocity+=((gParticle.Force/vec3(gParticle.Mass))*l9_24);
float l9_28;
if (abs(gParticle.Velocity.x)<0.0049999999)
{
l9_28=0.0;
}
else
{
l9_28=gParticle.Velocity.x;
}
gParticle.Velocity.x=l9_28;
float l9_29;
if (abs(gParticle.Velocity.y)<0.0049999999)
{
l9_29=0.0;
}
else
{
l9_29=gParticle.Velocity.y;
}
gParticle.Velocity.y=l9_29;
float l9_30;
if (abs(gParticle.Velocity.z)<0.0049999999)
{
l9_30=0.0;
}
else
{
l9_30=gParticle.Velocity.z;
}
gParticle.Velocity.z=l9_30;
gParticle.Position+=(gParticle.Velocity*l9_24);
vec2 l9_31=vec2(3.0,1.0)/vec2(2048.0,vfxTargetSizeWrite.y);
int l9_32=vfxOffsetInstancesWrite+sc_GetLocalInstanceID();
float l9_33;
if (texture0.x<0.5)
{
l9_33=0.0;
}
else
{
l9_33=l9_31.x;
}
float l9_34;
if (texture0.y<0.5)
{
l9_34=0.0;
}
else
{
l9_34=l9_31.y;
}
sc_SetClipPosition(vec4(((vec2(l9_33,l9_34)+(vec2(float(l9_32%682),float(l9_32/682))*l9_31))*2.0)-vec2(1.0),1.0,1.0));
Interp_Particle_Index=sc_GetLocalInstanceID();
Interp_Particle_Coord=texture0;
Interp_Particle_Force=gParticle.Force;
Interp_Particle_Position=gParticle.Position;
Interp_Particle_Velocity=gParticle.Velocity;
Interp_Particle_Life=gParticle.Life;
Interp_Particle_Age=gParticle.Age;
Interp_Particle_Size=gParticle.Size;
Interp_Particle_Color=gParticle.Color;
Interp_Particle_Quaternion=gParticle.Quaternion;
Interp_Particle_Mass=gParticle.Mass;
if (gParticle.Dead)
{
sc_SetClipPosition(vec4(4334.0,4334.0,4334.0,0.0));
return;
}
if (l9_1&&(overrideTimeDelta==0.0))
{
vec4 l9_35;
if (sc_GetLocalInstanceID()==0)
{
l9_35=vec4((texture0*2.0)-vec2(1.0),1.0,1.0);
}
else
{
l9_35=vec4(0.0);
}
sc_SetClipPosition(l9_35);
varPackedTex=vec4(texture0.x,texture0.y,varPackedTex.z,varPackedTex.w);
}
}
#elif defined FRAGMENT_SHADER // #if defined VERTEX_SHADER
#define SC_DISABLE_FRUSTUM_CULLING
#define SC_ALLOW_16_TEXTURES
#define SC_ENABLE_INSTANCED_RENDERING
#define sc_StereoRendering_Disabled 0
#define sc_StereoRendering_InstancedClipped 1
#define sc_StereoRendering_Multiview 2
#ifdef GL_ES
    #define SC_GLES_VERSION_20 2000
    #define SC_GLES_VERSION_30 3000
    #define SC_GLES_VERSION_31 3100
    #define SC_GLES_VERSION_32 3200
#endif
#ifdef VERTEX_SHADER
    #define scOutPos(clipPosition) gl_Position=clipPosition
    #define MAIN main
#endif
#ifdef SC_ENABLE_INSTANCED_RENDERING
    #ifndef sc_EnableInstancing
        #define sc_EnableInstancing 1
    #endif
#endif
#define mod(x,y) (x-y*floor((x+1e-6)/y))
#if defined(GL_ES)&&(__VERSION__<300)&&!defined(GL_OES_standard_derivatives)
#define dFdx(A) (A)
#define dFdy(A) (A)
#define fwidth(A) (A)
#endif
#if __VERSION__<300
#define isinf(x) (x!=0.0&&x*2.0==x ? true : false)
#define isnan(x) (x>0.0||x<0.0||x==0.0 ? false : true)
#endif
#ifdef sc_EnableFeatureLevelES3
    #ifdef sc_EnableStereoClipDistance
        #if defined(GL_APPLE_clip_distance)
            #extension GL_APPLE_clip_distance : require
        #elif defined(GL_EXT_clip_cull_distance)
            #extension GL_EXT_clip_cull_distance : require
        #else
            #error Clip distance is requested but not supported by this device.
        #endif
    #endif
#else
    #ifdef sc_EnableStereoClipDistance
        #error Clip distance is requested but not supported by this device.
    #endif
#endif
#ifdef sc_EnableFeatureLevelES3
    #ifdef VERTEX_SHADER
        #define attribute in
        #define varying out
    #endif
    #ifdef FRAGMENT_SHADER
        #define varying in
    #endif
    #define gl_FragColor sc_FragData0
    #define texture2D texture
    #define texture2DLod textureLod
    #define texture2DLodEXT textureLod
    #define textureCubeLodEXT textureLod
    #define sc_CanUseTextureLod 1
#else
    #ifdef FRAGMENT_SHADER
        #if defined(GL_EXT_shader_texture_lod)
            #extension GL_EXT_shader_texture_lod : require
            #define sc_CanUseTextureLod 1
            #define texture2DLod texture2DLodEXT
        #endif
    #endif
#endif
#if defined(sc_EnableMultiviewStereoRendering)
    #define sc_StereoRenderingMode sc_StereoRendering_Multiview
    #define sc_NumStereoViews 2
    #extension GL_OVR_multiview2 : require
    #ifdef VERTEX_SHADER
        #ifdef sc_EnableInstancingFallback
            #define sc_GlobalInstanceID (sc_FallbackInstanceID*2+gl_InstanceID)
        #else
            #define sc_GlobalInstanceID gl_InstanceID
        #endif
        #define sc_LocalInstanceID sc_GlobalInstanceID
        #define sc_StereoViewID int(gl_ViewID_OVR)
    #endif
#elif defined(sc_EnableInstancedClippedStereoRendering)
    #ifndef sc_EnableInstancing
        #error Instanced-clipped stereo rendering requires enabled instancing.
    #endif
    #ifndef sc_EnableStereoClipDistance
        #define sc_StereoRendering_IsClipDistanceEnabled 0
    #else
        #define sc_StereoRendering_IsClipDistanceEnabled 1
    #endif
    #define sc_StereoRenderingMode sc_StereoRendering_InstancedClipped
    #define sc_NumStereoClipPlanes 1
    #define sc_NumStereoViews 2
    #ifdef VERTEX_SHADER
        #ifdef sc_EnableInstancingFallback
            #define sc_GlobalInstanceID (sc_FallbackInstanceID*2+gl_InstanceID)
        #else
            #define sc_GlobalInstanceID gl_InstanceID
        #endif
        #ifdef sc_EnableFeatureLevelES3
            #define sc_LocalInstanceID (sc_GlobalInstanceID/2)
            #define sc_StereoViewID (sc_GlobalInstanceID%2)
        #else
            #define sc_LocalInstanceID int(sc_GlobalInstanceID/2.0)
            #define sc_StereoViewID int(mod(sc_GlobalInstanceID,2.0))
        #endif
    #endif
#else
    #define sc_StereoRenderingMode sc_StereoRendering_Disabled
#endif
#ifdef VERTEX_SHADER
    #ifdef sc_EnableInstancing
        #ifdef GL_ES
            #if defined(sc_EnableFeatureLevelES2)&&!defined(GL_EXT_draw_instanced)
                #define gl_InstanceID (0)
            #endif
        #else
            #if defined(sc_EnableFeatureLevelES2)&&!defined(GL_EXT_draw_instanced)&&!defined(GL_ARB_draw_instanced)&&!defined(GL_EXT_gpu_shader4)
                #define gl_InstanceID (0)
            #endif
        #endif
        #ifdef GL_ARB_draw_instanced
            #extension GL_ARB_draw_instanced : require
            #define gl_InstanceID gl_InstanceIDARB
        #endif
        #ifdef GL_EXT_draw_instanced
            #extension GL_EXT_draw_instanced : require
            #define gl_InstanceID gl_InstanceIDEXT
        #endif
        #ifndef sc_InstanceID
            #define sc_InstanceID gl_InstanceID
        #endif
        #ifndef sc_GlobalInstanceID
            #ifdef sc_EnableInstancingFallback
                #define sc_GlobalInstanceID (sc_FallbackInstanceID)
                #define sc_LocalInstanceID (sc_FallbackInstanceID)
            #else
                #define sc_GlobalInstanceID gl_InstanceID
                #define sc_LocalInstanceID gl_InstanceID
            #endif
        #endif
    #endif
#endif
#ifdef VERTEX_SHADER
    #if (__VERSION__<300)&&!defined(GL_EXT_gpu_shader4)
        #define gl_VertexID (0)
    #endif
#endif
#ifndef GL_ES
        #extension GL_EXT_gpu_shader4 : enable
    #extension GL_ARB_shader_texture_lod : enable
    #ifndef texture2DLodEXT
        #define texture2DLodEXT texture2DLod
    #endif
    #ifndef sc_CanUseTextureLod
    #define sc_CanUseTextureLod 1
    #endif
    #define precision
    #define lowp
    #define mediump
    #define highp
    #define sc_FragmentPrecision
#endif
#ifdef sc_EnableFeatureLevelES3
    #define sc_CanUseSampler2DArray 1
#endif
#if defined(sc_EnableFeatureLevelES2)&&defined(GL_ES)
    #ifdef FRAGMENT_SHADER
        #ifdef GL_OES_standard_derivatives
            #extension GL_OES_standard_derivatives : require
            #define sc_CanUseStandardDerivatives 1
        #endif
    #endif
    #ifdef GL_EXT_texture_array
        #extension GL_EXT_texture_array : require
        #define sc_CanUseSampler2DArray 1
    #else
        #define sc_CanUseSampler2DArray 0
    #endif
#endif
#ifdef GL_ES
    #ifdef sc_FramebufferFetch
        #if defined(GL_EXT_shader_framebuffer_fetch)
            #extension GL_EXT_shader_framebuffer_fetch : require
        #elif defined(GL_ARM_shader_framebuffer_fetch)
            #extension GL_ARM_shader_framebuffer_fetch : require
        #else
            #error Framebuffer fetch is requested but not supported by this device.
        #endif
    #endif
    #ifdef GL_FRAGMENT_PRECISION_HIGH
        #define sc_FragmentPrecision highp
    #else
        #define sc_FragmentPrecision mediump
    #endif
    #ifdef FRAGMENT_SHADER
        precision highp int;
        precision highp float;
    #endif
#endif
#ifdef VERTEX_SHADER
    #ifdef sc_EnableMultiviewStereoRendering
        layout(num_views=sc_NumStereoViews) in;
    #endif
#endif
#if __VERSION__>100
    #define SC_INT_FALLBACK_FLOAT int
    #define SC_INTERPOLATION_FLAT flat
    #define SC_INTERPOLATION_CENTROID centroid
#else
    #define SC_INT_FALLBACK_FLOAT float
    #define SC_INTERPOLATION_FLAT
    #define SC_INTERPOLATION_CENTROID
#endif
#ifndef sc_NumStereoViews
    #define sc_NumStereoViews 1
#endif
#ifndef sc_CanUseSampler2DArray
    #define sc_CanUseSampler2DArray 0
#endif
    #if __VERSION__==100||defined(SCC_VALIDATION)
        #define sampler2DArray vec2
        #define sampler3D vec3
        #define samplerCube vec4
        vec4 texture3D(vec3 s,vec3 uv)                       { return vec4(0.0); }
        vec4 texture3D(vec3 s,vec3 uv,float bias)           { return vec4(0.0); }
        vec4 texture3DLod(vec3 s,vec3 uv,float bias)        { return vec4(0.0); }
        vec4 texture3DLodEXT(vec3 s,vec3 uv,float lod)      { return vec4(0.0); }
        vec4 texture2DArray(vec2 s,vec3 uv)                  { return vec4(0.0); }
        vec4 texture2DArray(vec2 s,vec3 uv,float bias)      { return vec4(0.0); }
        vec4 texture2DArrayLod(vec2 s,vec3 uv,float lod)    { return vec4(0.0); }
        vec4 texture2DArrayLodEXT(vec2 s,vec3 uv,float lod) { return vec4(0.0); }
        vec4 textureCube(vec4 s,vec3 uv)                     { return vec4(0.0); }
        vec4 textureCube(vec4 s,vec3 uv,float lod)          { return vec4(0.0); }
        vec4 textureCubeLod(vec4 s,vec3 uv,float lod)       { return vec4(0.0); }
        vec4 textureCubeLodEXT(vec4 s,vec3 uv,float lod)    { return vec4(0.0); }
        #if defined(VERTEX_SHADER)||!sc_CanUseTextureLod
            #define texture2DLod(s,uv,lod)      vec4(0.0)
            #define texture2DLodEXT(s,uv,lod)   vec4(0.0)
        #endif
    #elif __VERSION__>=300
        #define texture3D texture
        #define textureCube texture
        #define texture2DArray texture
        #define texture2DLod textureLod
        #define texture3DLod textureLod
        #define texture2DLodEXT textureLod
        #define texture3DLodEXT textureLod
        #define textureCubeLod textureLod
        #define textureCubeLodEXT textureLod
        #define texture2DArrayLod textureLod
        #define texture2DArrayLodEXT textureLod
    #endif
    #ifndef sc_TextureRenderingLayout_Regular
        #define sc_TextureRenderingLayout_Regular 0
        #define sc_TextureRenderingLayout_StereoInstancedClipped 1
        #define sc_TextureRenderingLayout_StereoMultiview 2
    #endif
    #define depthToGlobal   depthScreenToViewSpace
    #define depthToLocal    depthViewToScreenSpace
    #ifndef quantizeUV
        #define quantizeUV sc_QuantizeUV
        #define sc_platformUVFlip sc_PlatformFlipV
        #define sc_PlatformFlipUV sc_PlatformFlipV
    #endif
    #ifndef sc_texture2DLod
        #define sc_texture2DLod sc_InternalTextureLevel
        #define sc_textureLod sc_InternalTextureLevel
        #define sc_textureBias sc_InternalTextureBiasOrLevel
        #define sc_texture sc_InternalTexture
    #endif
#if sc_ExporterVersion<224
#define MAIN main
#endif
    #ifndef sc_FramebufferFetch
    #define sc_FramebufferFetch 0
    #elif sc_FramebufferFetch==1
    #undef sc_FramebufferFetch
    #define sc_FramebufferFetch 1
    #endif
    #if !defined(GL_ES)&&__VERSION__<420
        #ifdef FRAGMENT_SHADER
            #define sc_FragData0 gl_FragData[0]
            #define sc_FragData1 gl_FragData[1]
            #define sc_FragData2 gl_FragData[2]
            #define sc_FragData3 gl_FragData[3]
        #endif
        mat4 getFragData() { return mat4(vec4(0.0),vec4(0.0),vec4(0.0),vec4(0.0)); }
        #define gl_LastFragData (getFragData())
        #if sc_FramebufferFetch
            #error Framebuffer fetch is requested but not supported by this device.
        #endif
    #elif defined(sc_EnableFeatureLevelES3)
        #if sc_FragDataCount>=1
            #define sc_DeclareFragData0(StorageQualifier) layout(location=0) StorageQualifier sc_FragmentPrecision vec4 sc_FragData0
        #endif
        #if sc_FragDataCount>=2
            #define sc_DeclareFragData1(StorageQualifier) layout(location=1) StorageQualifier sc_FragmentPrecision vec4 sc_FragData1
        #endif
        #if sc_FragDataCount>=3
            #define sc_DeclareFragData2(StorageQualifier) layout(location=2) StorageQualifier sc_FragmentPrecision vec4 sc_FragData2
        #endif
        #if sc_FragDataCount>=4
            #define sc_DeclareFragData3(StorageQualifier) layout(location=3) StorageQualifier sc_FragmentPrecision vec4 sc_FragData3
        #endif
        #ifndef sc_DeclareFragData0
            #define sc_DeclareFragData0(_) const vec4 sc_FragData0=vec4(0.0)
        #endif
        #ifndef sc_DeclareFragData1
            #define sc_DeclareFragData1(_) const vec4 sc_FragData1=vec4(0.0)
        #endif
        #ifndef sc_DeclareFragData2
            #define sc_DeclareFragData2(_) const vec4 sc_FragData2=vec4(0.0)
        #endif
        #ifndef sc_DeclareFragData3
            #define sc_DeclareFragData3(_) const vec4 sc_FragData3=vec4(0.0)
        #endif
        #if sc_FramebufferFetch
            #ifdef GL_EXT_shader_framebuffer_fetch
                sc_DeclareFragData0(inout);
                sc_DeclareFragData1(inout);
                sc_DeclareFragData2(inout);
                sc_DeclareFragData3(inout);
                mediump mat4 getFragData() { return mat4(sc_FragData0,sc_FragData1,sc_FragData2,sc_FragData3); }
                #define gl_LastFragData (getFragData())
            #elif defined(GL_ARM_shader_framebuffer_fetch)
                sc_DeclareFragData0(out);
                sc_DeclareFragData1(out);
                sc_DeclareFragData2(out);
                sc_DeclareFragData3(out);
                mediump mat4 getFragData() { return mat4(gl_LastFragColorARM,vec4(0.0),vec4(0.0),vec4(0.0)); }
                #define gl_LastFragData (getFragData())
            #endif
        #else
            #ifdef sc_EnableFeatureLevelES3
                sc_DeclareFragData0(out);
                sc_DeclareFragData1(out);
                sc_DeclareFragData2(out);
                sc_DeclareFragData3(out);
                mediump mat4 getFragData() { return mat4(vec4(0.0),vec4(0.0),vec4(0.0),vec4(0.0)); }
                #define gl_LastFragData (getFragData())
            #endif
        #endif
    #elif defined(sc_EnableFeatureLevelES2)
        #define sc_FragData0 gl_FragColor
        mediump mat4 getFragData() { return mat4(vec4(0.0),vec4(0.0),vec4(0.0),vec4(0.0)); }
    #else
        #define sc_FragData0 gl_FragColor
        mediump mat4 getFragData() { return mat4(vec4(0.0),vec4(0.0),vec4(0.0),vec4(0.0)); }
    #endif
#ifndef sc_CanUseTextureLod
#define sc_CanUseTextureLod 0
#elif sc_CanUseTextureLod==1
#undef sc_CanUseTextureLod
#define sc_CanUseTextureLod 1
#endif
#ifndef sc_StereoRenderingMode
#define sc_StereoRenderingMode 0
#endif
#ifndef sc_NumStereoViews
#define sc_NumStereoViews 1
#endif
#ifndef sc_StereoRendering_IsClipDistanceEnabled
#define sc_StereoRendering_IsClipDistanceEnabled 0
#endif
#ifndef sc_SkinBonesCount
#define sc_SkinBonesCount 0
#endif
#ifndef renderTarget0HasSwappedViews
#define renderTarget0HasSwappedViews 0
#elif renderTarget0HasSwappedViews==1
#undef renderTarget0HasSwappedViews
#define renderTarget0HasSwappedViews 1
#endif
#ifndef renderTarget0Layout
#define renderTarget0Layout 0
#endif
#ifndef renderTarget1HasSwappedViews
#define renderTarget1HasSwappedViews 0
#elif renderTarget1HasSwappedViews==1
#undef renderTarget1HasSwappedViews
#define renderTarget1HasSwappedViews 1
#endif
#ifndef renderTarget1Layout
#define renderTarget1Layout 0
#endif
#ifndef renderTarget2HasSwappedViews
#define renderTarget2HasSwappedViews 0
#elif renderTarget2HasSwappedViews==1
#undef renderTarget2HasSwappedViews
#define renderTarget2HasSwappedViews 1
#endif
#ifndef renderTarget2Layout
#define renderTarget2Layout 0
#endif
#ifndef renderTarget3HasSwappedViews
#define renderTarget3HasSwappedViews 0
#elif renderTarget3HasSwappedViews==1
#undef renderTarget3HasSwappedViews
#define renderTarget3HasSwappedViews 1
#endif
#ifndef renderTarget3Layout
#define renderTarget3Layout 0
#endif
#ifndef SC_USE_UV_TRANSFORM_renderTarget0
#define SC_USE_UV_TRANSFORM_renderTarget0 0
#elif SC_USE_UV_TRANSFORM_renderTarget0==1
#undef SC_USE_UV_TRANSFORM_renderTarget0
#define SC_USE_UV_TRANSFORM_renderTarget0 1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_U_renderTarget0
#define SC_SOFTWARE_WRAP_MODE_U_renderTarget0 -1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_V_renderTarget0
#define SC_SOFTWARE_WRAP_MODE_V_renderTarget0 -1
#endif
#ifndef SC_USE_UV_MIN_MAX_renderTarget0
#define SC_USE_UV_MIN_MAX_renderTarget0 0
#elif SC_USE_UV_MIN_MAX_renderTarget0==1
#undef SC_USE_UV_MIN_MAX_renderTarget0
#define SC_USE_UV_MIN_MAX_renderTarget0 1
#endif
#ifndef SC_USE_CLAMP_TO_BORDER_renderTarget0
#define SC_USE_CLAMP_TO_BORDER_renderTarget0 0
#elif SC_USE_CLAMP_TO_BORDER_renderTarget0==1
#undef SC_USE_CLAMP_TO_BORDER_renderTarget0
#define SC_USE_CLAMP_TO_BORDER_renderTarget0 1
#endif
#ifndef SC_USE_UV_TRANSFORM_renderTarget1
#define SC_USE_UV_TRANSFORM_renderTarget1 0
#elif SC_USE_UV_TRANSFORM_renderTarget1==1
#undef SC_USE_UV_TRANSFORM_renderTarget1
#define SC_USE_UV_TRANSFORM_renderTarget1 1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_U_renderTarget1
#define SC_SOFTWARE_WRAP_MODE_U_renderTarget1 -1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_V_renderTarget1
#define SC_SOFTWARE_WRAP_MODE_V_renderTarget1 -1
#endif
#ifndef SC_USE_UV_MIN_MAX_renderTarget1
#define SC_USE_UV_MIN_MAX_renderTarget1 0
#elif SC_USE_UV_MIN_MAX_renderTarget1==1
#undef SC_USE_UV_MIN_MAX_renderTarget1
#define SC_USE_UV_MIN_MAX_renderTarget1 1
#endif
#ifndef SC_USE_CLAMP_TO_BORDER_renderTarget1
#define SC_USE_CLAMP_TO_BORDER_renderTarget1 0
#elif SC_USE_CLAMP_TO_BORDER_renderTarget1==1
#undef SC_USE_CLAMP_TO_BORDER_renderTarget1
#define SC_USE_CLAMP_TO_BORDER_renderTarget1 1
#endif
#ifndef SC_USE_UV_TRANSFORM_renderTarget2
#define SC_USE_UV_TRANSFORM_renderTarget2 0
#elif SC_USE_UV_TRANSFORM_renderTarget2==1
#undef SC_USE_UV_TRANSFORM_renderTarget2
#define SC_USE_UV_TRANSFORM_renderTarget2 1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_U_renderTarget2
#define SC_SOFTWARE_WRAP_MODE_U_renderTarget2 -1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_V_renderTarget2
#define SC_SOFTWARE_WRAP_MODE_V_renderTarget2 -1
#endif
#ifndef SC_USE_UV_MIN_MAX_renderTarget2
#define SC_USE_UV_MIN_MAX_renderTarget2 0
#elif SC_USE_UV_MIN_MAX_renderTarget2==1
#undef SC_USE_UV_MIN_MAX_renderTarget2
#define SC_USE_UV_MIN_MAX_renderTarget2 1
#endif
#ifndef SC_USE_CLAMP_TO_BORDER_renderTarget2
#define SC_USE_CLAMP_TO_BORDER_renderTarget2 0
#elif SC_USE_CLAMP_TO_BORDER_renderTarget2==1
#undef SC_USE_CLAMP_TO_BORDER_renderTarget2
#define SC_USE_CLAMP_TO_BORDER_renderTarget2 1
#endif
#ifndef SC_USE_UV_TRANSFORM_renderTarget3
#define SC_USE_UV_TRANSFORM_renderTarget3 0
#elif SC_USE_UV_TRANSFORM_renderTarget3==1
#undef SC_USE_UV_TRANSFORM_renderTarget3
#define SC_USE_UV_TRANSFORM_renderTarget3 1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_U_renderTarget3
#define SC_SOFTWARE_WRAP_MODE_U_renderTarget3 -1
#endif
#ifndef SC_SOFTWARE_WRAP_MODE_V_renderTarget3
#define SC_SOFTWARE_WRAP_MODE_V_renderTarget3 -1
#endif
#ifndef SC_USE_UV_MIN_MAX_renderTarget3
#define SC_USE_UV_MIN_MAX_renderTarget3 0
#elif SC_USE_UV_MIN_MAX_renderTarget3==1
#undef SC_USE_UV_MIN_MAX_renderTarget3
#define SC_USE_UV_MIN_MAX_renderTarget3 1
#endif
#ifndef SC_USE_CLAMP_TO_BORDER_renderTarget3
#define SC_USE_CLAMP_TO_BORDER_renderTarget3 0
#elif SC_USE_CLAMP_TO_BORDER_renderTarget3==1
#undef SC_USE_CLAMP_TO_BORDER_renderTarget3
#define SC_USE_CLAMP_TO_BORDER_renderTarget3 1
#endif
#ifndef sc_PointLightsCount
#define sc_PointLightsCount 0
#endif
#ifndef sc_DirectionalLightsCount
#define sc_DirectionalLightsCount 0
#endif
#ifndef sc_AmbientLightsCount
#define sc_AmbientLightsCount 0
#endif
struct sc_PointLight_t
{
bool falloffEnabled;
float falloffEndDistance;
float negRcpFalloffEndDistance4;
float angleScale;
float angleOffset;
vec3 direction;
vec3 position;
vec4 color;
};
struct sc_DirectionalLight_t
{
vec3 direction;
vec4 color;
};
struct sc_AmbientLight_t
{
vec3 color;
float intensity;
};
struct sc_SphericalGaussianLight_t
{
vec3 color;
float sharpness;
vec3 axis;
};
struct sc_LightEstimationData_t
{
sc_SphericalGaussianLight_t sg[12];
vec3 ambientLight;
};
struct sc_Camera_t
{
vec3 position;
float aspect;
vec2 clipPlanes;
};
uniform vec4 sc_EnvmapDiffuseDims;
uniform vec4 sc_EnvmapSpecularDims;
uniform vec4 sc_ScreenTextureDims;
uniform vec4 sc_CurrentRenderTargetDims;
uniform mat4 sc_ProjectionMatrixArray[sc_NumStereoViews];
uniform float sc_ShadowDensity;
uniform vec4 sc_ShadowColor;
uniform float shaderComplexityValue;
uniform float _sc_framebufferFetchMarker;
uniform float _sc_GetFramebufferColorInvalidUsageMarker;
uniform mat4 sc_ViewProjectionMatrixArray[sc_NumStereoViews];
uniform mat4 sc_PrevFrameViewProjectionMatrixArray[sc_NumStereoViews];
uniform mat4 sc_PrevFrameModelMatrix;
uniform mat4 sc_ModelMatrixInverse;
uniform vec4 intensityTextureDims;
uniform float correctedIntensity;
uniform mat3 intensityTextureTransform;
uniform vec4 intensityTextureUvMinMax;
uniform vec4 intensityTextureBorderColor;
uniform vec4 renderTarget0Dims;
uniform vec4 renderTarget1Dims;
uniform vec4 renderTarget2Dims;
uniform vec4 renderTarget3Dims;
uniform int overrideTimeEnabled;
uniform float overrideTimeElapsed;
uniform vec4 sc_Time;
uniform int vfxOffsetInstancesRead;
uniform int vfxTargetWidth;
uniform vec2 vfxTargetSizeRead;
uniform mat3 renderTarget0Transform;
uniform vec4 renderTarget0UvMinMax;
uniform vec4 renderTarget0BorderColor;
uniform bool vfxBatchEnable[32];
uniform mat3 renderTarget1Transform;
uniform vec4 renderTarget1UvMinMax;
uniform vec4 renderTarget1BorderColor;
uniform mat3 renderTarget2Transform;
uniform vec4 renderTarget2UvMinMax;
uniform vec4 renderTarget2BorderColor;
uniform mat3 renderTarget3Transform;
uniform vec4 renderTarget3UvMinMax;
uniform vec4 renderTarget3BorderColor;
uniform float overrideTimeDelta;
uniform sc_PointLight_t sc_PointLights[sc_PointLightsCount+1];
uniform sc_DirectionalLight_t sc_DirectionalLights[sc_DirectionalLightsCount+1];
uniform sc_AmbientLight_t sc_AmbientLights[sc_AmbientLightsCount+1];
uniform sc_LightEstimationData_t sc_LightEstimationData;
uniform vec4 sc_EnvmapDiffuseSize;
uniform vec4 sc_EnvmapDiffuseView;
uniform vec4 sc_EnvmapSpecularSize;
uniform vec4 sc_EnvmapSpecularView;
uniform vec3 sc_EnvmapRotation;
uniform float sc_EnvmapExposure;
uniform vec3 sc_Sh[9];
uniform float sc_ShIntensity;
uniform vec4 sc_UniformConstants;
uniform vec4 sc_GeometryInfo;
uniform mat4 sc_ModelViewProjectionMatrixArray[sc_NumStereoViews];
uniform mat4 sc_ModelViewProjectionMatrixInverseArray[sc_NumStereoViews];
uniform mat4 sc_ViewProjectionMatrixInverseArray[sc_NumStereoViews];
uniform mat4 sc_ModelViewMatrixArray[sc_NumStereoViews];
uniform mat4 sc_ModelViewMatrixInverseArray[sc_NumStereoViews];
uniform mat3 sc_ViewNormalMatrixArray[sc_NumStereoViews];
uniform mat3 sc_ViewNormalMatrixInverseArray[sc_NumStereoViews];
uniform mat4 sc_ProjectionMatrixInverseArray[sc_NumStereoViews];
uniform mat4 sc_ViewMatrixArray[sc_NumStereoViews];
uniform mat4 sc_ViewMatrixInverseArray[sc_NumStereoViews];
uniform mat4 sc_ModelMatrix;
uniform mat3 sc_NormalMatrix;
uniform mat3 sc_NormalMatrixInverse;
uniform mat4 sc_PrevFrameModelMatrixInverse;
uniform vec3 sc_LocalAabbMin;
uniform vec3 sc_LocalAabbMax;
uniform vec3 sc_WorldAabbMin;
uniform vec3 sc_WorldAabbMax;
uniform vec4 sc_WindowToViewportTransform;
uniform sc_Camera_t sc_Camera;
uniform mat4 sc_ProjectorMatrix;
uniform float sc_DisableFrustumCullingMarker;
uniform vec4 sc_BoneMatrices[(sc_SkinBonesCount*3)+1];
uniform mat3 sc_SkinBonesNormalMatrices[sc_SkinBonesCount+1];
uniform vec4 weights0;
uniform vec4 weights1;
uniform vec4 weights2;
uniform vec4 sc_StereoClipPlanes[sc_NumStereoViews];
uniform int sc_FallbackInstanceID;
uniform vec2 sc_TAAJitterOffset;
uniform float strandWidth;
uniform float strandTaper;
uniform vec4 sc_StrandDataMapTextureSize;
uniform float clumpInstanceCount;
uniform float clumpRadius;
uniform float clumpTipScale;
uniform float hairstyleInstanceCount;
uniform float hairstyleNoise;
uniform vec4 sc_ScreenTextureSize;
uniform vec4 sc_ScreenTextureView;
uniform vec4 intensityTextureSize;
uniform vec4 intensityTextureView;
uniform float reflBlurWidth;
uniform float reflBlurMinRough;
uniform float reflBlurMaxRough;
uniform int vfxNumCopies;
uniform mat4 vfxModelMatrix[32];
uniform vec4 renderTarget0Size;
uniform vec4 renderTarget0View;
uniform vec4 renderTarget1Size;
uniform vec4 renderTarget1View;
uniform vec4 renderTarget2Size;
uniform vec4 renderTarget2View;
uniform vec4 renderTarget3Size;
uniform vec4 renderTarget3View;
uniform vec3 vfxLocalAabbMin;
uniform vec3 vfxLocalAabbMax;
uniform float vfxCameraAspect;
uniform float vfxCameraNear;
uniform float vfxCameraFar;
uniform vec3 vfxCameraUp;
uniform vec3 vfxCameraForward;
uniform vec3 vfxCameraRight;
uniform mat4 vfxProjectionMatrix;
uniform mat4 vfxProjectionMatrixInverse;
uniform mat4 vfxViewMatrix;
uniform mat4 vfxViewMatrixInverse;
uniform mat4 vfxViewProjectionMatrix;
uniform mat4 vfxViewProjectionMatrixInverse;
uniform int vfxFrame;
uniform int vfxOffsetInstancesWrite;
uniform vec2 vfxTargetSizeWrite;
uniform vec4 Tweak_N49Size;
uniform vec2 Tweak_N49Depth;
uniform float amount;
uniform float Port_Import_N209;
uniform vec3 Port_Import_N210;
uniform vec3 Port_Input1_N146;
uniform float Port_Min_N223;
uniform float Port_Max_N223;
uniform float Port_Input1_N224;
uniform float Port_Input1_N225;
uniform float Port_Input2_N225;
uniform float Port_Value2_N226;
uniform float Port_Value3_N226;
uniform vec3 Port_Import_N203;
uniform float Port_Input1_N233;
uniform float Port_Value1_N154;
uniform float Port_Multiplier_N147;
uniform float Port_RangeMinA_N152;
uniform float Port_RangeMaxA_N152;
uniform float Port_RangeMinB_N152;
uniform float Port_RangeMaxB_N152;
uniform float Port_Value3_N154;
uniform float Port_Value1_N155;
uniform float Port_Input1_N151;
uniform float Port_RangeMinA_N153;
uniform float Port_RangeMaxA_N153;
uniform float Port_RangeMinB_N153;
uniform float Port_RangeMaxB_N153;
uniform float Port_Value3_N155;
uniform vec3 Port_Input1_N090;
uniform float Port_Import_N267;
uniform float Port_Import_N268;
uniform float Port_Import_N132;
uniform float Port_Import_N133;
uniform float Port_Input1_N089;
uniform float Port_RangeMinA_N091;
uniform float Port_RangeMaxA_N091;
uniform float Port_RangeMinB_N091;
uniform float Port_RangeMaxB_N091;
uniform float Port_Input1_N031;
uniform float Port_Min_N030;
uniform float Port_Max_N030;
uniform float Port_Input1_N229;
uniform float Port_Input1_N230;
uniform float Port_Input2_N230;
uniform float Port_Import_N053;
uniform vec3 Port_Input0_N157;
uniform vec3 Port_Input1_N157;
uniform float Port_Multiplier_N156;
uniform float Port_RangeMinA_N161;
uniform float Port_RangeMaxA_N161;
uniform float Port_RangeMinB_N161;
uniform float Port_RangeMaxB_N161;
uniform vec3 Port_Input0_N159;
uniform vec3 Port_Input1_N159;
uniform float Port_Input1_N162;
uniform float Port_RangeMinA_N164;
uniform float Port_RangeMaxA_N164;
uniform float Port_RangeMinB_N164;
uniform float Port_RangeMaxB_N164;
uniform vec3 Port_Import_N054;
uniform vec4 Port_Import_N117;
uniform vec4 Port_Import_N118;
uniform float Port_Min_N119;
uniform float Port_Max_N119;
uniform vec3 Port_Input1_N165;
uniform vec3 Port_Input2_N165;
uniform vec3 Port_Import_N103;
uniform float Port_Import_N105;
uniform vec3 Port_Import_N110;
uniform vec3 Port_Import_N112;
uniform vec3 Port_Import_N306;
uniform float Port_Multiplier_N307;
uniform vec3 Port_Import_N310;
uniform vec2 Port_Input1_N314;
uniform vec2 Port_Scale_N315;
uniform vec2 Port_Input1_N317;
uniform vec2 Port_Scale_N318;
uniform vec2 Port_Input1_N320;
uniform vec2 Port_Scale_N321;
uniform vec3 Port_Input1_N323;
uniform float Port_Import_N142;
uniform float Port_Import_N143;
uniform float Port_Min_N175;
uniform float Port_Max_N175;
uniform float Port_Import_N009;
uniform float Port_Import_N010;
uniform float Port_Import_N075;
uniform float Port_Input0_N214;
uniform float Port_Import_N012;
uniform float Port_Import_N213;
uniform float Port_Input1_N076;
uniform float Port_Input2_N076;
uniform float Port_Input0_N079;
uniform float Port_Import_N064;
uniform float Port_Import_N078;
uniform float Port_Input1_N081;
uniform float Port_Input2_N081;
uniform float Port_Import_N017;
uniform float Port_Input2_N024;
uniform vec3 Port_Input1_N067;
uniform float Port_Input1_N072;
uniform vec3 Port_Input2_N072;
uniform float Port_Min_N096;
uniform float Port_Max_N096;
uniform float Port_RangeMinA_N095;
uniform float Port_RangeMaxA_N095;
uniform float Port_RangeMinB_N095;
uniform float Port_RangeMaxB_N095;
uniform sampler2DArray renderTarget0ArrSC;
uniform sampler2D renderTarget0;
uniform sampler2DArray renderTarget1ArrSC;
uniform sampler2D renderTarget1;
uniform sampler2DArray renderTarget2ArrSC;
uniform sampler2D renderTarget2;
uniform sampler2DArray renderTarget3ArrSC;
uniform sampler2D renderTarget3;
flat in int varStereoViewID;
in vec2 varShadowTex;
in float varClipDistance;
in float varViewSpaceDepth;
flat in int Interp_Particle_Index;
in vec4 varPackedTex;
in vec3 Interp_Particle_Position;
in vec3 Interp_Particle_Velocity;
in float Interp_Particle_Life;
in float Interp_Particle_Age;
in float Interp_Particle_Size;
in vec4 Interp_Particle_Color;
in vec4 Interp_Particle_Quaternion;
in float Interp_Particle_Mass;
in vec2 Interp_Particle_Coord;
in vec3 varPos;
in vec3 varNormal;
in vec4 varTangent;
in vec4 varScreenPos;
in vec2 varScreenTexturePos;
in vec4 varColor;
in vec3 Interp_Particle_Force;
int sc_GetStereoViewIndex()
{
int l9_0;
#if (sc_StereoRenderingMode==0)
{
l9_0=0;
}
#else
{
l9_0=varStereoViewID;
}
#endif
return l9_0;
}
int renderTarget0GetStereoViewIndex()
{
int l9_0;
#if (renderTarget0HasSwappedViews)
{
l9_0=1-sc_GetStereoViewIndex();
}
#else
{
l9_0=sc_GetStereoViewIndex();
}
#endif
return l9_0;
}
void sc_SoftwareWrapEarly(inout float uv,int softwareWrapMode)
{
if (softwareWrapMode==1)
{
uv=fract(uv);
}
else
{
if (softwareWrapMode==2)
{
float l9_0=fract(uv);
uv=mix(l9_0,1.0-l9_0,clamp(step(0.25,fract((uv-l9_0)*0.5)),0.0,1.0));
}
}
}
void sc_ClampUV(inout float value,float minValue,float maxValue,bool useClampToBorder,inout float clampToBorderFactor)
{
float l9_0=clamp(value,minValue,maxValue);
float l9_1=step(abs(value-l9_0),9.9999997e-06);
clampToBorderFactor*=(l9_1+((1.0-float(useClampToBorder))*(1.0-l9_1)));
value=l9_0;
}
vec2 sc_TransformUV(vec2 uv,bool useUvTransform,mat3 uvTransform)
{
if (useUvTransform)
{
uv=vec2((uvTransform*vec3(uv,1.0)).xy);
}
return uv;
}
void sc_SoftwareWrapLate(inout float uv,int softwareWrapMode,bool useClampToBorder,inout float clampToBorderFactor)
{
if ((softwareWrapMode==0)||(softwareWrapMode==3))
{
sc_ClampUV(uv,0.0,1.0,useClampToBorder,clampToBorderFactor);
}
}
vec3 sc_SamplingCoordsViewToGlobal(vec2 uv,int renderingLayout,int viewIndex)
{
vec3 l9_0;
if (renderingLayout==0)
{
l9_0=vec3(uv,0.0);
}
else
{
vec3 l9_1;
if (renderingLayout==1)
{
l9_1=vec3(uv.x,(uv.y*0.5)+(0.5-(float(viewIndex)*0.5)),0.0);
}
else
{
l9_1=vec3(uv,float(viewIndex));
}
l9_0=l9_1;
}
return l9_0;
}
vec4 sc_InternalTextureLevel(vec3 uv,float level_,sampler2DArray texsmp)
{
vec4 l9_0;
#if (sc_CanUseTextureLod)
{
l9_0=textureLod(texsmp,uv,level_);
}
#else
{
l9_0=vec4(0.0);
}
#endif
return l9_0;
}
vec4 sc_SampleViewLevel(vec2 texSize,vec2 uv,int renderingLayout,int viewIndex,float level_,sampler2DArray texsmp)
{
return sc_InternalTextureLevel(sc_SamplingCoordsViewToGlobal(uv,renderingLayout,viewIndex),level_,texsmp);
}
vec4 sc_SampleTextureLevel(vec2 samplerDims,int renderingLayout,int viewIndex,vec2 uv,bool useUvTransform,mat3 uvTransform,ivec2 softwareWrapModes,bool useUvMinMax,vec4 uvMinMax,bool useClampToBorder,vec4 borderColor,float level_,sampler2DArray texture_sampler_)
{
bool l9_0=useClampToBorder;
bool l9_1=useUvMinMax;
bool l9_2=l9_0&&(!l9_1);
sc_SoftwareWrapEarly(uv.x,softwareWrapModes.x);
sc_SoftwareWrapEarly(uv.y,softwareWrapModes.y);
float l9_3;
if (useUvMinMax)
{
bool l9_4=useClampToBorder;
bool l9_5;
if (l9_4)
{
l9_5=softwareWrapModes.x==3;
}
else
{
l9_5=l9_4;
}
float param_8=1.0;
sc_ClampUV(uv.x,uvMinMax.x,uvMinMax.z,l9_5,param_8);
float l9_6=param_8;
bool l9_7=useClampToBorder;
bool l9_8;
if (l9_7)
{
l9_8=softwareWrapModes.y==3;
}
else
{
l9_8=l9_7;
}
float param_13=l9_6;
sc_ClampUV(uv.y,uvMinMax.y,uvMinMax.w,l9_8,param_13);
l9_3=param_13;
}
else
{
l9_3=1.0;
}
uv=sc_TransformUV(uv,useUvTransform,uvTransform);
float param_20=l9_3;
sc_SoftwareWrapLate(uv.x,softwareWrapModes.x,l9_2,param_20);
sc_SoftwareWrapLate(uv.y,softwareWrapModes.y,l9_2,param_20);
float l9_9=param_20;
vec4 l9_10=sc_SampleViewLevel(samplerDims,uv,renderingLayout,viewIndex,level_,texture_sampler_);
vec4 l9_11;
if (useClampToBorder)
{
l9_11=mix(borderColor,l9_10,vec4(l9_9));
}
else
{
l9_11=l9_10;
}
return l9_11;
}
vec4 sc_SampleViewLevel(vec2 texSize,vec2 uv,int renderingLayout,int viewIndex,float level_,sampler2D texsmp)
{
return textureLod(texsmp,sc_SamplingCoordsViewToGlobal(uv,renderingLayout,viewIndex).xy,level_);
}
vec4 sc_SampleTextureLevel(vec2 samplerDims,int renderingLayout,int viewIndex,vec2 uv,bool useUvTransform,mat3 uvTransform,ivec2 softwareWrapModes,bool useUvMinMax,vec4 uvMinMax,bool useClampToBorder,vec4 borderColor,float level_,sampler2D texture_sampler_)
{
bool l9_0=useClampToBorder;
bool l9_1=useUvMinMax;
bool l9_2=l9_0&&(!l9_1);
sc_SoftwareWrapEarly(uv.x,softwareWrapModes.x);
sc_SoftwareWrapEarly(uv.y,softwareWrapModes.y);
float l9_3;
if (useUvMinMax)
{
bool l9_4=useClampToBorder;
bool l9_5;
if (l9_4)
{
l9_5=softwareWrapModes.x==3;
}
else
{
l9_5=l9_4;
}
float param_8=1.0;
sc_ClampUV(uv.x,uvMinMax.x,uvMinMax.z,l9_5,param_8);
float l9_6=param_8;
bool l9_7=useClampToBorder;
bool l9_8;
if (l9_7)
{
l9_8=softwareWrapModes.y==3;
}
else
{
l9_8=l9_7;
}
float param_13=l9_6;
sc_ClampUV(uv.y,uvMinMax.y,uvMinMax.w,l9_8,param_13);
l9_3=param_13;
}
else
{
l9_3=1.0;
}
uv=sc_TransformUV(uv,useUvTransform,uvTransform);
float param_20=l9_3;
sc_SoftwareWrapLate(uv.x,softwareWrapModes.x,l9_2,param_20);
sc_SoftwareWrapLate(uv.y,softwareWrapModes.y,l9_2,param_20);
float l9_9=param_20;
vec4 l9_10=sc_SampleViewLevel(samplerDims,uv,renderingLayout,viewIndex,level_,texture_sampler_);
vec4 l9_11;
if (useClampToBorder)
{
l9_11=mix(borderColor,l9_10,vec4(l9_9));
}
else
{
l9_11=l9_10;
}
return l9_11;
}
int renderTarget1GetStereoViewIndex()
{
int l9_0;
#if (renderTarget1HasSwappedViews)
{
l9_0=1-sc_GetStereoViewIndex();
}
#else
{
l9_0=sc_GetStereoViewIndex();
}
#endif
return l9_0;
}
int renderTarget2GetStereoViewIndex()
{
int l9_0;
#if (renderTarget2HasSwappedViews)
{
l9_0=1-sc_GetStereoViewIndex();
}
#else
{
l9_0=sc_GetStereoViewIndex();
}
#endif
return l9_0;
}
int renderTarget3GetStereoViewIndex()
{
int l9_0;
#if (renderTarget3HasSwappedViews)
{
l9_0=1-sc_GetStereoViewIndex();
}
#else
{
l9_0=sc_GetStereoViewIndex();
}
#endif
return l9_0;
}
vec4 ssEncodeFloat32(float Value,float Min,float Max,float RemapRange)
{
vec4 l9_0=fract(vec4(1.0,255.0,65025.0,16581375.0)*(0.0+(((clamp(Value,Min,Max)-Min)*(RemapRange-0.0))/(Max-Min))));
return l9_0-(l9_0.yzww*vec4(0.0039215689,0.0039215689,0.0039215689,0.0));
}
vec2 ssEncodeFloat16(float Value,float Min,float Max,float RemapRange)
{
vec4 l9_0=fract(vec4(1.0,255.0,65025.0,16581375.0)*(0.0+(((clamp(Value,Min,Max)-Min)*(RemapRange-0.0))/(Max-Min))));
return (l9_0-(l9_0.yzww*vec4(0.0039215689,0.0039215689,0.0039215689,0.0))).xy;
}
void sc_writeFragData0(vec4 col)
{
    sc_FragData0=col;
}
void sc_writeFragData1(vec4 col)
{
#if sc_FragDataCount>=2
    sc_FragData1=col;
#endif
}
void sc_writeFragData2(vec4 col)
{
#if sc_FragDataCount>=3
    sc_FragData2=col;
#endif
}
void sc_writeFragData3(vec4 col)
{
#if sc_FragDataCount>=4
    sc_FragData3=col;
#endif
}
void main()
{
#if ((sc_StereoRenderingMode==1)&&(sc_StereoRendering_IsClipDistanceEnabled==0))
{
if (varClipDistance<0.0)
{
discard;
}
}
#endif
#if (renderTarget0Layout==2)
{
}
#else
{
}
#endif
#if (renderTarget1Layout==2)
{
}
#else
{
}
#endif
#if (renderTarget2Layout==2)
{
}
#else
{
}
#endif
#if (renderTarget3Layout==2)
{
}
#else
{
}
#endif
vec4 l9_0;
vec4 l9_1;
vec4 l9_2;
vec4 l9_3;
if ((overrideTimeEnabled==1)&&(overrideTimeDelta==0.0))
{
vec4 l9_4;
#if (renderTarget0Layout==2)
{
l9_4=sc_SampleTextureLevel(renderTarget0Dims.xy,renderTarget0Layout,renderTarget0GetStereoViewIndex(),varPackedTex.xy,(int(SC_USE_UV_TRANSFORM_renderTarget0)!=0),renderTarget0Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget0,SC_SOFTWARE_WRAP_MODE_V_renderTarget0),(int(SC_USE_UV_MIN_MAX_renderTarget0)!=0),renderTarget0UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget0)!=0),renderTarget0BorderColor,0.0,renderTarget0ArrSC);
}
#else
{
l9_4=sc_SampleTextureLevel(renderTarget0Dims.xy,renderTarget0Layout,renderTarget0GetStereoViewIndex(),varPackedTex.xy,(int(SC_USE_UV_TRANSFORM_renderTarget0)!=0),renderTarget0Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget0,SC_SOFTWARE_WRAP_MODE_V_renderTarget0),(int(SC_USE_UV_MIN_MAX_renderTarget0)!=0),renderTarget0UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget0)!=0),renderTarget0BorderColor,0.0,renderTarget0);
}
#endif
vec4 l9_5;
#if (renderTarget1Layout==2)
{
l9_5=sc_SampleTextureLevel(renderTarget1Dims.xy,renderTarget1Layout,renderTarget1GetStereoViewIndex(),varPackedTex.xy,(int(SC_USE_UV_TRANSFORM_renderTarget1)!=0),renderTarget1Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget1,SC_SOFTWARE_WRAP_MODE_V_renderTarget1),(int(SC_USE_UV_MIN_MAX_renderTarget1)!=0),renderTarget1UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget1)!=0),renderTarget1BorderColor,0.0,renderTarget1ArrSC);
}
#else
{
l9_5=sc_SampleTextureLevel(renderTarget1Dims.xy,renderTarget1Layout,renderTarget1GetStereoViewIndex(),varPackedTex.xy,(int(SC_USE_UV_TRANSFORM_renderTarget1)!=0),renderTarget1Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget1,SC_SOFTWARE_WRAP_MODE_V_renderTarget1),(int(SC_USE_UV_MIN_MAX_renderTarget1)!=0),renderTarget1UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget1)!=0),renderTarget1BorderColor,0.0,renderTarget1);
}
#endif
vec4 l9_6;
#if (renderTarget2Layout==2)
{
l9_6=sc_SampleTextureLevel(renderTarget2Dims.xy,renderTarget2Layout,renderTarget2GetStereoViewIndex(),varPackedTex.xy,(int(SC_USE_UV_TRANSFORM_renderTarget2)!=0),renderTarget2Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget2,SC_SOFTWARE_WRAP_MODE_V_renderTarget2),(int(SC_USE_UV_MIN_MAX_renderTarget2)!=0),renderTarget2UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget2)!=0),renderTarget2BorderColor,0.0,renderTarget2ArrSC);
}
#else
{
l9_6=sc_SampleTextureLevel(renderTarget2Dims.xy,renderTarget2Layout,renderTarget2GetStereoViewIndex(),varPackedTex.xy,(int(SC_USE_UV_TRANSFORM_renderTarget2)!=0),renderTarget2Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget2,SC_SOFTWARE_WRAP_MODE_V_renderTarget2),(int(SC_USE_UV_MIN_MAX_renderTarget2)!=0),renderTarget2UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget2)!=0),renderTarget2BorderColor,0.0,renderTarget2);
}
#endif
vec4 l9_7;
#if (renderTarget3Layout==2)
{
l9_7=sc_SampleTextureLevel(renderTarget3Dims.xy,renderTarget3Layout,renderTarget3GetStereoViewIndex(),varPackedTex.xy,(int(SC_USE_UV_TRANSFORM_renderTarget3)!=0),renderTarget3Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget3,SC_SOFTWARE_WRAP_MODE_V_renderTarget3),(int(SC_USE_UV_MIN_MAX_renderTarget3)!=0),renderTarget3UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget3)!=0),renderTarget3BorderColor,0.0,renderTarget3ArrSC);
}
#else
{
l9_7=sc_SampleTextureLevel(renderTarget3Dims.xy,renderTarget3Layout,renderTarget3GetStereoViewIndex(),varPackedTex.xy,(int(SC_USE_UV_TRANSFORM_renderTarget3)!=0),renderTarget3Transform,ivec2(SC_SOFTWARE_WRAP_MODE_U_renderTarget3,SC_SOFTWARE_WRAP_MODE_V_renderTarget3),(int(SC_USE_UV_MIN_MAX_renderTarget3)!=0),renderTarget3UvMinMax,(int(SC_USE_CLAMP_TO_BORDER_renderTarget3)!=0),renderTarget3BorderColor,0.0,renderTarget3);
}
#endif
l9_3=l9_7;
l9_2=l9_6;
l9_1=l9_5;
l9_0=l9_4;
}
else
{
int l9_8=int(floor(Interp_Particle_Coord.x*3.0));
float l9_9;
float l9_10;
float l9_11;
float l9_12;
float l9_13;
float l9_14;
float l9_15;
float l9_16;
float l9_17;
float l9_18;
float l9_19;
float l9_20;
float l9_21;
float l9_22;
float l9_23;
float l9_24;
if (l9_8==0)
{
vec4 l9_25=ssEncodeFloat32(Interp_Particle_Position.x,-1000.0,1000.0,0.99998999);
vec4 l9_26=ssEncodeFloat32(Interp_Particle_Position.y,-1000.0,1000.0,0.99998999);
vec4 l9_27=ssEncodeFloat32(Interp_Particle_Position.z,-1000.0,1000.0,0.99998999);
vec4 l9_28=ssEncodeFloat32(Interp_Particle_Velocity.x,-1000.0,1000.0,0.99998999);
l9_24=l9_28.w;
l9_23=l9_28.z;
l9_22=l9_28.y;
l9_21=l9_28.x;
l9_20=l9_27.w;
l9_19=l9_27.z;
l9_18=l9_27.y;
l9_17=l9_27.x;
l9_16=l9_26.w;
l9_15=l9_26.z;
l9_14=l9_26.y;
l9_13=l9_26.x;
l9_12=l9_25.w;
l9_11=l9_25.z;
l9_10=l9_25.y;
l9_9=l9_25.x;
}
else
{
float l9_29;
float l9_30;
float l9_31;
float l9_32;
float l9_33;
float l9_34;
float l9_35;
float l9_36;
float l9_37;
float l9_38;
float l9_39;
float l9_40;
float l9_41;
float l9_42;
float l9_43;
float l9_44;
if (l9_8==1)
{
vec4 l9_45=ssEncodeFloat32(Interp_Particle_Velocity.y,-1000.0,1000.0,0.99998999);
vec4 l9_46=ssEncodeFloat32(Interp_Particle_Velocity.z,-1000.0,1000.0,0.99998999);
vec4 l9_47=ssEncodeFloat32(Interp_Particle_Life,0.0,3.0,0.99998999);
vec4 l9_48=ssEncodeFloat32(Interp_Particle_Age,0.0,3.0,0.99998999);
l9_44=l9_48.w;
l9_43=l9_48.z;
l9_42=l9_48.y;
l9_41=l9_48.x;
l9_40=l9_47.w;
l9_39=l9_47.z;
l9_38=l9_47.y;
l9_37=l9_47.x;
l9_36=l9_46.w;
l9_35=l9_46.z;
l9_34=l9_46.y;
l9_33=l9_46.x;
l9_32=l9_45.w;
l9_31=l9_45.z;
l9_30=l9_45.y;
l9_29=l9_45.x;
}
else
{
float l9_49;
float l9_50;
float l9_51;
float l9_52;
float l9_53;
float l9_54;
float l9_55;
float l9_56;
float l9_57;
float l9_58;
float l9_59;
float l9_60;
float l9_61;
float l9_62;
float l9_63;
float l9_64;
if (l9_8==2)
{
vec2 l9_65=ssEncodeFloat16(Interp_Particle_Size,0.0,100.0,0.99998999);
vec2 l9_66=ssEncodeFloat16(Interp_Particle_Quaternion.x,-1.0,1.0,0.99998999);
vec2 l9_67=ssEncodeFloat16(Interp_Particle_Quaternion.y,-1.0,1.0,0.99998999);
vec2 l9_68=ssEncodeFloat16(Interp_Particle_Quaternion.z,-1.0,1.0,0.99998999);
vec2 l9_69=ssEncodeFloat16(Interp_Particle_Quaternion.w,-1.0,1.0,0.99998999);
vec2 l9_70=ssEncodeFloat16(Interp_Particle_Mass,0.0,100.0,0.99998999);
l9_64=0.0+(((clamp(Interp_Particle_Color.w,0.0,1.00001)-0.0)*(1.0-0.0))/(1.00001-0.0));
l9_63=0.0+(((clamp(Interp_Particle_Color.z,0.0,1.00001)-0.0)*(1.0-0.0))/(1.00001-0.0));
l9_62=0.0+(((clamp(Interp_Particle_Color.y,0.0,1.00001)-0.0)*(1.0-0.0))/(1.00001-0.0));
l9_61=0.0+(((clamp(Interp_Particle_Color.x,0.0,1.00001)-0.0)*(1.0-0.0))/(1.00001-0.0));
l9_60=l9_70.y;
l9_59=l9_70.x;
l9_58=l9_69.y;
l9_57=l9_69.x;
l9_56=l9_68.y;
l9_55=l9_68.x;
l9_54=l9_67.y;
l9_53=l9_67.x;
l9_52=l9_66.y;
l9_51=l9_66.x;
l9_50=l9_65.y;
l9_49=l9_65.x;
}
else
{
l9_64=0.0;
l9_63=0.0;
l9_62=0.0;
l9_61=0.0;
l9_60=0.0;
l9_59=0.0;
l9_58=0.0;
l9_57=0.0;
l9_56=0.0;
l9_55=0.0;
l9_54=0.0;
l9_53=0.0;
l9_52=0.0;
l9_51=0.0;
l9_50=0.0;
l9_49=0.0;
}
l9_44=l9_64;
l9_43=l9_63;
l9_42=l9_62;
l9_41=l9_61;
l9_40=l9_60;
l9_39=l9_59;
l9_38=l9_58;
l9_37=l9_57;
l9_36=l9_56;
l9_35=l9_55;
l9_34=l9_54;
l9_33=l9_53;
l9_32=l9_52;
l9_31=l9_51;
l9_30=l9_50;
l9_29=l9_49;
}
l9_24=l9_44;
l9_23=l9_43;
l9_22=l9_42;
l9_21=l9_41;
l9_20=l9_40;
l9_19=l9_39;
l9_18=l9_38;
l9_17=l9_37;
l9_16=l9_36;
l9_15=l9_35;
l9_14=l9_34;
l9_13=l9_33;
l9_12=l9_32;
l9_11=l9_31;
l9_10=l9_30;
l9_9=l9_29;
}
vec4 l9_71=vec4(l9_9,l9_10,l9_11,l9_12);
vec4 l9_72=vec4(l9_13,l9_14,l9_15,l9_16);
vec4 l9_73=vec4(l9_17,l9_18,l9_19,l9_20);
vec4 l9_74=vec4(l9_21,l9_22,l9_23,l9_24);
vec4 l9_75;
if (dot(((l9_71+l9_72)+l9_73)+l9_74,vec4(0.23454))==0.34231836)
{
l9_75=l9_71+vec4(1e-06);
}
else
{
l9_75=l9_71;
}
l9_3=l9_74;
l9_2=l9_73;
l9_1=l9_72;
l9_0=l9_75;
}
sc_writeFragData0(l9_0);
sc_writeFragData1(l9_1);
sc_writeFragData2(l9_2);
sc_writeFragData3(l9_3);
}
#endif // #elif defined FRAGMENT_SHADER // #if defined VERTEX_SHADER
