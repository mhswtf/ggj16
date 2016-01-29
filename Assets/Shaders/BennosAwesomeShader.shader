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
				UNITY_FOG_COORDS(1)
            };
 
 			sampler2D _MainTex;
			float4 _MainTex_ST;
 
            v2f vert(appdata v)
            {
                v2f o;
                o.pos = mul(UNITY_MATRIX_MVP, v.pos);
                o.projPos = ComputeScreenPos(o.pos);
 				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.pos);

                return o;
            }
 
            half4 frag(v2f i) : COLOR
            {
                //Grab the depth value from the depth texture
                //Linear01Depth restricts this value to [0, 1]
                float depth = Linear01Depth (tex2Dproj(_CameraDepthTexture,
                                                             UNITY_PROJ_COORD(i.projPos)).x);
 
 				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
			
                col.a *= 1-depth;
                
                // apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);	
 
                return col;
            }
 
            ENDCG
        }
    }
    FallBack "VertexLit"
}