Shader "Hidden/PointCloud"
{
    SubShader
    {
        Cull Off
        Pass
        {
            CGPROGRAM
            #pragma vertex Vertex
            #pragma geometry Geometry
            #pragma fragment Fragment
            #include "PointCloud.cginc"
            ENDCG
        }
    }
}
