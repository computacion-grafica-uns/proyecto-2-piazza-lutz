Shader "Custom/WardTest_NoLights"
{
    Properties
    {
        _Maintex("Texture", 2D) = "white" {}
        _AlphaX("Alpha X (roughness)", Range(0.01,1)) = 0.3
        _AlphaY("Alpha Y (roughness)", Range(0.01,1)) = 0.3
        _MaterialKs("Specular Color", Color) = (1,1,1,1)
        _Ambient("Ambient", Color) = (0.2,0.2,0.2,1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float2 uv : TEXCOORD0;
                float3 tangent : TEXCOORD3;
            };

            sampler2D _Maintex;
            float4 _MaterialKs;
            float _AlphaX, _AlphaY;
            float4 _Ambient;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
                o.uv = v.uv;
                return o;
            }

            void getOrthonormalBasis(float3 N, out float3 T, out float3 B)
            {
                float3 up = abs(N.y) < 0.999 ? float3(0.0, 1.0, 0.0) : float3(1.0, 0.0, 0.0);
                T = normalize(cross(up, N));
                B = normalize(cross(N, T));
            }

            float3 wardSpecular(float3 L, float3 V, float3 N)
            {
                float3 H = normalize(L + V);

                // Construcción robusta del sistema ortonormal T (tangente) y B (binormal)
                float3 up = abs(N.y) < 0.999 ? float3(0.0, 1.0, 0.0) : float3(1.0, 0.0, 0.0);
                float3 T = normalize(cross(up, N));
                float3 B = normalize(cross(N, T));

                // Proyección de H en la base tangente
                float hx = dot(H, T);
                float hy = dot(H, B);
                float hz = dot(H, N);

                // Clamp de rugosidad para evitar divisiones peligrosas
                float safeAlphaX = clamp(_AlphaX, 0.01, 1.0);
                float safeAlphaY = clamp(_AlphaY, 0.01, 1.0);

                float tan2 = (hx * hx) / (safeAlphaX * safeAlphaX) + (hy * hy) / (safeAlphaY * safeAlphaY);
                tan2 /= max(hz * hz, 1e-5);

                float NdotL = max(dot(N, L), 1e-4);
                float NdotV = max(dot(N, V), 1e-4);
                float denom = 4.0 * UNITY_PI * safeAlphaX * safeAlphaY * sqrt(NdotL * NdotV);

                float spec = exp(-tan2) / max(denom, 1e-4);
                return _MaterialKs.rgb * spec;
            }


            fixed4 frag(v2f i) : SV_Target
            {
                float3 tex = tex2D(_Maintex, i.uv).rgb;
                float3 N = normalize(i.normal);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                float3 L = normalize(float3(0.5, 1.0, 0.5));

                float3 color = _Ambient.rgb * tex;
                float3 spec = wardSpecular(L, V, N);
                return float4(saturate(color + spec), 1.0);
            }
            ENDCG
        }
    }
}
