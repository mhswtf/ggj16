Shader "Custom/Water" {

	Properties {
		_Direction("WindDirection", Vector) = (1.0, 0.0, 1.0, 0.0)
		_Speed("Speed", Range(0.1, 5)) = 0.5
		_Amplitude("Amplitude", Range(0.0, 1.0)) = 0.5
		_Frequency("Frequency", Range(0.0, 3.0)) = 1.0

		_MainTex("Main Texture", 2D) = "white" {}
		_ColorRamp("ColorRamp", 2D) = "white" {}
		_NNoise1("Normal Noise 1", 2D) = "white" {}
		_NNoise2("Normal Noise 2", 2D) = "white" {}
		_DistortFactor("Distortion Factor", Range(0.0, 10.0)) = 0.5
		_MaxDepth("Max Depth", Range(0.0, 20.0)) = 10
		
	}

	CGINCLUDE

	#pragma target 3.0
	#pragma vertex vert
	#pragma fragment frag

	#include "UnityCG.cginc"

	uniform half4 _Direction;
	uniform half _Speed;
	uniform fixed _Amplitude;
	uniform half _Frequency;
	uniform half _DistortFactor;
	uniform half _MaxDepth;

	uniform sampler2D _MainTex;
	uniform sampler2D _ColorRamp;
	uniform sampler2D _NNoise1;
	uniform sampler2D _NNoise2;
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
			"Queue" = "Geometry"
			"RenderType" = "Opaque" 
		}

		GrabPass{ "_GrabTexture" }

		Pass {

 			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			struct v2f {
				float2 uv1 : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float4 pos : SV_POSITION;
                float4 projPos : TEXCOORD2; //Screen position of pos
                float depth : TEXCOORD3;
            };

            v2f vert(appdata_base v) {
                v2f o;

        		fixed2 f = normalize(_Direction.xz);
				float x = (v.vertex.x * f.x + v.vertex.z * f.y) * _Frequency + _Time.w * _Speed;

                v.vertex.y += sin(x) * _Amplitude;

                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                o.projPos = ComputeScreenPos(o.pos);
 				o.depth = o.pos.z/o.pos.w;

 				o.uv1 = v.texcoord * _MainTex_ST.xy + _MainTex_ST.zw + float2(_Time.x * _Speed,0);
 				o.uv2 = v.texcoord * _MainTex_ST.xy + _MainTex_ST.zw + float2(0,_Time.x * _Speed);

                return o;
            }

			half4 frag (v2f i) : COLOR {
				fixed depth = DepthBufferDistance(i.depth, i.projPos);

				float4 distortNormal1 = (tex2D(_NNoise1, i.uv1) - 0.5) * 2;
				float4 distortNormal2 = (tex2D(_NNoise2, i.uv2) - 0.5) * 2;
				float4 distortNormal = (distortNormal1 + distortNormal2)/2;
				
				float adjustedDepth = clamp((depth)/40, 0.5, 5);
				float4 projPosDistorted = i.projPos + distortNormal*_DistortFactor*adjustedDepth;
				half4 distortedColor = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(projPosDistorted));
				
				float distortedDepth = DepthBufferDistance(i.depth, projPosDistorted);
				fixed relativeDepth = clamp(distortedDepth,0,_MaxDepth);
				relativeDepth = relativeDepth/_MaxDepth;
				
				fixed4 depthColor = tex2D(_ColorRamp, float2(relativeDepth*0.99,0));
				//half4 tex = tex2D(_MainTex, i.uv1);
				//output.a = (depth / _TransparencyDropoff + _BaseTransparency) * tex.r;
				
				half4 col = (relativeDepth * depthColor + (1-relativeDepth) * distortedColor);
				col.a = 1;
				return col;
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}