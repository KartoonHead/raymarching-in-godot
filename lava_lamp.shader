shader_type spatial;
render_mode unshaded, depth_test_disable;

uniform sampler2D matcap_texture;

uniform vec4 lava_colour1 : hint_color;
uniform vec4 lava_colour2 : hint_color;
uniform vec4 sphereA = vec4(0.0, 0.5, 0.0, 0.5);
uniform vec4 sphereB = vec4(0.0, 0.5, 0.0, 0.5);
uniform vec4 sphereC = vec4(0.0, 0.5, 0.5, 0.5);
uniform vec4 sphereD = vec4(0.0, 0.5, 0.5, 0.5);
uniform vec4 sphereE = vec4(0.0, 0.5, 0.5, 0.5);
uniform vec4 cone = vec4(0.0, 0.0, 0.0, 0.5);
uniform vec4 plane = vec4(0.0, 1.0, 0.0, 0.0);
uniform float blend = 0.5;

uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float SURF_DIST = 0.01;

uniform float vertical_scale = 1.0;
uniform float anim_speed = 1.0;


// **** Boolean Operators ****
float union(float a, float b){
	return min(a, b);
}

float smoothUnion(float d1, float d2, float k){
    float h = clamp(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) - k*h*(1.0-h);
}

float subtraction(float a, float b){
	return max(-a, b);
}

float smoothSubtraction(float d1, float d2, float k){
    float h = clamp(0.5 - 0.5*(d2+d1)/k, 0.0, 1.0);
    return mix(d2, -d1, h) + k*h*(1.0-h);
}

float intersection(float a, float b){
	return max(a, b);
}

float smoothIntersection(float d1, float d2, float k){
    float h = clamp(0.5 - 0.5*(d2-d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) + k*h*(1.0-h);
}

// **** Shapes ****
float sdSphere(vec3 p, vec3 sp, float r){
	return length(sp - p) - r;
}

float sdCone(vec3 p, vec2 q){
	vec2 w = vec2(length(p.xz), p.y);
	vec2 a = w - q*clamp(dot(w,q)/dot(q,q), 0.0, 1.0);
	vec2 b = w - q*vec2(clamp( w.x/q.x, 0.0, 1.0 ), 1.0);
	float k = sign(q.y);
	float d = min(dot(a, a),dot(b, b));
	float s = max(k*(w.x*q.y-w.y*q.x),k*(w.y-q.y));
	return sqrt(d)*sign(s);
}

float sdPlane(vec3 p, vec3 n, float h){
  return dot(p,n) + h;
}

// **** Ray Marching ****
float GetDist(vec3 p, float time){	
	float coneDist = sdCone(p - vec3(0.0, cone.y, 0.0), cone.xz);
	float planeDist = sdPlane(p, plane.xyz, plane.a);
	
	vec4 sA = sphereA + (vec4(sin(time*1.3), cos(time*1.66)*vertical_scale, cos(time*1.11), 0.8) * 0.1);
	vec4 sB = sphereB + (vec4(sin(time*1.0), sin(time*1.55)*vertical_scale, cos(time*1.66), 0.6) * 0.1);
	vec4 sC = sphereC + (vec4(sin(time*1.55), cos(time*1.33)*vertical_scale, cos(time*1.87), 0.3) * 0.1);
	vec4 sD = sphereD + (vec4(sin(time*1.55), sin(time*1.277)*vertical_scale, cos(time*1.87), 0.3) * 0.1);
	
	float sphereDistA = length(p-sA.xyz) - sA.w;
	float sphereDistB = length(p-sB.xyz) - sB.w;
	float sphereDistC = length(p-sC.xyz) - sC.w;
	float sphereDistD = length(p-sD.xyz) - sD.w;
	float sphereDistE = length(p-sphereE.xyz) - sphereE.w;
	
	float sphereDist = smoothUnion(sphereDistA, sphereDistB, blend);
	sphereDist = smoothUnion(sphereDist, sphereDistC, blend);
	sphereDist = smoothUnion(sphereDist, sphereDistD, blend);
	sphereDist = smoothUnion(sphereDist, sphereDistE, blend);
	
	float d = smoothIntersection(coneDist, sphereDist, 0.1);
	d = smoothSubtraction(planeDist, d, 0.1);
	
	return d;
}

vec3 GetNormal(vec3 p, float time){
	float d = GetDist(p, time);
	vec2 e = vec2(0.01, 0.0);
	
	vec3 n = d - vec3(
		GetDist(p-e.xyy, time),
		GetDist(p-e.yxy, time),
		GetDist(p-e.yyx, time));
	
	return normalize(n);
}

float RayMarch(vec3 ro, vec3 rd, float time){
	float dO=0.0;  // dO = current distance
	for(int i=0; i<MAX_STEPS; i++){
		vec3 p = ro + rd*dO;  // step along ray
		float dS = GetDist(p, time);
		dO += dS;
		if(dO > MAX_DIST || dS<SURF_DIST) break;
	}
	return dO;
}

float GetLight(vec3 p, float t){
	//vec3 lightPos = (vec4(0.0, -1.0, 0.0, 1.0) * cam).xyz;
	vec3 lightPos = vec3(0.0, 4.0, 0.0);
	vec3 l = normalize(lightPos - p);
	vec3 n = GetNormal(p, t);
	
	float diff = max(0.0 , dot(n, l));
	//float diff = dot(n, l);
	float d = RayMarch(p + n*SURF_DIST*2.0, l, t);
	if(d < length(lightPos - p)){
		diff = 0.0;
	}
	return diff;
}

float GetBaseLight(vec3 p, float t){
	float bottom = 2.7;
	float grad = (p.y - bottom) * 0.28;
	grad = 1.0 - min(max(pow(grad, 0.2), 0.0), 1.0);
	
	vec3 l = vec3(0.0, -1.0, 0.0);
	vec3 n = GetNormal(p, t);
	
	float diff = dot(n, l);
	diff = (diff * 0.5) + 0.5;
	return grad;
}

float GetLightHalfLambert(vec3 p, float t){
	//vec3 lightPos = (vec4(0.0, -1.0, 0.0, 1.0) * cam).xyz;
	vec3 lightPos = vec3(0.0, 4.0, 0.0);
	vec3 l = normalize(lightPos - p);
	vec3 n = GetNormal(p, t);
	
	float diff = dot(n, l);
	float hl = (diff + 1.0) / 2.0;
	
	return hl;
}


void fragment(){
	vec3 frag_pos = ((CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec3 ro = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 rd = normalize(frag_pos - ro);
	
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	depth = length(view.xyz);
	
	float t = TIME * anim_speed;

	float d = RayMarch(ro, rd, t);
	vec3 p = ro + rd * d;
	
	vec3 n = (vec4(GetNormal(p, t), 1.0) * CAMERA_MATRIX).xyz;
	vec2 mc_uv = (n.xy + 1.0) / 2.0;
	mc_uv.y = -mc_uv.y;
	vec3 mc_col = texture(matcap_texture, mc_uv).xyz;
	
	float base_light = GetBaseLight(p, t);
	ALBEDO = mix(lava_colour2.rgb, lava_colour1.rgb, base_light) * 2.0;
	
	float max_depth = min(MAX_DIST, depth);
	if(d >= max_depth){
		ALPHA = 0.0;
	}
}