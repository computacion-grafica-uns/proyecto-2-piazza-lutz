Shader "Custom/ToonShader_LucesCompatible"
{
    Properties
    {
        _Maintex("Texture", 2D) = "white" {}
        _ShadeColor("Shade Color", Color) = (0.1, 0.1, 0.1, 1)

        _MaterialKd("Material Kd (Base Color)", Color) = (1, 1, 1, 1)

        _DirectionalLightDirection_w("Directional Light Directional", Vector) = (0, -1, 0, 0)
        _DirectionalLightIntensity("Directional Light Intensity", Color) = (1, 1, 1, 1)

        _PuntualLightPosition_w("Puntual Light Position", Vector) = (0, 3, 0, 1)
        _PuntualLightIntensity("Puntual Light Intensity", Color) = (1, 1, 1, 1)

        _SpotLightPosition_w("Spot Light Position", Vector) = (0, 3, 0, 1)
        _SpotLightDirection_w("Spot Light Directional", Vector) = (0, -1, 0, 0)
        _SpotLightIntensity("Spot LightIntensity", Color) = (1, 1, 1, 1)
        _CircleRadius("Spot Light size", Range(0,1)) = 0.5
        
        _AmbientLight("Ambient Light", Color) = (0.1, 0.1, 0.1, 1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

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
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            sampler2D _Maintex;
            float4 _Maintex_ST;
            float4 _ShadeColor;
            float4 _MaterialKd;

            float4 _AmbientLight;
            float4 _DirectionalLightDirection_w;
            float4 _DirectionalLightIntensity;
            float4 _PuntualLightPosition_w;
            float4 _PuntualLightIntensity;
            float4 _SpotLightPosition_w;
            float4 _SpotLightDirection_w;
            float4 _SpotLightIntensity;
            float _CircleRadius;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _Maintex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            float3 ToonLighting(v2f i)
            {
                float3 N = normalize(i.worldNormal);

                float3 Ldir = normalize(-_DirectionalLightDirection_w.xyz);
                float diffDir = max(0, dot(N, Ldir));
                float3 directional = diffDir * _DirectionalLightIntensity.rgb;

                float3 Lp = normalize(_PuntualLightPosition_w.xyz - i.worldPos);
                float diffP = max(0, dot(N, Lp));
                float3 punctual = diffP * _PuntualLightIntensity.rgb;

                float3 Ls = normalize(_SpotLightPosition_w.xyz - i.worldPos);
                float3 spotDir = normalize(-_SpotLightDirection_w.xyz);
                float angle = dot(Ls, spotDir);
                float diffS = 0;
                if (angle > 1 - _CircleRadius)
                    diffS = max(0, dot(N, Ls));
                float3 spot = diffS * _SpotLightIntensity.rgb;

                float3 ambient = _AmbientLight.rgb;

                return ambient + directional + punctual + spot;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 totalLight = ToonLighting(i);
                float lightIntensity = saturate(length(totalLight));

                // Toon en 3 bandas con transiciones suaves
                float3 toonLevels = float3(0.3, 0.6, 0.9);
                float3 toonShades = float3(0.2, 0.5, 1.0);

                // Suavizamos cada franja
                float s1 = smoothstep(toonLevels.x - 0.05, toonLevels.x + 0.05, lightIntensity);
                float s2 = smoothstep(toonLevels.y - 0.05, toonLevels.y + 0.05, lightIntensity);
                float s3 = smoothstep(toonLevels.z - 0.05, toonLevels.z + 0.05, lightIntensity);

                // Mezcla ponderada entre bandas
                float shadeFactor = lerp(toonShades.x, toonShades.y, s1);
                shadeFactor = lerp(shadeFactor, toonShades.z, s2 * s3);

                fixed4 texColor = tex2D(_Maintex, i.uv) * _MaterialKd;
                fixed4 finalColor = lerp(_ShadeColor, texColor, shadeFactor);

                return finalColor;
            }
            ENDCG
        }
    }

    FallBack "Diffuse"
}
