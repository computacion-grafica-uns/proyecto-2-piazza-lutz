Shader "Custom/Cook Torrance Multitextura"
{
    Properties
    {
        _Maintex("Base", 2D) = "white" {}
        _Secondtex("Detalle",2d) = "white" {}
        _Blend("Blend", Range(0,1)) = 0.5

        _DirectionalLightIntensity("Directional Light Intensity", Color) = (0,0,0,1)
        _DirectionalLightDirection_w("Directional Light Direction", Vector) = (0,0,0,1)

        _PuntualLightIntensity("Puntual Light Intensity", Color) = (0,0,0,1)
        _PuntualLightPosition_w("Puntual Light Position (World)", Vector) = (0,0,0,1)

        _SpotLightIntensity("Spot Light Intensity", Color) = (0,0,0,1)
        _SpotLightPosition_w("Spot Light Position (World)", Vector) = (0,0,0,1)
        _SpotLightDirection_w("Spot Light Direction (World)", Vector) = (0,0,0,1)
        _CircleRadius("Spot Light size", Range(0,1)) = 0.25

        _AmbientLight("Ambient Light", Color) = (0,0,0,1)

        _BaseColor("Base Color", Color) = (1,0,0,1)
        _Metallic("Metallic", Range(0,1)) = 0.0
        _Roughness("Roughness", Range(0.05,1)) = 0.3

        _CamaraPosition("Camara orbital position", Vector) = (90,90,90)
    }

        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            LOD 100

            Pass
            {
                CGPROGRAM
                #pragma vertex vertexShader
                #pragma fragment fragmentShader
                #include "UnityCG.cginc"

                struct vertexData {
                    float4 position : POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                };

                struct v2f {
                    float4 position : SV_POSITION;
                    float4 position_w : TEXCOORD1;
                    float3 normal_w : TEXCOORD0;
                    float2 uv_Main : TEXCOORD2;
                    float2 uv_Second : TEXCOORD3;
                };

                sampler2D _Maintex;
                float4 _Maintex_ST;

                sampler2D _Secondtex;
                float4 _Secondtex_ST;

                float _Blend;
                float4 _PuntualLightIntensity, _PuntualLightPosition_w;
                float4 _DirectionalLightIntensity, _DirectionalLightDirection_w;
                float4 _SpotLightIntensity, _SpotLightPosition_w, _SpotLightDirection_w;
                float _CircleRadius;
                float4 _AmbientLight;
                float4 _BaseColor;
                float _Metallic, _Roughness;
                float4 _CustomCameraPos;

                v2f vertexShader(vertexData v) {
                    v2f o;
                    o.position = UnityObjectToClipPos(v.position);
                    o.position_w = mul(unity_ObjectToWorld, v.position);
                    o.normal_w = UnityObjectToWorldNormal(v.normal);
                    o.uv_Main = TRANSFORM_TEX(v.uv, _Maintex);
                    o.uv_Second = TRANSFORM_TEX(v.uv, _Secondtex);
                    return o;
                }

                float3 FresnelSchlick(float cosTheta, float3 F0) {
                    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
                }

                float DistributionGGX(float3 N, float3 H, float roughness) {
                    float a = roughness * roughness;
                    float a2 = a * a;
                    float NdotH = max(dot(N, H), 0.05); // aseguramos piso
                    float NdotH2 = NdotH * NdotH;
                    float denom = NdotH2 * (a2 - 1.0) + 1.0;
                    return a2 / (UNITY_PI * denom * denom);
                }

                float GeometrySchlickGGX(float NdotV, float roughness) {
                    float r = roughness + 1.0;
                    float k = (r * r) / 8.0;
                    return NdotV / (NdotV * (1.0 - k) + k);
                }

                float GeometrySmith(float3 N, float3 V, float3 L, float roughness) {
                    float ggx1 = GeometrySchlickGGX(max(dot(N, V), 0.05), roughness);
                    float ggx2 = GeometrySchlickGGX(max(dot(N, L), 0.05), roughness);
                    return ggx1 * ggx2;
                }

                float3 CookTorranceSpecular(float3 N, float3 V, float3 L, float roughness, float3 F0) {
                    float3 H = normalize(V + L);
                    float NdotV = max(dot(N, V), 0.05);
                    float NdotL = max(dot(N, L), 0.05);
                    float HdotV = max(dot(H, V), 0.05);
                    float3 F = FresnelSchlick(HdotV, F0);
                    float D = DistributionGGX(N, H, roughness);
                    float G = GeometrySmith(N, V, L, roughness);
                    return (G * D * F) / (4.0 * NdotV * NdotL + 0.001);
                }

                float3 computeLight(float3 N, float3 V, float3 L, float3 lightColor, float3 baseColor) {
                    float3 F0 = lerp(0.04, baseColor, _Metallic);
                    float3 H = normalize(V + L);
                    float HdotV = max(dot(H, V), 0.05);
                    float3 F = FresnelSchlick(HdotV, F0);
                    float3 kD = (1.0 - F) * (1.0 - _Metallic);

                    float NdotL = max(dot(N, L), 0.05); // piso m�nimo

                    float3 diffuse = kD * baseColor / UNITY_PI;
                    float3 specular = CookTorranceSpecular(N, V, L, _Roughness, F0);

                    return (diffuse + specular) * lightColor * NdotL;
                }

                fixed4 fragmentShader(v2f f) : SV_Target {
                    float3 N = normalize(f.normal_w);
                    float3 V = normalize(_CustomCameraPos.xyz - f.position_w.xyz);
                    fixed4 tex1 = tex2D(_Maintex, f.uv_Main);
                    fixed4 tex2 = tex2D(_Secondtex, f.uv_Second);
                    float3 texBlended= lerp(tex1.rgb, tex2.rgb, _Blend) * 2;
                    float3 baseColor = texBlended * _BaseColor.rgb;

                    float3 color = _AmbientLight.rgb * baseColor;

                    float3 Lp = normalize(_PuntualLightPosition_w.xyz - f.position_w.xyz);
                    color += computeLight(N, V, Lp, _PuntualLightIntensity.rgb, baseColor);

                    float3 Ld = normalize(-_DirectionalLightDirection_w.xyz);
                    color += computeLight(N, V, Ld, _DirectionalLightIntensity.rgb, baseColor);

                    float3 Ls = normalize(_SpotLightPosition_w.xyz - f.position_w.xyz);
                    float3 spotDir = normalize(-_SpotLightDirection_w.xyz);
                    float att = dot(Ls, spotDir) > 1.0 - _CircleRadius ? 1.0 : 0.0;
                    color += computeLight(N, V, Ls, _SpotLightIntensity.rgb, baseColor) * att;

                    return fixed4(color, 1.0);
                }
                ENDCG
            }
        }
}
