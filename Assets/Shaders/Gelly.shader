// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Jelly" {
    Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
	}
	SubShader {
        Pass {
            Tags { "RenderType"="Opaque" }
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
            struct v2f {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
            };

            v2f vert(appdata_base v) {
                v2f o;

                float4 vertex = v.vertex;
                vertex.x += sign(vertex.x) * sin(_Time.y * 2) / 5;
                vertex.y += sign(vertex.y) * cos(_Time.y * 2) / 5;

                o.pos = UnityObjectToClipPos(vertex);
                o.uv = v.texcoord;
                return o;
            }


			half4 frag(v2f i) : COLOR {
                half4 c = tex2D(_MainTex, i.uv);
                return c;
            }

			ENDCG
		}
	} 
	FallBack "Diffuse"
}