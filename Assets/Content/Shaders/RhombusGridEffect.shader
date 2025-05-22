Shader "Unlit/RhombusGridEffect"
{
    Properties
    {
        _BackgroundColor ("Background Color", Color) = (0.1, 0.1, 0.2, 1.0)
        _EdgeColor ("Edge Highlight Color", Color) = (0.3, 0.3, 0.7, 1.0)
        _EdgeFalloff ("Edge Falloff", Range(0.01, 5.0)) = 1.0
        _GridScale ("Grid Scale", Float) = 10.0
        _MainLineWidth ("Main Line Width", Range(0.001, 0.1)) = 0.01
        _MainLineColor ("Main Line Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SubLineCount ("Sub-Line Count (per side)", Range(0, 5)) = 1
        _SubLineWidth ("Sub-Line Width", Range(0.001, 0.05)) = 0.005
        _SubLineColor ("Sub-Line Color", Color) = (0.7, 0.7, 0.9, 1.0)
        _SubLineSpacing ("Sub-Line Spacing", Range(0.001, 0.1)) = 0.01
        _PulseIntensity ("Pulse Intensity", Range(0.0, 1.0)) = 0.5
        _PulseSpeed ("Pulse Speed", Float) = 1.0
        _PulseType ("Pulse Type (0=Sync, 1=Wave X, 2=Wave Y)", Range(0,2)) = 0 // 0: Sync, 1: Wave X, 2: Wave Y
        _WaveFrequency ("Wave Frequency", Float) = 5.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            float4 _BackgroundColor;
            float4 _EdgeColor;
            float _EdgeFalloff;
            float _GridScale;
            float _MainLineWidth;
            float4 _MainLineColor;
            int _SubLineCount;
            float _SubLineWidth;
            float4 _SubLineColor;
            float _SubLineSpacing;
            float _PulseIntensity;
            float _PulseSpeed;
            float _PulseType;
            float _WaveFrequency;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv * _GridScale;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            
            float SDFLine(float p, float center, float width, float edge)
            {
                float d = abs(p - center) - width * 0.5;
                return smoothstep(edge, -edge, d);
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float fresnel = 1.0 - saturate(dot(viewDir, normalize(i.worldNormal)));
                fresnel = pow(fresnel, _EdgeFalloff);
                float4 backgroundColor = lerp(_BackgroundColor, _EdgeColor, fresnel);
                float4 col = backgroundColor;

                float u = i.uv.x;
                float v = i.uv.y;

                float line1 = u + v;
                float line2 = u - v;

                float pulseFactor = 0.0;
                float timeVal = _Time.y * _PulseSpeed;
                if (_PulseType == 0.0)
                {
                    pulseFactor = sin(timeVal);
                }
                else if (_PulseType == 1.0)
                {
                    pulseFactor = sin(timeVal + u * _WaveFrequency / _GridScale);
                }
                else
                {
                    pulseFactor = sin(timeVal + v * _WaveFrequency / _GridScale);
                }
                pulseFactor = (pulseFactor * 0.5 + 0.5) * _PulseIntensity + (1.0 - _PulseIntensity);
                
                float currentMainLineWidth = _MainLineWidth * pulseFactor;
                float4 currentMainLineColor = _MainLineColor;
                currentMainLineColor.rgb *= pulseFactor;

                float mainLines = 0.0;
                mainLines = max(mainLines, SDFLine(frac(line1) - 0.5, 0.0, currentMainLineWidth, 0.005));
                mainLines = max(mainLines, SDFLine(frac(line2) - 0.5, 0.0, currentMainLineWidth, 0.005));
                
                col = lerp(col, currentMainLineColor, mainLines);

                if (_SubLineCount > 0)
                {
                    float subLines = 0.0;
                    for (int k = 1; k <= _SubLineCount; ++k)
                    {
                        float offset = _MainLineWidth * 0.5 + _SubLineSpacing * k + _SubLineWidth * (k - 0.5) ;
                        float subLineAlpha = 1.0 - (float)k / (_SubLineCount + 1.0);
                        subLineAlpha *= subLineAlpha;

                        subLines = max(subLines, SDFLine(frac(line1) - 0.5, offset, _SubLineWidth, 0.002) * subLineAlpha);
                        subLines = max(subLines, SDFLine(frac(line1) - 0.5, -offset, _SubLineWidth, 0.002) * subLineAlpha);
                        subLines = max(subLines, SDFLine(frac(line2) - 0.5, offset, _SubLineWidth, 0.002) * subLineAlpha);
                        subLines = max(subLines, SDFLine(frac(line2) - 0.5, -offset, _SubLineWidth, 0.002) * subLineAlpha);
                    }
                    float4 currentSubLineColor = _SubLineColor;
                    // currentSubLineColor.a *= pulseFactor; // Sublines movement
                    col = lerp(col, currentSubLineColor, subLines * (1.0-mainLines));
                }

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
} 