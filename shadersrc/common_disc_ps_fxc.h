#include "common_ps_fxc.h"

float4 WIDTHCOLOR : register(c0);

struct PS_INPUT
{
    #if defined(DX11)
    float4 P            : SV_Position;
    #else
    float2 P            : VPOS;
    #endif
    float2 uv : TEXCOORD0;             // Position on triangle
    float depth : TEXCOORD1;
};

// Helper function for Bias
float bias(float t, float b) {
    return t / ((((1.0/b) - 2.0) * (1.0 - t)) + 1.0);
}

#if defined(DX11)
float4 main( PS_INPUT frag ) : SV_Target
#else
float4 main( PS_INPUT frag ) : COLOR
#endif
{
    float4 color = float4(WIDTHCOLOR.yzw, 1);

    float midPoint = 0.5; 
    float gradient = smoothstep(0.0, 1.0, bias(frag.depth, midPoint));

    float width = WIDTHCOLOR.x;
    float centerRadius = 0.667;
    float edgeSoftness = 0.001;

    float2 p = frag.uv * 2.0 - 1.0;
    float dist = length(p);

    float innerBound = centerRadius - (width * 0.1);
    float outerBound = centerRadius + (width * 0.1);

    float mask = smoothstep(innerBound - edgeSoftness, innerBound, dist) 
                    - smoothstep(outerBound, outerBound + edgeSoftness, dist);

    color.a *= mask;

    #ifdef PARTIAL_RINGS
    if (gradient <= 0.5f) discard;
    #endif

    if (mask <= 0.0) discard;

    return color;
}