#include "Common.cginc"
#include "Packages/jp.keijiro.pcx/Runtime/Shaders/Common.cginc"

float4x4 _Offset;
float _PointSize;
float3 _Emission1;
float3 _Emission2;
float3 _Emission3;
float _LocalTime;

struct Attributes
{
    float4 position : POSITION;
    float3 color : COLOR;
};

struct Varyings
{
    float4 position : SV_POSITION;
    float4 color : COLOR;     // RGB, Emission
    float2 params : TEXCOORD; // Random, Scale
};

// Vertex phase
Varyings Vertex(uint vid : SV_VertexID, Attributes input)
{
    float4 pos = input.position;
    float3 col = input.color;

    pos = mul(_Offset, pos);
    col = GammaToLinearSpace(col);

    float delay = saturate(length(pos.xz) * 0.04);
    float param = saturate(frac(_LocalTime / 5) * 1.5 - 0.1 - 0.26 * delay);

    float scale = lerp(0.1, 1, smoothstep(1.0 / 3, 2.0 / 3, param));

    //float rr = lerp(40, 100, Random(vid * 2 + 38943));
    float p = min(param, sqrt((pos.y + 2) / 50));
    float y = pos.y - p * p * 50;
    pos.y = lerp(y, pos.y, smoothstep(2.0 / 3, 1, param));

    float p2 = p * (1 - smoothstep(2.0 / 3, 1, param));
    pos.x += lerp(-1, 1, Random(vid * 3 + 1)) * p2 * 6;
    pos.z += lerp(-1, 1, Random(vid * 3 + 2)) * p2 * 6;

    pos.xyz *= scale;

    float em = smoothstep(0, 0.1, param);
    em += smoothstep(0.1, 1.0 / 3, param);
    em += smoothstep(2.0 / 3, 1, param);

    scale = lerp(0.1, 1, smoothstep(2.0 / 3, 1, param));

    Varyings o;
    o.position = UnityObjectToClipPos(pos);
    o.color = float4(col, em);
    o.params = float2(Random(vid * 3), scale);
    return o;
}

// Geometry phase
[maxvertexcount(36)]
void Geometry(point Varyings input[1], inout TriangleStream<Varyings> outStream)
{
    float4 origin = input[0].position;
    float2 extent = abs(UNITY_MATRIX_P._11_22 * _PointSize * input[0].params.y);

    // Copy the basic information.
    Varyings o = input[0];

    // Determine the number of slices based on the radius of the
    // point on the screen.
    float radius = extent.y / origin.w * _ScreenParams.y;
    uint slices = min((radius + 1) / 5, 4) + 2;

    // Slightly enlarge quad points to compensate area reduction.
    // Hopefully this line would be complied without branch.
    if (slices == 2) extent *= 1.2;

    // Top vertex
    o.position.y = origin.y + extent.y;
    o.position.xzw = origin.xzw;
    outStream.Append(o);

    UNITY_LOOP for (uint i = 1; i < slices; i++)
    {
        float sn, cs;
        sincos(UNITY_PI / slices * i, sn, cs);

        // Right side vertex
        o.position.xy = origin.xy + extent * float2(sn, cs);
        outStream.Append(o);

        // Left side vertex
        o.position.x = origin.x - extent.x * sn;
        outStream.Append(o);
    }

    // Bottom vertex
    o.position.x = origin.x;
    o.position.y = origin.y - extent.y;
    outStream.Append(o);

    outStream.RestartStrip();
}

float4 Fragment(Varyings input) : SV_Target
{
    float3 col = input.color.rgb;
    float em = input.color.a;
    col = lerp(col, _Emission1, saturate(em));
    col = lerp(col, lerp(_Emission2, _Emission3, input.params.x > 0.95), saturate(em - 1));
    col = lerp(col, input.color.rgb, saturate(em - 2));
    return float4(col, 1);
}

