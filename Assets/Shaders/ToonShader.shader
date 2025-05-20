Shader "Custom/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _ShadeColor ("Shade Color", Color) = (0.1, 0.1, 0.1, 1)
        _Threshold ("Shade Threshold", Range(0,1)) = 0.5
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
                float3 worldLightDir : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float4 _ShadeColor;
            float _Threshold;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float NdotL = dot(normalize(i.worldNormal), i.worldLightDir);

                // Toon lighting: apply step threshold
                float toonShade = step(_Threshold, NdotL);

                fixed4 texColor = tex2D(_MainTex, i.uv) * _Color;
                fixed4 finalColor = lerp(_ShadeColor, texColor, toonShade);

                return finalColor;
            }
            ENDCG
        }
    }

    FallBack "Diffuse"
}
