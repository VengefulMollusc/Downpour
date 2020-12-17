// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/groundSurface"
{
    Properties
    {
        _Tess ("Tessellation", Range(1,8)) = 4
        _TessMin ("Tessellation Min Distance", float) = 5
        _TessMax ("Tessellation Max Distance", float) = 20
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _NoiseScale ("Noise Scale", float) = 1
        _NoiseFrequency ("Noise Frequency", float) = 1
        _NoiseOffset ("Noise Offset", Vector) = (0,0,0,0)
        _NoisePower ("Noise Power function", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows tessellate:tess vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 4.6

        #include "Tessellation.cginc"
        #include "noiseSimplex.cginc"

        struct appdata {
            float4 vertex : POSITION;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD0;
        };

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        float _Tess, _TessMin, _TessMax;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float _NoiseScale, _NoiseFrequency, _NoisePower;
        float4 _NoiseOffset;

        float4 tess(appdata v0, appdata v1, appdata v2) {
            return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, _TessMin, _TessMax, _Tess);
        }

        void vert(inout appdata v)
        {
            float4 v0 = mul(unity_ObjectToWorld, v.vertex);
            float3 bitangent = cross(v.tangent.xyz, v.normal);
            float3 v1 = v0.xyz + (v.tangent.xyz * 0.01);
            float3 v2 = v0.xyz + (bitangent * 0.01);

            float ns0 = _NoiseScale * snoise(float3(v0.x + _NoiseOffset.x, v0.y + _NoiseOffset.y, v0.z + _NoiseOffset.z) * _NoiseFrequency);
            v0.xyz += ((pow(ns0, _NoisePower) + 1) / 2) * v.normal;

            float ns1 = _NoiseScale * snoise(float3(v1.x + _NoiseOffset.x, v1.y + _NoiseOffset.y, v1.z + _NoiseOffset.z) * _NoiseFrequency);
            v1.xyz += ((pow(ns1, _NoisePower) + 1) / 2) * v.normal;

            float ns2 = _NoiseScale * snoise(float3(v2.x + _NoiseOffset.x, v2.y + _NoiseOffset.y, v2.z + _NoiseOffset.z) * _NoiseFrequency);
            v2.xyz += ((pow(ns2, _NoisePower) + 1) / 2) * v.normal;

            float3 vn = cross(v2 - v0.xyz, v1 - v0.xyz);

            v.normal = normalize(vn);
            v.vertex = mul(unity_WorldToObject, v0);

            /*float3 worldVert = mul(unity_ObjectToWorld, v.vertex).xyz;
            float noise = _NoiseScale * snoise(float3(worldVert.x + _NoiseOffset.x, worldVert.y + _NoiseOffset.y, worldVert.z + _NoiseOffset.z) * _NoiseFrequency);
            v.vertex.y += pow(noise, _NoisePower);*/
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
