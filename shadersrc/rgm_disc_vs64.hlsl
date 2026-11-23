cbuffer VertexShaderConstants : register( b0 )
{
	float4 cEyePosWaterZ : packoffset( c2 );
    row_major float4x4 cViewProj : packoffset( c8 );
	
	float3 cAmbientCubeX [ 2 ] : register ( c21 ) ;
	float3 cAmbientCubeY [ 2 ] : register ( c23 ) ;
	float3 cAmbientCubeZ [ 2 ] : register ( c25 ) ;
};

#define cEyePos			cEyePosWaterZ.xyz

struct VS_INPUT
{
	float4 vPos : POSITION;
	float2 uv : TEXCOORD0;
};

struct VS_OUTPUT
{
	float4 projPos : SV_Position;
	float2 uv : TEXCOORD0;
	float depth : TEXCOORD1;
};

VS_OUTPUT main( const VS_INPUT v )
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
}
