#include "common_vs_fxc.h"

// Our default vertex data input structure
struct VS_INPUT
{
	float4 vPos : POSITION;
	float4 vTexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
	float4 proj_pos : POSITION; // Screen space position
	float2 uv : TEXCOORD0;		// World space position
	float depth : TEXCOORD1;
};

// The code below runs for every vertex in the model
VS_OUTPUT main(VS_INPUT vert)
{
	// Model space -> World space calculation
	float3 world_pos;
	SkinPosition(0, vert.vPos, 0, 0, world_pos);

	// World space -> Screen space calculation
	float4 proj_pos = mul(float4(world_pos, 1), cViewProj);

	float minDist = cAmbientCubeX[0].x;
	float maxDist = cAmbientCubeX[0].y;

	float dist = distance(world_pos, cEyePos);
	float normalizedDist = (dist - minDist) / (maxDist - minDist);

	VS_OUTPUT output = (VS_OUTPUT)0;
	output.proj_pos = proj_pos;
	output.uv = vert.vTexCoord.xy;
    output.depth = saturate(1.0 - normalizedDist);

	return output;
};