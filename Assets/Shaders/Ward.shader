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

    _MaterialKa("Ka", Color) = (1,0,0,1)
    _MaterialKd("Kd", Color) = (1,0,0,1)
    _MaterialKs("Ks", Color) = (1,1,1,1)
    _AlphaX("Alpha X (roughness)", Range(0.01,1)) = 0.3
    _AlphaY("Alpha Y (roughness)", Range(0.01,1)) = 0.3

    _LightScale("Global Light Scale", Range(0,5)) = 1
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

        float _LightScale;

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

            float3 up = abs(N.y) < 0.99 ? float3(0,1,0) : float3(1,0,0);
            float3 X = normalize(cross(up, N));
            float3 Y = cross(X, N);

            float hx = dot(H, X);
            float hy = dot(H, Y);
            float hz = dot(H, N);

            float safeAlphaX = clamp(_AlphaX, 0.01, 1.0);
            float safeAlphaY = clamp(_AlphaY, 0.01, 1.0);

            float tan2Theta = (hx * hx) / (safeAlphaX * safeAlphaX) + (hy * hy) / (safeAlphaY * safeAlphaY);
            tan2Theta /= max(hz * hz, 1e-5);

            float NdotL = max(dot(N, L), 1e-4);
            float NdotV = max(dot(N, V), 1e-4);
            float denom = 4.0 * UNITY_PI * safeAlphaX * safeAlphaY * sqrt(NdotL * NdotV);

            float spec = exp(-tan2Theta) / max(denom, 1e-4);
            return _MaterialKs.rgb * spec;
        }

        float3 ComputeLighting(float3 L, float3 lightColor, float3 N, float3 V, float attenuation, float3 colorTextura)
        {
            float NdotL = max(dot(N, L), 0);
            float3 diffuse = _MaterialKd.rgb * lightColor * NdotL;
            float3 specular = wardSpecular(L, V, N) * lightColor;
            return _LightScale * attenuation * (diffuse * colorTextura + specular);
        }

        fixed4 frag(v2f i) : SV_Target
        {
            float3 N = normalize(i.normal);
            float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

            float3 color = _AmbientLight.rgb * _MaterialKa.rgb;
            float3 texColor = tex2D(_Maintex, i.uv).rgb;

            // Luz puntual
            float3 Lp = _PuntualLightPosition_w.xyz - i.worldPos;
            float dist2P = dot(Lp, Lp);
            float attenP = 1.0 / (0.1 + 0.1 * dist2P);
            color += ComputeLighting(normalize(Lp), _PuntualLightIntensity.rgb, N, V, attenP, texColor);

            // Luz direccional
            float3 Ld = normalize(-_DirectionalLightDirection_w.xyz);
            color += ComputeLighting(Ld, _DirectionalLightIntensity.rgb, N, V, 1.0, texColor);

            // Luz spot
            float3 Ls = _SpotLightPosition_w.xyz - i.worldPos;
            float3 Ls_norm = normalize(Ls);
            float3 spotDir = normalize(-_SpotLightDirection_w.xyz);
            float theta = dot(Ls_norm, spotDir);
            float inner = 1.0 - _CircleRadius;
            float outer = inner - 0.05;
            float spotFactor = smoothstep(outer, inner, theta);
            float attenS = spotFactor / (1.0 + dot(Ls, Ls));
            color += ComputeLighting(Ls_norm, _SpotLightIntensity.rgb, N, V, attenS, texColor);

            return float4(saturate(color), 1.0);
        }
        ENDCG
    }
}
}