Shader "Custom/MinnaertFull"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1, 0.4, 0.3, 1)
        _MinnaertExponent("Minnaert Exponent", Range(0, 3)) = 0.5

        _AmbientLight("Ambient Light", Color) = (0.1,0.1,0.1,1)

        // Puntual
        _PuntualLightColor("Puntual Light Color", Color) = (1,1,1,1)
        _PuntualLightPos("Puntual Light Pos", Vector) = (0, 5, 0, 1)

        // Direccional
        _DirLightColor("Directional Light Color", Color) = (1,1,1,1)
        _DirLightDir("Directional Light Direction", Vector) = (0,-1,0,0)

        // Spot
        _SpotLightColor("Spot Light Color", Color) = (1,1,1,1)
        _SpotLightPos("Spot Light Pos", Vector) = (0,5,0,1)
        _SpotLightDir("Spot Light Dir", Vector) = (0,-1,0,0)
        _SpotAngle("Spot Angle Limit", Range(0,1)) = 0.75
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
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _BaseColor;
            float _MinnaertExponent;
            float4 _AmbientLight;

            float4 _PuntualLightColor;
            float4 _PuntualLightPos;

            float4 _DirLightColor;
            float4 _DirLightDir;

            float4 _SpotLightColor;
            float4 _SpotLightPos;
            float4 _SpotLightDir;
            float _SpotAngle;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                return o;
            }

            float3 minnaertDiffuse(float3 N, float3 L, float3 V, float3 lightColor)
            {
                float NdotL = max(0, dot(N, L));
                float NdotV = max(0, dot(N, V));
                float factor = pow(NdotV, _MinnaertExponent);
                return NdotL * factor * lightColor;
            }

            float3 punctualLight(v2f i)
            {
                float3 N = normalize(i.normal);
                float3 L = normalize(_PuntualLightPos.xyz - i.worldPos);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                return minnaertDiffuse(N, L, V, _PuntualLightColor.rgb);
            }

            float3 directionalLight(v2f i)
            {
                float3 N = normalize(i.normal);
                float3 L = normalize(-_DirLightDir.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                return minnaertDiffuse(N, L, V, _DirLightColor.rgb);
            }

            float3 spotLight(v2f i)
            {
                float3 L = normalize(_SpotLightPos.xyz - i.worldPos);
                float3 lightDir = normalize(-_SpotLightDir.xyz);
                float3 N = normalize(i.normal);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                float spotFactor = dot(L, lightDir);

                if (spotFactor > _SpotAngle)
                {
                    return minnaertDiffuse(N, L, V, _SpotLightColor.rgb * spotFactor);
                }
                return 0;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 texColor = tex2D(_MainTex, i.uv).rgb;
                float3 diffuse = _AmbientLight.rgb +
                                 punctualLight(i) +
                                 directionalLight(i) +
                                 spotLight(i);

                float3 finalColor = texColor * _BaseColor.rgb * diffuse;

                return float4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}
