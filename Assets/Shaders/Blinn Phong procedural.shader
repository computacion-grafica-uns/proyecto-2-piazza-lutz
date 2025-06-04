Shader "Custom/BlinnPhong_OndasFull"
{
    Properties
    {
        [NoScaleOffset] _Maintex("Texture",2D) = "white" {}

        _DirectionalLightIntensity("Directional Light Intensity", Color) = (1,1,1,1)
        _DirectionalLightDirection_w("Directional Light Direction", Vector) = (0, -1, 0, 0)

        _PuntualLightIntensity("Puntual Light Intensity", Color) = (1,1,1,1)
        _PuntualLightPosition_w("Puntual Light Position", Vector) = (0, 5, 0, 1)

        _SpotLightIntensity("Spot Light Intensity", Color) = (1,1,1,1)
        _SpotLightPosition_w("Spot Light Position", Vector) = (0, 3, 0, 1)
        _SpotLightDirection_w("Spot Light Direction", Vector) = (0, -1, 0, 0)
        _CircleRadius("Spot Light size", Range(0,1)) = 0.5

        _AmbientLight("Ambient Light", Color) = (0.1,0.1,0.1,1)

        _MaterialKa ("Material Ka", Color) = (0.2,0.2,0.2,1)
        _MaterialKd ("Material Kd", Color) = (1,1,1,1)
        _MaterialKs ("Material Ks", Color) = (0.5,0.5,0.5,1)
        _Material_n ("Shininess", float) = 32
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #define TAU 6.28318530718

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 normal_w : TEXCOORD0;
                float4 pos_w : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            sampler2D _Maintex;
            float4 _Maintex_ST;

            float4 _PuntualLightIntensity, _PuntualLightPosition_w;
            float4 _DirectionalLightIntensity, _DirectionalLightDirection_w;
            float4 _SpotLightIntensity, _SpotLightPosition_w, _SpotLightDirection_w;
            float _CircleRadius;
            float4 _AmbientLight;

            float4 _MaterialKa, _MaterialKd, _MaterialKs;
            float _Material_n;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.pos_w = mul(unity_ObjectToWorld, v.vertex);
                o.normal_w = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _Maintex);
                return o;
            }

            float3 CalcLight(float3 N, float3 V, float3 L, float3 lightColor)
            {
                float3 R = reflect(-L, N);
                float NdotL = max(0, dot(N, L));
                float RdotV = max(0, dot(R, V));

                float3 ambient = _AmbientLight.rgb * _MaterialKa.rgb;
                float3 diffuse = lightColor * _MaterialKd.rgb * NdotL;
                float3 specular = lightColor * _MaterialKs.rgb * pow(RdotV, _Material_n);

                return ambient + diffuse + specular;
            }

            float3 CalcSpotAttenuation(float3 L, float3 spotDir)
            {
                return (dot(L, spotDir) > 1.0 - _CircleRadius) ? 1.0 : 0.0;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 N = normalize(i.normal_w);
                float3 V = normalize(_WorldSpaceCameraPos - i.pos_w.xyz);
                fixed4 tex = tex2D(_Maintex, i.uv);

                float3 color = float3(0,0,0);

                float3 Ld = normalize(-_DirectionalLightDirection_w.xyz);
                color += CalcLight(N, V, Ld, _DirectionalLightIntensity.rgb);

                float3 Lp = normalize(_PuntualLightPosition_w.xyz - i.pos_w.xyz);
                color += CalcLight(N, V, Lp, _PuntualLightIntensity.rgb);

                float3 Ls = normalize(_SpotLightPosition_w.xyz - i.pos_w.xyz);
                float3 spotDir = normalize(-_SpotLightDirection_w.xyz);
                float spotAtt = CalcSpotAttenuation(Ls, spotDir);
                color += CalcLight(N, V, Ls, _SpotLightIntensity.rgb) * spotAtt;

                // Ondas animadas procedurales
                float t = cos(i.uv.y * TAU * 2) * 0.5 + 1.0;
                float offset = cos((_Time.y + i.uv.y * t) * TAU * 0.5) * 0.5 + 0.5;
                offset = saturate(offset);

                float3 finalColor = color * tex.rgb;

                // Aplicamos la onda sobre R/G/B de forma estética
                finalColor.r *= offset;
                finalColor.g *= lerp(0.9, 1.0, offset);
                finalColor.b *= lerp(0.7, 1.0, offset);

                return float4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}
