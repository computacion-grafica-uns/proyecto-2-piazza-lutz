Shader "Custom/WardWithLights"
{
    Properties
    {
        _Maintex("Texture", 2D) = "white" {}

        _DirectionalLightIntensity("Directional Light Intensity", Color) = (0.5,0.5,0.5,1)
        _DirectionalLightDirection_w("Directional Light Direction", Vector) = (0,-1,0,0)

        _PuntualLightIntensity("Puntual Light Intensity", Color) = (1,1,1,1)
        _PuntualLightPosition_w("Puntual Light Position", Vector) = (0,5,0,1)

        _SpotLightIntensity("Spot Light Intensity", Color) = (1,1,1,1)
        _SpotLightPosition_w("Spot Light Position", Vector) = (0,5,0,1)
        _SpotLightDirection_w("Spot Light Direction", Vector) = (0,-1,0,0)
        _CircleRadius("Spotlight Size", Range(0,1)) = 0.25

        _AmbientLight("Ambient Light", Color) = (0.2,0.2,0.2,1)

        // Material
        _MaterialKa("Ka", Color) = (1,0,0,1)
        _MaterialKd("Kd", Color) = (1,0,0,1)
        _MaterialKs("Ks", Color) = (1,1,1,1)
        _AlphaX("Alpha X (roughness)", float) = 0.3
        _AlphaY("Alpha Y (roughness)", float) = 0.3
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

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangent: TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float2 uv : TEXCOORD0;
                float3 worldTangent : TEXCOORD3;
            };

            sampler2D _Maintex;

            float4 _PuntualLightIntensity, _PuntualLightPosition_w;
            float4 _DirectionalLightIntensity, _DirectionalLightDirection_w;
            float4 _SpotLightIntensity, _SpotLightPosition_w, _SpotLightDirection_w;
            float _CircleRadius;

            float4 _AmbientLight;
            float4 _MaterialKa, _MaterialKd, _MaterialKs;
            float _AlphaX, _AlphaY;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                o.uv = v.uv;
                return o;
            }

            float3 wardSpecular(float3 L, float3 V, float3 N)
            {
                float3 H = normalize(L + V);
                float3 X = normalize(cross(N, float3(0.0, 1.0, 0.0)));
                float3 Y = cross(X, N);

                float3 H_proj = normalize(H - dot(H, N) * N);
                float hx = dot(H_proj, X);
                float hy = dot(H_proj, Y);

                float alpha = (hx * hx) / (_AlphaX * _AlphaX) + (hy * hy) / (_AlphaY * _AlphaY);
                float NdotL = max(dot(N, L), 0);
                float NdotV = max(dot(N, V), 0);
                float NdotH = max(dot(N, H), 0);

                float exponent = (-2.0 * alpha) / (1.0 + NdotH);
                float denom = 4 * UNITY_PI * _AlphaX * _AlphaY * sqrt(max((NdotL * NdotV),1e-5)) ;

                return _MaterialKs.rgb * exp(exponent) / denom;
            }

            float3 ComputeLighting(float3 L, float3 lightColor, float3 N, float3 V, float attenuation, float3 colorTextura)
            {
                float NdotL = max(0, dot(N, L));
                float3 diffuse = _MaterialKd.rgb * lightColor * NdotL;
                float3 specular = wardSpecular(L, V, N) * lightColor * colorTextura;
                return attenuation * (diffuse * colorTextura + specular);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 N = normalize(i.normal);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 X = normalize(i.worldTangent);
                float3 Y = cross(X, N);

                float3 color = _AmbientLight.rgb * _MaterialKa.rgb;
                float3 texColor = tex2D(_Maintex, i.uv).rgb;

                // Luz puntual
                float3 Lp = _PuntualLightPosition_w.xyz - i.worldPos;
                float distP = length(Lp);
                float attenP = 1.0 / (1.0 + distP * distP);
                color += ComputeLighting(normalize(Lp), _PuntualLightIntensity.rgb, N, V, attenP, texColor);

                // Luz direccional
                float3 Ld = normalize(-_DirectionalLightDirection_w.xyz);
                color += ComputeLighting(Ld, _DirectionalLightIntensity.rgb, N, V, 1.0, texColor);

                // Luz spot
                float3 Ls = _SpotLightPosition_w.xyz - i.worldPos;
                float3 spotDir = normalize(-_SpotLightDirection_w.xyz);
                float3 Ls_norm = normalize(Ls);
                float theta = dot(Ls_norm, spotDir);
                float attenS = step(1 - _CircleRadius, theta) / (1.0 + dot(Ls, Ls));
                color += ComputeLighting(Ls_norm, _SpotLightIntensity.rgb, N, V, attenS, texColor);

                return float4(color , 1.0);
            }
            ENDCG
        }
    }
}