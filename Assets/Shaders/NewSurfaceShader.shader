Shader "Custom/BlinnPhongWithProceduralColor"
{
    Properties {
        _Maintex("Texture", 2D) = "white" {}
        _Color("Base Color", Color) = (1,1,1,1)
        _SpecColor("Specular Color", Color) = (1,1,1,1)
        _Shininess("Shininess", Range(1, 128)) = 20
    }

    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _Maintex;
            float4 _Color;
            float4 _SpecColor;
            float _Shininess;
            float4 _LightColor0;

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(appdata v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                float3 N = normalize(i.worldNormal);
                float3 L = normalize(_WorldSpaceLightPos0.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 H = normalize(L + V);

                float NdotL = max(0, dot(N, L));
                float NdotH = max(0, dot(N, H));

                float3 ambient = 0.1 * _Color.rgb;
                float3 diffuse = NdotL * _Color.rgb;
                float3 specular = pow(NdotH, _Shininess) * _SpecColor.rgb;

                float3 lightColor = _LightColor0.rgb;

                // Procedural offset effect
                float t = cos((i.uv.y) * 6.28 * 2) * 0.5 + 0.5;
                float offset = cos((i.uv.y + t + _Time.y) * 6.28 * 5) * 0.5 + 0.5;

                float3 finalColor = (ambient + diffuse + specular) * tex2D(_Maintex, i.uv).rgb;
                finalColor.r += offset * 0.2;
                finalColor.g += offset * 0.1;
                finalColor.b += offset * 0.3;

                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}
