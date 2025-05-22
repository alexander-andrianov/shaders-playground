Shader "Unlit/Water"
{
    Properties
    {
        _TimeScale ("Time Scale", Float) = 1.0
        _Mouse ("Mouse", Vector) = (0,0,0,0)
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
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float _TimeScale;
            float4 _Mouse;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float3 mod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            float4 mod289(float4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            float4 permute(float4 x) { return mod289(((x*34.0)+1.0)*x); }
            float4 taylorInvSqrt(float4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

            float noise(float3 v)
            {
                const float2  C = float2(1.0/6.0, 1.0/3.0);
                const float4  D = float4(0.0, 0.5, 1.0, 2.0);
                float3 i  = floor(v + dot(v, C.yyy));
                float3 x0 = v - i + dot(i, C.xxx);
                float3 g = step(x0.yzx, x0.xyz);
                float3 l = 1.0 - g;
                float3 i1 = min(g.xyz, l.zxy);
                float3 i2 = max(g.xyz, l.zxy);
                float3 x1 = x0 - i1 + C.xxx;
                float3 x2 = x0 - i2 + C.yyy;
                float3 x3 = x0 - D.yyy;
                i = mod289(i);
                float4 p = permute(permute(permute(
                    i.z + float4(0.0, i1.z, i2.z, 1.0))
                    + i.y + float4(0.0, i1.y, i2.y, 1.0))
                    + i.x + float4(0.0, i1.x, i2.x, 1.0));
                float n_ = 0.142857142857;
                float3 ns = n_ * D.wyz - D.xzx;
                float4 j = p - 49.0 * floor(p * ns.z * ns.z);
                float4 x_ = floor(j * ns.z);
                float4 y_ = floor(j - 7.0 * x_);
                float4 x = x_ * ns.x + ns.yyyy;
                float4 y = y_ * ns.x + ns.yyyy;
                float4 h = 1.0 - abs(x) - abs(y);
                float4 b0 = float4(x.xy, y.xy);
                float4 b1 = float4(x.zw, y.zw);
                float4 s0 = floor(b0)*2.0 + 1.0;
                float4 s1 = floor(b1)*2.0 + 1.0;
                float4 sh = -step(h, float4(0.0,0.0,0.0,0.0));
                float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
                float4 a1 = b1.xzyw + s1.xzyw*sh.zzww;
                float3 p0 = float3(a0.xy,h.x);
                float3 p1 = float3(a0.zw,h.y);
                float3 p2 = float3(a1.xy,h.z);
                float3 p3 = float3(a1.zw,h.w);
                float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
                p0 *= norm.x;
                p1 *= norm.y;
                p2 *= norm.z;
                p3 *= norm.w;
                float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
                m = m * m;
                return 42.0 * dot(m*m, float4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
            }

            float3x3 rotationMatrix(float3 axis, float angle)
            {
                axis = normalize(axis);
                float s = sin(angle);
                float c = cos(angle);
                float oc = 1.0 - c;
                return float3x3(
                    oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c
                );
            }

            float fnoise(float3 p, float t)
            {
                float3x3 rot = rotationMatrix(normalize(float3(0.0,0.0,1.0)), 0.5*t);
                float3x3 rot2 = rotationMatrix(normalize(float3(0.0,0.0,1.0)), 0.3*t);
                float sum = 0.0;
                float3 r = mul(rot, p);
                float add = noise(r);
                float msc = add+0.7;
                msc = clamp(msc, 0.0, 1.0);
                sum += 0.6*add;
                p = p*2.0;
                r = mul(rot, p);
                add = noise(r);
                add *= msc;
                sum += 0.5*add;
                msc *= add+0.7;
                msc = clamp(msc, 0.0, 1.0);
                p.xy = p.xy*2.0;
                p = mul(rot2, p);
                add = noise(p);
                add *= msc;
                sum += 0.25*abs(add);
                msc *= add+0.7;
                msc = clamp(msc, 0.0, 1.0);
                p = p*2.0;
                add = noise(p);
                add *= msc;
                sum += 0.125*abs(add);
                msc *= add+0.2;
                msc = clamp(msc, 0.0, 1.0);
                p = p*2.0;
                add = noise(p);
                add *= msc;
                sum += 0.0625*abs(add);
                return sum*0.516129;
            }

            float getHeight(float3 p, float t)
            {
                return 0.3-0.5*fnoise(float3(0.5*(p.x + 0.0*t), 0.5*p.z, 0.4*t), t);
            }

            #define box_y 1.0
            #define box_x 2.0
            #define box_z 2.0
            #define stepSize 0.3
            #define PI_HALF 1.5707963267949

            float4 bg = float4(0.0, 0.0, 0.0, 1.0);
            float4 redClr = float4(1.0, 0.0, 0.0, 1.0);

            float4 getSky(float3 rd)
            {
                if (rd.y > 0.3) return float4(0.5, 0.8, 1.5, 1.0);
                if (rd.y < 0.0) return float4(0.0, 0.2, 0.4, 1.0);
                if (rd.z > 0.9 && rd.x > 0.3) {
                    if (rd.y > 0.2) return 1.5*float4(2.0, 1.0, 1.0, 1.0);
                    return 1.5*float4(2.0, 1.0, 0.5, 1.0);
                } else return float4(0.5, 0.8, 1.5, 1.0);
            }

            float4 shadeBox(float3 normal, float3 pos, float3 rd)
            {
                float deep = 1.0+0.5*pos.y;
                float4 col = deep*0.4*float4(0.0, 0.3, 0.4, 1.0);
                return col;
            }

            float4 shade(float3 normal, float3 pos, float3 rd)
            {
                float ReflectionFresnel = 0.99;
                float fresnel = ReflectionFresnel*pow(1.0-clamp(dot(-rd, normal), 0.0, 1.0), 5.0) + (1.0-ReflectionFresnel);
                float3 refVec = reflect(rd, normal);
                float4 reflection = getSky(refVec);
                float deep = 1.0+0.5*pos.y;
                float4 col = fresnel*reflection;
                col += deep*0.4*float4(0.0, 0.3, 0.4, 1.0);
                return clamp(col, 0.0, 1.0);
            }

            float4 intersect_box(float3 ro, float3 rd)
            {
                float t_min = 1000.0;
                float3 t_normal = float3(0,0,0);
                float t = (-box_x -ro.x) / rd.x;
                float3 p = ro + t*rd;
                if (p.y > -box_y && p.z < box_z && p.z > -box_z) {
                    t_normal = float3(-1.0, 0.0, 0.0);
                    t_min = t;
                }
                t = (box_x -ro.x) / rd.x;
                p = ro + t*rd;
                if (p.y > -box_y && p.z < box_z && p.z > -box_z) {
                    if (t < t_min) {
                        t_normal = float3(1.0, 0.0, 0.0);
                        t_min = t;
                    }
                }
                t = (-box_z -ro.z) / rd.z;
                p = ro + t*rd;
                if (p.y > -box_y && p.x < box_x && p.x > -box_x) {
                    if (t < t_min) {
                        t_normal = float3(0.0, 0.0, -1.0);
                        t_min = t;
                    }
                }
                t = (box_z -ro.z) / rd.z;
                p = ro + t*rd;
                if (p.y > -box_y && p.x < box_x && p.x > -box_x) {
                    if (t < t_min) {
                        t_normal = float3(0.0, 0.0, 1.0);
                        t_min = t;
                    }
                }
                if (t_min < 1000.0) return shadeBox(t_normal, ro + t_min*rd, rd);
                return bg;
            }

            float4 trace_heightfield(float3 ro, float3 rd, float t)
            {
                float tt = (1.0 - ro.y) / rd.y;

                if (tt < 0.0) {
                    return getSky(rd); 
                } else {
                    float3 p = ro + tt*rd; 
    
                    if (p.x < -box_x && rd.x <= 0.0) return bg; 
                    if (p.x >  box_x && rd.x >= 0.0) return bg; 
                    if (p.z < -box_z && rd.z <= 0.0) return bg; 
                    if (p.z >  box_z && rd.z >= 0.0) return bg; 

                    float h_loop, last_h_loop = 0.0; 
                    bool not_found = true;
                    float3 current_p_loop = p; 
                    float3 last_p_loop = current_p_loop; 

                    [unroll(20)]
                    for (int i_loop=0; i_loop<100; i_loop++) {
                        current_p_loop += stepSize*rd; 
                        h_loop = getHeight(current_p_loop, t); 
                        if (current_p_loop.y < h_loop) {not_found = false; break;}
                        last_h_loop = h_loop;
                        last_p_loop = current_p_loop;
                    }

                    if (not_found) return bg;

                    float dh2 = h_loop - current_p_loop.y; 
                    float dh1 = last_p_loop.y - last_h_loop; 
                    
                    if (abs(dh2/dh1 + 1.0) < 0.0001) {
                        p = last_p_loop;
                    } else {
                        p = last_p_loop + rd*stepSize/(dh2/dh1+1.0);
                    }

                    return float4(0.0, 0.0, 1.0, 1.0);
                }
            }

            float3x3 setCamera(float3 ro, float3 ta, float cr)
            {
                float3 cw = normalize(ta-ro);
                float3 cp = float3(sin(cr), cos(cr),0.0);
                float3 cu = normalize(cross(cw,cp));
                float3 cv = normalize(cross(cu,cw));
                return float3x3(cu, cv, cw);
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _ScreenParams.xy;
                float2 iResolution = _ScreenParams.xy;
                float iTime = _Time.y * _TimeScale;
                float2 iMouse = _Mouse.xy; 
                float2 p = (-iResolution.xy + 2.0*fragCoord.xy)/ iResolution.y;
                
                float2 m = iMouse; 
                if (iResolution.x > 0.0 && iResolution.y > 0.0) { 
                     m = _Mouse.xy / iResolution.xy;
                } else {
                     m = float2(0.5, 0.5); 
                }

                m.y += 0.3;
                m.x += 0.72;
                
                float3 ro = 9.0*normalize(float3(sin(5.0*m.x), 1.0*m.y, cos(5.0*m.x)));
                float3 ta = float3(0.0, -1.0, 0.0);
                float3x3 ca = setCamera(ro, ta, 0.0);
                float3 rd = mul(ca, normalize(float3(p.xy,4.0)));
                return trace_heightfield(ro, rd, iTime);
            }
            ENDCG
        }
    }
    FallBack "Unlit/Color"
} 