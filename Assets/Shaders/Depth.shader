Shader "Custom/DepthGrayscale" {


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
		Tags { "RenderType"="Opaque" }

		GrabPass{ "_GrabTexture" }

		Pass {
			CGPROGRAM

			//Vertex Shader
			v2f vert (appdata_base v) {
			   	v2f o;
			   	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			   	o.scrPos = ComputeScreenPos(o.pos);
		   		o.uvgrab = ComputeGrabScreenPos(o.pos);

		   		return o;
			}

			//Fragment Shader
			half4 frag (v2f i) : COLOR{
			   fixed depth = Linear01Depth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)).r);

			   depth += _Time.x;
			   depth = depth % 1;

			   fixed4 output = fixed4(depth, depth, depth, 1);

			   return output;
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}