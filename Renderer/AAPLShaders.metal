/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Include header shared between this Metal shader code and C code executing Metal API commands
#import "AAPLShaderTypes.h"

// Vertex shader outputs and per-fragment inputs. Includes clip-space position and vertex outputs
//  interpolated by rasterizer and fed to each fragment generated by clip-space primitives.
//typedef struct
//{
//    // The [[position]] attribute qualifier of this member indicates this value is the clip space
//    //   position of the vertex wen this structure is returned from the vertex shader
//    float4 clipSpacePosition [[position]];
//
//    // Since this member does not have a special attribute qualifier, the rasterizer will
//    //   interpolate its value with values of other vertices making up the triangle and
//    //   pass that interpolated value to the fragment shader for each fragment in that triangle;
//    float2 textureCoordinate;
//
//} RasterizerData;

//struct xlatMtlShaderInput1
//{
//    float2 position [[attribute(0)]];
//    float2 texcoord [[attribute(1)]];
//};
//
//struct xlatMtlShaderOutput1 {
//    float4 gl_Position [[position]];
//    float2 v_texCoord;
//};
//
//struct xlatMtlShaderUniform1 {
//    uint2 viewportSize;
//};
//
//// Vertex Function
//vertex xlatMtlShaderOutput1
//xlatMtlMain1(const xlatMtlShaderInput1 vertexIn [[stage_in]],
//             constant xlatMtlShaderUniform1& viewportSizePointer  [[ buffer(1) ]])
//
//{
//
//    xlatMtlShaderOutput1 out;
//
//    // Index into our array of positions to get the current vertex
//    //   Our positions are specified in pixel dimensions (i.e. a value of 100 is 100 pixels from
//    //   the origin)
//    //float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
//    float2 pixelSpacePosition = vertexIn.position;
//
//    // Get the size of the drawable so that we can convert to normalized device coordinates,
//    //float2 viewportSize = float2(*viewportSizePointer);
//    float2 viewportSize = float2(viewportSizePointer.viewportSize);
//
//    // The output position of every vertex shader is in clip space (also known as normalized device
//    //   coordinate space, or NDC). A value of (-1.0, -1.0) in clip-space represents the
//    //   lower-left corner of the viewport whereas (1.0, 1.0) represents the upper-right corner of
//    //   the viewport.
//
//    // In order to convert from positions in pixel space to positions in clip space we divide the
//    //   pixel coordinates by half the size of the viewport.
//    out.gl_Position.xy = pixelSpacePosition / (viewportSize / 2.0);
//
//    // Set the z component of our clip space position 0 (since we're only rendering in
//    //   2-Dimensions for this sample)
//    out.gl_Position.z = 0.0;
//
//    // Set the w component to 1.0 since we don't need a perspective divide, which is also not
//    //   necessary when rendering in 2-Dimensions
//    out.gl_Position.w = 1.0;
//
//    // Pass our input textureCoordinate straight to our output RasterizerData. This value will be
//    //   interpolated with the other textureCoordinate values in the vertices that make up the
//    //   triangle.
//    //out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
//    out.v_texCoord = vertexIn.texcoord;
//    return out;
//}
//
//
//// Fragment function
//struct xlatMtlShaderInput2 {
//    float2 v_texCoord;
//};
//
//struct xlatMtlShaderOutput2 {
//    float4 gl_FragColor;
//};
//
//fragment xlatMtlShaderOutput2
//xlatMtlMain2(xlatMtlShaderInput2 _mtl_i [[stage_in]],
//               //texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]]，
//               texture2d<float> u_texture [[texture(0)]], sampler _mtlsmp_u_texture [[sampler(0)]],
//             texture2d<float> u_materialTexture [[texture(1)]], sampler _mtlsmp_u_materialTexture [[sampler(1)]])
//{
////    constexpr sampler textureSampler (mag_filter::linear,
////                                      min_filter::linear);
//
//    xlatMtlShaderOutput2 _mtl_o;
//    // Sample the texture to obtain a color
//    const float4 colorSample = u_texture.sample(_mtlsmp_u_texture, _mtl_i.v_texCoord);
//    const float4 colorSample2 = u_materialTexture.sample(_mtlsmp_u_materialTexture, _mtl_i.v_texCoord);
//
//    // We return the color of the texture
//    //return float4(colorSample);
//    //_mtl_o.gl_FragColor = (float4)colorSample;
//    _mtl_o.gl_FragColor = (float4)mix(colorSample, colorSample2, 0.5);
//    return _mtl_o;
//}

