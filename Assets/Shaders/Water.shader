Shader "Custom/Water" {

	Properties {
		_TintColor ("TintColor", Color) = (1.0, 1.0, 1.0, 1.0)
		_BaseTransparency ("Base Transparency", Range(0.0, 1.0)) = .5
		_TransparencyDropoff ("Transparency dropoff", Range(0.0, 10.0)) = 1
		_Direction("WindDirection", Vector) = (1.0, 0.0, 1.0, 0.0)
		_Speed("Speed", Range(0.1, 5)) = 0.5
		_Amplitude("Amplitude", Range(0.0, 1.0)) = 0.5
		_Frequency("Frequency", Range(0.0, 3.0)) = 1.0

		_MainTex("Main Texture", 2D) = "white" {}
	}

	CGINCLUDE

	#pragma target 3.0
	#pragma vertex vert
	#pragma fragment frag

	#include "UnityCG.cginc"

	uniform fixed4 _TintColor;
	uniform fixed _BaseTransparency;
	uniform half _TransparencyDropoff;

	uniform half4 _Direction;
	uniform half _Speed;
	uniform fixed _Amplitude;
	uniform half _Frequency;

	uniform sampler2D _MainTex;
	uniform float4 _MainTex_ST;
	uniform sampler2D _CameraDepthTexture;
	uniform sampler2D _GrabTexture;

	// depth = float depth of pixel, projPos = float4 screenPosition of pixel
	float DepthBufferDistance(float depth, float4 projPos){

        //Grab the depth value from the depth texture
        //Linear01Depth restricts this value to [0, 1]
        float depth1 = Linear01Depth (tex2Dproj(_CameraDepthTexture,
                                                     UNITY_PROJ_COORD(projPos)).x);
        // get depth of pixel we are rendering                                          
        float depth2 = Linear01Depth(depth);
        
        // transform to world space distance _ProjectionParams.y = near plane, _ProjectionParams.z = far plane
        float worldDepth1 = _ProjectionParams.y + (_ProjectionParams.z-_ProjectionParams.y)*depth1;
        float worldDepth2 = _ProjectionParams.y + (_ProjectionParams.z-_ProjectionParams.y)*depth2;

		return worldDepth1 - worldDepth2;
	}

	ENDCG

	SubShader {
		Tags { 
			"Queue" = "Transparent"
			"RenderType" = "Transparent" 
		}

		GrabPass{ "_GrabTexture" }

		Pass {

 			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			struct v2f {
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
                float4 projPos : TEXCOORD1; //Screen position of pos
                float depth : TEXCOORD2;
            };

            v2f vert(appdata_base v) {
                v2f o;

        		fixed2 f = normalize(_Direction.xz);
				float x = (v.vertex.x * f.x + v.vertex.z * f.y) * _Frequency + _Time.w * _Speed;

                v.vertex.y += sin(x) * _Amplitude;

                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                o.projPos = ComputeScreenPos(o.pos);
 				o.depth = o.pos.z/o.pos.w;

 				o.uv = v.texcoord;

                return o;
            }

			half4 frag (v2f i) : COLOR {
				fixed depth = DepthBufferDistance(i.depth, i.projPos);

				fixed4 output;

				half4 tex = tex2D(_MainTex, i.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw);

				output.r = depth / 10 - .5;
				output.g = (5 - depth) / 4;
				output.b = depth / 3 + .3;
				output.a = (depth / _TransparencyDropoff + _BaseTransparency) * tex.r;

				return output * _TintColor;
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}