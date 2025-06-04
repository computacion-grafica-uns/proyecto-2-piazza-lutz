Shader "Custom/BlingPhong Luces"
{
    Properties
    {
        //Textura
        _Maintex("Texture",2d) = "white" {}
       
        //Propiedades de luz direccional
        _DirectionalLightIntensity("Directional Light Intensity", Color) = (0,0,0,1)
        _DirectionalLightDirection_w("Directional Light Directional", Vector) = (0,0,0,1)

        //Luz puntual
        _PuntualLightIntensity("Puntual Light Intensity", Color) = (0,0,0,1)
        _PuntualLightPosition_w("Puntual Light Position", Vector) = (0,0,0,1)

        //Propiedades de luz spot
        _SpotLightIntensity("Spot LightIntensity", Color) = (0,0,0,1)
        _SpotLightPosition_w("Spot Light Position", Vector) = (0,0,0,1)
        _SpotLightDirection_w("Spot Light Directional", Vector) = (0,0,0,1)
        _CircleRadius("Spot Light size",Range(0,1)) = 0.25

        //Luz ambiental
        _AmbientLight("Ambient Light", Color) = (0,0,0,1)

        //Constantes de los materiales
        _MaterialKa ("MaterialKa", Color) = (0,0,0,1)
        _MaterialKd ("MaterialKd", Color) = (0,0,0,1)
        _MaterialKs ("MaterialKs", Color) = (0,0,0,1)
        _Material_n ("Material_n",float) = 20

        // Posicion camara
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

            struct vertexData
            {
                float4 position : POSITION; //Object space
                float3 normal : Normal; // ObjectSpace
                float2 uv : TEXCOORD3; //texture coordinate
            };

            struct v2f
            {
                float4 position : SV_POSITION; //Clipping Space
                float4 position_w : TEXCOORD1; //World Space
                float3 normal_w : TEXCOORD0; //World Space
                float2 uv : TEXCOORD2; //texture coordinate
            };
            
            sampler2D _Maintex;
            float4 _Maintex_ST;
           
            float4 _PuntualLightIntensity;
            float4 _PuntualLightPosition_w;

            float4 _DirectionalLightIntensity;
            float4 _DirectionalLightDirection_w;

            float4 _SpotLightIntensity;
            float4 _SpotLightPosition_w;
            float4 _SpotLightDirection_w;
            float _CircleRadius;

            float4 _AmbientLight;

            float4 _MaterialKa;
            float4 _MaterialKd;
            float4 _MaterialKs;
            float _Material_n;
            float4 _CustomCameraPos;

        
           v2f vertexShader(vertexData v)
           {
                v2f output;
                output.uv = TRANSFORM_TEX(v.uv, _Maintex);
                output.position = UnityObjectToClipPos(v.position);
                output.position_w = mul(unity_ObjectToWorld, v.position);
                output.normal_w = UnityObjectToWorldNormal(v.normal);
                return output;
           }

           float3 ambientLight()
           {
              float3 ambient = _AmbientLight * _MaterialKa;
              return ambient;
           }

           float3 diffusePuntualLight (v2f f)
           {
               float3 N = normalize(f.normal_w);
               float3 L = normalize(_PuntualLightPosition_w - f.position_w);
               float3 diffuse = _PuntualLightIntensity * _MaterialKd * dot(L, N);
               return diffuse;
           }

           float3 specularPuntualLight(v2f f)
           {
               float3 L = normalize(_PuntualLightPosition_w - f.position_w);
               float3 N = normalize(f.normal_w);
               float3 R = reflect(-L, N);
               float3 V = normalize(_CustomCameraPos - f.position_w);
               float3 specular = _PuntualLightIntensity * _MaterialKs * pow(max(0, dot(R, V)), max(0,_Material_n));
               return specular;
           }

           fixed4 puntualLight(v2f f)
           {
               fixed4 fragColor = 0;
               fixed4 colorTextura1 = tex2D(_Maintex, f.uv);
               //fragColor.rgb = ambientLight() + diffusePuntualLight(f) + specularPuntualLight(f);
               float3 light = ambientLight() + diffusePuntualLight(f) + specularPuntualLight(f);
               fragColor.rgb = light * colorTextura1.rgb;
               return fragColor;
           }

           float3 diffuseDirectionalLight(v2f f)
           {
               float3 N = normalize(f.normal_w);
               float3 L = normalize(-_DirectionalLightDirection_w);
               float NdotL = max (0, dot(N,L));
               float3 diffuse = _DirectionalLightIntensity * _MaterialKd * NdotL;
               return diffuse;
           }

           float3 specularDirectionalLight(v2f f)
           {
               float3 L = normalize(-_DirectionalLightDirection_w);
               float3 N = normalize(f.normal_w);
               float3 R = reflect(L, N);
               float3 V = normalize(_CustomCameraPos - f.position_w);
               float3 specular = _DirectionalLightIntensity * _MaterialKs * pow(max(0, dot(R, V)), max(0, _Material_n));
               return specular;
           }

           fixed4 directionalLight(v2f f)
           {
               fixed4 fragColor = 0;
               fixed4 colorTextura1 = tex2D(_Maintex, f.uv);
               //fragColor.rgb = ambientLight() + diffuseDirectionalLight(f) + specularDirectionalLight(f);
               float3 light = ambientLight() + diffuseDirectionalLight(f) + specularDirectionalLight(f);
               fragColor.rgb = light * colorTextura1.rgb;
               return fragColor;
           }

           float3 diffuseSpotLight(v2f f)
           {
               float3 L = normalize(_SpotLightPosition_w - f.position_w);
               float3 N = normalize(f.normal_w);
               float3 lightDirection = normalize(-_SpotLightDirection_w);
               float3 LdotN = 0;
               if (dot(L, lightDirection) > 1-_CircleRadius)
               {
                   LdotN = dot(L, N) + dot(lightDirection, N);
               }
               float3 diffuse = _SpotLightIntensity * _MaterialKd * LdotN;
               return diffuse;
           }

           float3 specularSpotLight(v2f f)
           {
               float3 L = normalize(_SpotLightPosition_w - f.position_w);
               float3 N = normalize(f.normal_w);
               float3 R = reflect(-L, N);
               float3 V = normalize(_CustomCameraPos - f.position_w);
               float3 lightDirection = normalize(-_SpotLightDirection_w);
               float3 RdotV = 0;
               if (dot(L, lightDirection) > 1-_CircleRadius)
               {
                   RdotV = dot(R, V);
               }
               float3 specular = _SpotLightIntensity * _MaterialKs * pow(max(0, RdotV), max(0, _Material_n));
               return specular;
           }

           fixed4 spotLight(v2f f)
           {
               fixed4 fragColor = 0;
               fixed4 colorTextura1 = tex2D(_Maintex, f.uv);
               //fragColor.rgb = ambientLight() + diffuseSpotLight(f) + specularSpotLight(f);
               float3 light = ambientLight() + diffuseDirectionalLight(f) + specularDirectionalLight(f);
               fragColor.rgb = light * colorTextura1.rgb;
               return fragColor;
           }

           fixed4 fragmentShader(v2f f) : SV_Target
           {
               fixed4 fragColor = puntualLight(f) + 0.75 * directionalLight(f) + spotLight(f);
               return fragColor;
           }
         ENDCG
        }
    }
}