struct xlatMtlShaderInput1 {
    float2 a_position [[attribute(0)]];
    float2 a_texCoord [[attribute(1)]];
};
struct xlatMtlShaderOutput1 {
    float4 gl_Position [[position]];
    float2 v_texCoord;
};
struct xlatMtlShaderUniform1 {
    int2 viewportSize;
};
vertex xlatMtlShaderOutput1 xlatMtlMain1 (xlatMtlShaderInput1 _mtl_i [[stage_in]], constant xlatMtlShaderUniform1& _mtl_u [[buffer(1)]])
{
    xlatMtlShaderOutput1 _mtl_o;
    float2 pixelSpaceLocation_1 = 0;
    float2 tmpvar_2 = 0;
    tmpvar_2 = float2(_mtl_u.viewportSize).xy;
    float2 tmpvar_3 = 0;
    tmpvar_3 = (_mtl_i.a_position / (tmpvar_2 / 2.0));
    pixelSpaceLocation_1 = tmpvar_3;
    float4 tmpvar_4 = 0;
    tmpvar_4.zw = float2(0.0, 1.0);
    tmpvar_4.xy = pixelSpaceLocation_1.xy;
    _mtl_o.gl_Position = tmpvar_4;
    _mtl_o.v_texCoord = _mtl_i.a_texCoord;
    return _mtl_o;
}



struct xlatMtlShaderInput2 {
    float2 v_texCoord;
};
struct xlatMtlShaderOutput2 {
    float4 gl_FragColor;
};
struct xlatMtlShaderUniform2 {
};
float blendSoftLight (
                      float base_1,
                      float blend_2
                      )
{
    float tmpvar_3 = 0;
    if ((blend_2 < 0.5)) {
        tmpvar_3 = (((2.0 * base_1) * blend_2) + ((base_1 * base_1) * (1.0 -
                                                                       (2.0 * blend_2)
                                                                       )));
    } else {
        float tmpvar_4 = 0;
        tmpvar_4 = sqrt (base_1);
        tmpvar_3 = ((tmpvar_4 * (
                                 (2.0 * blend_2)
                                 - 1.0)) + ((2.0 * base_1) * (1.0 - blend_2)));
    };
    return tmpvar_3;
}

fragment xlatMtlShaderOutput2 xlatMtlMain2 (xlatMtlShaderInput2 _mtl_i [[stage_in]], constant xlatMtlShaderUniform2& _mtl_u [[buffer(1)]]
                                            ,   texture2d<float> u_texture [[texture(0)]], sampler _mtlsmp_u_texture [[sampler(0)]]
                                            ,   texture2d<float> u_materialTexture [[texture(1)]], sampler _mtlsmp_u_materialTexture [[sampler(1)]])
{
    xlatMtlShaderOutput2 _mtl_o;
    float3 resultColor_5 = 0;
    float3 srcColor_6 = 0;
    float3 materialColor_7 = 0;
    float4 tmpvar_8 = 0;
    tmpvar_8 = u_materialTexture.sample(_mtlsmp_u_materialTexture, _mtl_i.v_texCoord);
    float3 tmpvar_9 = 0;
    tmpvar_9 = tmpvar_8.xyz;
    materialColor_7 = tmpvar_9;
    float4 tmpvar_10 = 0;
    tmpvar_10 = u_texture.sample(_mtlsmp_u_texture, _mtl_i.v_texCoord);
    float3 tmpvar_11 = 0;
    tmpvar_11 = tmpvar_10.xyz;
    srcColor_6 = tmpvar_11;
    float tmpvar_12 = 0;
    tmpvar_12 = blendSoftLight (materialColor_7.x, srcColor_6.x);
    resultColor_5.x = tmpvar_12;
    float tmpvar_13 = 0;
    tmpvar_13 = blendSoftLight (materialColor_7.y, srcColor_6.y);
    resultColor_5.y = float2(tmpvar_13).y;
    float tmpvar_14 = 0;
    tmpvar_14 = blendSoftLight (materialColor_7.z, srcColor_6.z);
    resultColor_5.z = float3(tmpvar_14).z;
    float4 tmpvar_15 = 0;
    tmpvar_15.w = 1.0;
    tmpvar_15.xyz = resultColor_5.xyz;
    _mtl_o.gl_FragColor = tmpvar_15;
    return _mtl_o;
}
