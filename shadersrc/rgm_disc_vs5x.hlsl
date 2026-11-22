const float4 cEyePosWaterZ				: register(c2);
#define cEyePos			cEyePosWaterZ.xyz
const float4x4 cViewProj				: register(c8);

const float3 cAmbientCubeX [ 2 ] : register ( c21 ) ;
const float3 cAmbientCubeY [ 2 ] : register ( c23 ) ;
const float3 cAmbientCubeZ [ 2 ] : register ( c25 ) ;

// Our default vertex data input structure
struct VS_INPUT
{
	float4 vPos : POSITION;
	float2 uv : TEXCOORD0;
};

struct VS_OUTPUT
{
	float4 projPos : SV_Position; // Screen space position
	float2 uv : TEXCOORD0;		// World space position
	float depth : TEXCOORD1;
};

// The code below runs for every vertex in the model
VS_OUTPUT main(VS_INPUT v)
{
	// World space -> Screen space calculation
	float4 projPos = mul(v.vPos, cViewProj);

	float minDist = cAmbientCubeX[0].x;
	float maxDist = cAmbientCubeX[0].y;

	float dist = distance(v.vPos, cEyePos);
	float normalizedDist = (dist - minDist) / (maxDist - minDist);

	VS_OUTPUT output = (VS_OUTPUT)0;
	output.projPos = projPos;
	output.uv = v.uv;
    output.depth = saturate(1.0 - normalizedDist);

	return output;
};