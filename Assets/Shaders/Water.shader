Shader "Custom/Water" {

	Properties {
		_Direction("WindDirection", Vector) = (1.0, 0.0, 1.0, 0.0)
		_Speed("Speed", Range(0.1, 5)) = 0.5
		_Amplitude("Amplitude", Range(0.0, 1.0)) = 0.5
		_Frequency("Frequency", Range(0.0, 3.0)) = 1.0
		_Smoothing("Smoothing", Range(0.0, 1.0)) = 0.5

		_ColorRamp("ColorRamp", 2D) = "white" {}
		_NNoise1("Normal Noise 1", 2D) = "white" {}
		_NNoise2("Normal Noise 2", 2D) = "white" {}
		_DistortFactor("Distortion Factor", Range(0.0, 10.0)) = 0.5
		_MaxDepth("Max Depth", Range(0.01, 20.0)) = 10
		
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
	uniform fixed _Smoothing;

	uniform sampler2D _ColorRamp;
	uniform sampler2D _NNoise1;
	uniform float4 _NNoise1_ST;
	uniform sampler2D _NNoise2;
	uniform float4 _NNoise2_ST;
	uniform sampler2D _CameraDepthTexture;
	uniform sampler2D _GrabTexture;

	// depth = float depth of pixel, projPos = float4 screenPosition of pixel
	float DepthBufferDistance(float depth, float4 projPos){

        //Grab the depth value from the depth texture
        //Linear01Depth restricts this value to [0, 1]
        float depth1 = Linear01Depth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(projPos)).x);
        // get depth of pixel we are rendering                                          
        float depth2 = Linear01Depth(depth);
        
        // transform to world space distance _ProjectionParams.y = near plane, _ProjectionParams.z = far plane
        float worldDepth1 = _ProjectionParams.y + (_ProjectionParams.z-_ProjectionParams.y)*depth1;
        float worldDepth2 = _ProjectionParams.y + (_ProjectionParams.z-_ProjectionParams.y)*depth2;

		return worldDepth1 - worldDepth2;
	}

	float VertexDisplacement(float3 vertex) {
		fixed2 dir = normalize(_Direction.xz);
		float x = (vertex.x * dir.x + vertex.z * dir.y) * _Frequency + _Time.w * _Speed;
        return sin(x) * _Amplitude;
	}

	ENDCG

	SubShader {
		Tags { 
			"Queue" = "Geometry"
			"RenderType" = "Opaque" 
		}

		GrabPass { "_GrabTexture" }

		Pass {

 			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			struct v2f {
				float4 pos : SV_POSITION;
				float3 normalWorld : NORMAL;
				float2 uv1 : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float4 posWorld : TEXCOORD2;
                float4 projPos : TEXCOORD3; 
                float depth : TEXCOORD4;
            };

            v2f vert(appdata_full v) {
                v2f o;

                // Vertex displacement
                // Move the vertex to world space
				float3 v0 = mul(_Object2World, v.vertex).xyz;
				
				// Create two fake neighbour vertices, so we can simulate the new slope, and generate a new normal
				// The fake neighbours are both in the XZ plane, meaning that this will only work for a surface parallel with this
				float3 v1 = v0 + float3(0.05, 0, 0); // +X
				float3 v2 = v0 + float3(0, 0, 0.05); // +Z
				
				// Now apply the vertex displacement to the original vertex, and the two fake neighbours. Since the fake vertices
				// are applied the function relative to their own coordinates, we can use them to generate the new normal, even though
				// they don't assume the position of actual vertices.
				
				v0.y += VertexDisplacement(v0);
				v1.y += VertexDisplacement(v1);
				v2.y += VertexDisplacement(v2);
				
				// We smooth out the Y difference to avoid hard edges. This will actually result in incorrect normals, but
				// it can make the water look smoother
				// A value of 1 for smoothing will result in the original normal, and no effect
				v1.y -= (v1.y - v0.y) * _Smoothing;
				v2.y -= (v2.y - v0.y) * _Smoothing;
				
				// Take the cross product of the two vectors from the original vertex to the two fake neighbour vertices 
				// resulting in the new normal. Move the new normal back to object space, normalize it, and we're done.
				float3 vta = v2-v0;
				float3 vna = cross(vta, v1-v0);
				
				float3 vt = mul((float3x3)_World2Object, vta);
				float3 vn = mul((float3x3)_World2Object, vna);
				
				v.tangent = float4(normalize(vt), 1.0);
				v.normal = normalize(vn);

				o.posWorld = float4(v0, 1.0);
				v.vertex = mul(_World2Object, o.posWorld);

                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

                //Screen position of pos
                o.projPos = ComputeScreenPos(o.pos);
 				o.depth = o.pos.z/o.pos.w;

 				o.uv1 = v.texcoord * _NNoise1_ST.xy + _NNoise1_ST.zw + float2(_Time.x * _Speed, 0);
 				o.uv2 = v.texcoord * _NNoise2_ST.xy + _NNoise2_ST.zw + float2(0, _Time.x * _Speed);

                return o;
            }

			half4 frag (v2f i) : COLOR {
//				return fixed4(i.normalWorld, 1);

				float realDepth = DepthBufferDistance(i.depth, i.projPos);
				float adjustedDepth = clamp((realDepth) / 20, 0, _MaxDepth);

				float4 distortNormal1 = (tex2D(_NNoise1, i.uv1) - 0.5) * 2;
				float4 distortNormal2 = (tex2D(_NNoise2, i.uv2) - 0.5) * 2;
				float4 distortNormal = (distortNormal1 + distortNormal2) / 2;
				
				float4 projPosDistorted = i.projPos + distortNormal * _DistortFactor * adjustedDepth;
	
				float distortedDepth = DepthBufferDistance(i.depth, projPosDistorted);
//				return distortedDepth / _MaxDepth;
				if (distortedDepth < 0) {
					distortedDepth = DepthBufferDistance(i.depth, i.projPos);
					projPosDistorted = i.projPos;
				}

				half4 distortedColor = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(projPosDistorted));
				

				//float adjustedDepth = clamp((distortedDepth) / 20, 0, _MaxDepth);

				fixed relativeDepth = clamp(distortedDepth, 0.5, _MaxDepth);
				relativeDepth = relativeDepth/_MaxDepth;
				
				//relativeDepth = 1 - pow(1 - relativeDepth, 3);
				
				fixed4 depthColor = tex2D(_ColorRamp, float2(relativeDepth * 0.95, 0));
				
				half4 col = (relativeDepth * depthColor + (1 - relativeDepth) * distortedColor);
				col.a = 1;
				return col;
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}