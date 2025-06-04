Shader "Custom/Ward_VertexLit_Clean"
{
    Properties
    {
        _BaseColour("Base (RGB)", Color) = (1,1,1,1)
        _SpecularTint("Specular Tint", Color) = (1,1,1,1)
        _Specular("Specular", Range(0.0,1.0)) = 0.5
        _Roughness("Roughness", Range(0.01,1.0)) = 0.5
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 _BaseColour;
            float4 _SpecularTint;
            float _Specular;
            float _Roughness;
            float4 _LightColor0;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 col : COLOR;
            };

            v2f vert(appdata v)
            {
                v2f o;
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 N = normalize(UnityObjectToWorldNormal(v.normal));
                float3 V = normalize(_WorldSpaceCameraPos - worldPos);

                float3 L;
                float attenuation;

                if (_WorldSpaceLightPos0.w == 0.0)
                {
                    // directional light
                    L = normalize(_WorldSpaceLightPos0.xyz);
                    attenuation = 1.0;
                }
                else
                {
                    float3 lightVec = _WorldSpaceLightPos0.xyz - worldPos;
                    float dist = length(lightVec);
                    L = normalize(lightVec);
                    attenuation = 1.0 / (dist * dist);
                }

                float3 H = normalize(L + V);
                float NdotL = max(dot(N, L), 0.0);
                float NdotV = max(dot(N, V), 0.001);
                float NdotH = max(dot(N, H), 0.001);

                float tanThetaH = sqrt(1.0 - NdotH * NdotH) / NdotH;
                float alpha = max(_Roughness, 0.01);
                float exponent = -(tanThetaH * tanThetaH) / (alpha * alpha);
                float denom = 4.0 * UNITY_PI * alpha * alpha * sqrt(NdotL * NdotV);
                float3 wardSpec = exp(exponent) / denom * _SpecularTint.rgb * _Specular;

                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * _BaseColour.rgb;
                float3 diffuse = _BaseColour.rgb * NdotL * _LightColor0.rgb;
                float3 color = ambient + attenuation * (diffuse + wardSpec);

                o.col = float4(saturate(color), 1.0);
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return i.col;
            }

            ENDCG
        }
    }
}
