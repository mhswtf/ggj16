Shader "Custom/BennosAwesomeShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
 
        Pass
        {
 
 			Blend SrcAlpha OneMinusSrcAlpha // use alpha blending
 
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
 
            uniform sampler2D _CameraDepthTexture; //the depth texture
  			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
 
			struct appdata
			{
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
                float4 projPos : TEXCOORD1; //Screen position of pos
                float2 depth : TEXCOORD2;
				UNITY_FOG_COORDS(1)
            };
 
            v2f vert(appdata v)
            {
                v2f o;
                o.pos = mul(UNITY_MATRIX_MVP, v.pos);
                o.projPos = ComputeScreenPos(o.pos);
 				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
 				o.depth = o.pos.zw;
				UNITY_TRANSFER_FOG(o,o.pos);
 
                return o;
            }
 
            half4 frag(v2f i) : COLOR
            {
                //Grab the depth value from the depth texture
                //Linear01Depth restricts this value to [0, 1]
                float depth1 = Linear01Depth (tex2Dproj(_CameraDepthTexture,
                                                             UNITY_PROJ_COORD(i.projPos)).x);
                // get depth of pixel we are rendering                                          
                float depth2 = Linear01Depth(i.depth.x/i.depth.y);
                
                // transform to world space distance _ProjectionParams.y = near plane, _ProjectionParams.z = far plane
                float worldDepth1 = _ProjectionParams.y + (_ProjectionParams.z-_ProjectionParams.y)*depth1;
                float worldDepth2 = _ProjectionParams.y + (_ProjectionParams.z-_ProjectionParams.y)*depth2;
 	
 				float depthDistance = worldDepth1 - worldDepth2;
 				// sample the texture
 				fixed4 col;
 				col.r = depthDistance;
 				col.g = depthDistance;
 				col.b = depthDistance;
 				col.a = 1;
//				fixed4 col = tex2D(_MainTex, i.uv);
//				
//				if(worldDepth < 1 && worldDepth > 0)
//					col.a = 1;
//				else
//					col.a = 0;
                
                // apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);	
 
                return col;
            }
 
            ENDCG
        }
    }
    FallBack "VertexLit"
}