Shader "Custom/Terrain" {

	Properties {
		_ObjectUpVector("Object space up vector", Vector) = (0.0, 1.0, 0.0, 0.0)

		_UpperColor ("Upper Tint Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_MainColor ("Middle Tint Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_LowerColor ("Lower Tint Color", Color) = (1.0, 1.0, 1.0, 1.0)

		_UpperBorder ("Upper Border", Range(-1.0, 1.0)) = 0.5
		_UpperLerp ("Upper Lerp Zone", Range(0.0, 0.5)) = 0.2
		_LowerBorder ("Lower Border", Range(-1.0, 1.0)) = -0.5
		_LowerLerp ("Lower Lerp Zone", Range(0.0, 0.5)) = 0.2

		_UpperTex("Upper texture", 2D) = "white" {}
		_MiddleTex("Middle texture", 2D) = "white" {}
		_LowerTex("Lower texture", 2D) = "white" {}
	}
	
	CGINCLUDE
 
	#include "UnityCG.cginc"
	#pragma target 3.0
	
	#pragma vertex vert
	#pragma fragment frag

	uniform fixed4 _LightColor0;

	uniform fixed4 _ObjectUpVector;
	
	uniform fixed4 _UpperColor;
	uniform fixed4 _MainColor;
	uniform fixed4 _LowerColor;

	uniform fixed _UpperBorder;
	uniform fixed _UpperLerp;
	uniform fixed _LowerBorder;
	uniform fixed _LowerLerp;
	
	uniform sampler2D _UpperTex;
	uniform float4 _UpperTex_ST;
	uniform sampler2D _MiddleTex;
	uniform float4 _MiddleTex_ST;
	uniform sampler2D _LowerTex;
	uniform float4 _LowerTex_ST;

	ENDCG
 
	SubShader {
		Tags { 
			"RenderType" = "Opaque"
		}
		
		LOD 200
		
		Pass {
			Tags { 
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase

			struct v2f {
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				half4 uv : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalWorld : TEXCOORD2;
				LIGHTING_COORDS(3, 4)
			};
			
			v2f vert(appdata_full v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.posWorld = mul(_Object2World, v.vertex);
				o.normal = v.normal;	
				o.normalWorld = normalize(mul(float4(v.normal, 1.0), _World2Object).xyz);

				o.uv = v.texcoord;

				TRANSFER_VERTEX_TO_FRAGMENT(o);
				
				return o;
			}
			
			fixed4 frag(v2f i) : COLOR {
				fixed3 lightDirection;
				fixed attenuation;
				
				if (_WorldSpaceLightPos0.w == 0.0) { // Directional light
					lightDirection = normalize(_WorldSpaceLightPos0.xyz);
					attenuation = 1;
				} else {
					float3 fragToLight = _WorldSpaceLightPos0.xyz - i.posWorld.xyz;
					float distance = length(fragToLight);
					attenuation = 1.0 / distance;
					lightDirection = normalize(fragToLight);
				}
				
				attenuation *= LIGHT_ATTENUATION(i);

				fixed3 diffuseLight = attenuation * _LightColor0.rgb * saturate(dot(i.normalWorld, lightDirection));
				fixed3 ambLight = UNITY_LIGHTMODEL_AMBIENT.rgb;
				fixed4 finalLight = float4(ambLight + diffuseLight, 1.0);

				half lerpUU = _UpperBorder + (_UpperLerp / 2);
				half lerpUL = _UpperBorder - (_UpperLerp / 2);
				half lerpLU = _LowerBorder + (_LowerLerp / 2);
				half lerpLL = _LowerBorder - (_LowerLerp / 2);

				fixed4 output;

				// Up vector dot face normal vector
				// 1 means horizontal face pointing up, 0 is vertical, -1 means down
				fixed udn = dot(_ObjectUpVector, i.normal);
				if (udn < lerpLL) {
					fixed4 tex = tex2D(_LowerTex, i.uv.xy * _LowerTex_ST.xy + _LowerTex_ST.zw);
					output = tex * _LowerColor;

				} else if (udn >= lerpLL && udn < lerpLU) {
					// Lerp factor in the lerp zone
					fixed lerpf = (udn - lerpLL) / (lerpLU - lerpLL);

					fixed4 lowerTex = tex2D(_LowerTex, i.uv.xy * _LowerTex_ST.xy + _LowerTex_ST.zw);
					fixed4 middleTex = tex2D(_MiddleTex, i.uv.xy * _MiddleTex_ST.xy + _MiddleTex_ST.zw);

					output = lerp(_LowerColor, _MainColor, lerpf) * lerp(lowerTex, middleTex, lerpf);

				} else if (udn >= lerpLU && udn < lerpUL) {
					fixed4 tex = tex2D(_MiddleTex, i.uv.xy * _MiddleTex_ST.xy + _MiddleTex_ST.zw);

					output = tex * _MainColor;

				} else if (udn >= lerpLU && udn < lerpUU) {
					fixed lerpf = (udn - lerpUL) / (lerpUU - lerpUL);

					fixed4 middleTex = tex2D(_MiddleTex, i.uv.xy * _MiddleTex_ST.xy + _MiddleTex_ST.zw);
					fixed4 upperTex = tex2D(_UpperTex, i.uv.xy * _UpperTex_ST.xy + _UpperTex_ST.zw);

					output = lerp(_MainColor, _UpperColor, lerpf) * lerp(middleTex, upperTex, lerpf);

				} else {
					fixed4 tex = tex2D(_UpperTex, i.uv.xy * _UpperTex_ST.xy + _UpperTex_ST.zw);

					output = tex * _UpperColor;
				}
				return output * finalLight;
			}
			
			ENDCG
		}
		
		Pass {
			Tags { 
				"LightMode" = "ForwardAdd"
			}
			
			Blend One One

			CGPROGRAM

			struct v2f {
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD1;
				float3 normal : TEXCOORD0;
				float3 normalWorld : TEXCOORD2;
			};
			
			v2f vert(appdata_full v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.posWorld = mul(_Object2World, v.vertex);
				o.normal = v.normal;	
				o.normalWorld = normalize(mul(float4(v.normal, 1.0), _World2Object).xyz);
								
				return o;
			}
			
			fixed4 frag(v2f i) : COLOR {
			
				fixed3 lightDirection;
				fixed attenuation;
				
				if (_WorldSpaceLightPos0.w == 0.0) { // Directional light
					lightDirection = normalize(_WorldSpaceLightPos0.xyz);
					attenuation = 1;
				} else {
					float3 fragToLight = _WorldSpaceLightPos0.xyz - i.posWorld.xyz;
					float distance = length(fragToLight);
					attenuation = 1.0 / distance;
					lightDirection = normalize(fragToLight);
				}
				
				fixed3 diffuseLight = attenuation * _LightColor0.rgb * saturate(dot(i.normalWorld, lightDirection));

				fixed4 finalLight = float4(diffuseLight, 1.0);
				
				return finalLight;
			}
			
			ENDCG
		}
	} 
	FallBack "Diffuse"
}
