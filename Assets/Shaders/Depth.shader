Shader "Custom/Depth" {

	CGINCLUDE

	#pragma target 3.0
	#pragma vertex vert
	#pragma fragment frag

	#include "UnityCG.cginc"

	uniform sampler2D _CameraDepthTexture;
	uniform sampler2D _GrabTexture;

	struct v2f {
	   float4 pos : SV_POSITION;
	   float4 scrPos : TEXCOORD1;
	   float4 uvgrab : TEXCOORD2;
	};

	ENDCG

	SubShader {
		Tags { 
			"Queue" = "Transparent"
			"RenderType" = "Transparent" 
		}

		GrabPass{ "_GrabTexture" }

		Pass {

//			ZWrite off

 			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			v2f vert (appdata_base v) {
			   	v2f o;
			   	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			   	o.scrPos = ComputeScreenPos(o.pos);
		   		o.uvgrab = ComputeGrabScreenPos(o.pos);

		   		return o;
			}

			half4 frag (v2f i) : COLOR {
				fixed depth = Linear01Depth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)).x);

				if (depth == 1) return 0;

				fixed4 refl = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(i.uvgrab));

				return fixed4(0, depth, pow(depth, 3), .5);

				fixed4 output = fixed4(0, depth, depth, .5);

				return output;
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}