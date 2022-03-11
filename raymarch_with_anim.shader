shader_type spatial;
render_mode unshaded, depth_test_disable;

uniform sampler2D matcap_texture;

uniform vec4 sphereA = vec4(0.0, 0.5, 0.0, 0.5);
uniform vec4 sphereB = vec4(0.0, 0.5, 0.0, 0.5);
uniform vec4 sphereC = vec4(0.0, 0.5, 0.5, 0.5);
uniform float blend = 0.5;

uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float SURF_DIST = 0.01;



float smin(float a, float b, float k){
	float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
	return mix(b, a, h) - k*h*(1.0-h);
}

float GetDist(vec3 p){
	
	vec4 plane = vec4(0.0, 1.0, 0.0, 0.0);
	
	float sphereDistA = length(p-sphereA.xyz) - sphereA.w;
	float sphereDistB = length(p-sphereB.xyz) - sphereB.w;
	float sphereDistC = length(p-sphereC.xyz) - sphereC.w;
	
	float sphereDist = smin(sphereDistA, sphereDistB, blend);
	sphereDist = smin(sphereDist, sphereDistC, blend);
	
	float planeDist = dot(p, plane.xyz) - plane.w;
	
	float d = min(sphereDist, planeDist);
	return d;
}

float GetDistAnim(vec3 p, float time){
	
	vec4 plane = vec4(0.0, 1.0, 0.0, -1.5);
	
	vec4 sA = vec4(sin(time*1.3), cos(time*1.66), cos(time*1.11), 0.8);
	vec4 sB = vec4(sin(time*1.0), sin(time*1.55), cos(time*1.66), 0.6);
	vec4 sC = vec4(sin(time*1.55), sin(time*1.3), cos(time*1.87), 0.3);
	
	float sphereDistA = length(p-sA.xyz) - sA.w;
	float sphereDistB = length(p-sB.xyz) - sB.w;
	float sphereDistC = length(p-sC.xyz) - sC.w;
	
	float sphereDist = smin(sphereDistA, sphereDistB, blend);
	sphereDist = smin(sphereDist, sphereDistC, blend);
	
	float planeDist = dot(p, plane.xyz) - plane.w;
	
	float d = smin(sphereDist, planeDist, blend);
	return d;
}

vec3 GetNormal(vec3 p){
	float d = GetDist(p);
	vec2 e = vec2(0.01, 0.0);
	
	vec3 n = d - vec3(
		GetDist(p-e.xyy),
		GetDist(p-e.yxy),
		GetDist(p-e.yyx));
	
	return normalize(n);
}

vec3 GetNormalAnim(vec3 p, float time){
	float d = GetDistAnim(p, time);
	vec2 e = vec2(0.01, 0.0);
	
	vec3 n = d - vec3(
		GetDistAnim(p-e.xyy, time),
		GetDistAnim(p-e.yxy, time),
		GetDistAnim(p-e.yyx, time));
	
	return normalize(n);
}

float RayMarch(vec3 ro, vec3 rd){
	float dO=0.0;  // dO = current distance
	for(int i=0; i<MAX_STEPS; i++){
		vec3 p = ro + rd*dO;  // step along ray
		float dS = GetDist(p);
		dO += dS;
		if(dO > MAX_DIST || dS<SURF_DIST) break;
	}
	return dO;
}

float RayMarchAnim(vec3 ro, vec3 rd, float time){
	float dO=0.0;  // dO = current distance
	for(int i=0; i<MAX_STEPS; i++){
		vec3 p = ro + rd*dO;  // step along ray
		float dS = GetDistAnim(p, time);
		dO += dS;
		if(dO > MAX_DIST || dS<SURF_DIST) break;
	}
	return dO;
}

float GetLight(vec3 p, float t){
	//vec3 lightPos = (vec4(0.0, -1.0, 0.0, 1.0) * cam).xyz;
	vec3 lightPos = vec3(sin(t), 2.0, cos(t));
	vec3 l = normalize(lightPos - p);
	vec3 n = GetNormal(p);
	
	float diff = max(0.0 , dot(n, l));
	//float diff = dot(n, l);
	float d = RayMarch(p + n*SURF_DIST*2.0, l);
	if(d < length(lightPos - p)){
		diff = 0.0;
	}
	return diff;
}

float GetLightAnim(vec3 p, float t){
	//vec3 lightPos = (vec4(0.0, -1.0, 0.0, 1.0) * cam).xyz;
	vec3 lightPos = vec3(0.0, 4.0, 0.0);
	vec3 l = normalize(lightPos - p);
	vec3 n = GetNormalAnim(p, t);
	
	float diff = max(0.0 , dot(n, l));
	//float diff = dot(n, l);
	float d = RayMarchAnim(p + n*SURF_DIST*2.0, l, t);
	if(d < length(lightPos - p)){
		diff = 0.0;
	}
	return diff;
}

float GetLightHalfLambert(vec3 p, float t){
	//vec3 lightPos = (vec4(0.0, -1.0, 0.0, 1.0) * cam).xyz;
	vec3 lightPos = vec3(sin(t), 2.0, cos(t));
	vec3 l = normalize(lightPos - p);
	vec3 n = GetNormal(p);
	
	float diff = dot(n, l);
	float hl = (diff + 1.0) / 2.0;
	
	return hl;
}

float GetLightHalfLambertAnim(vec3 p, float t){
	//vec3 lightPos = (vec4(0.0, -1.0, 0.0, 1.0) * cam).xyz;
	vec3 lightPos = vec3(0.0, 4.0, 0.0);
	vec3 l = normalize(lightPos - p);
	vec3 n = GetNormalAnim(p, t);
	
	float diff = dot(n, l);
	float hl = (diff + 1.0) / 2.0;
	
	return hl;
}


void fragment(){
	vec3 frag_pos = ((CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec3 ro = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 rd = normalize(frag_pos - ro);
	
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	depth = depth * 2.0 - 1.0;
	depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
	
	float t = TIME * 1.6;

	//float d = RayMarch(ro, rd);
	float d = RayMarchAnim(ro, rd, t);
	vec3 p = ro + rd * d;
	//float diff = GetLightHalfLambert(p, TIME);
	float diff = GetLightHalfLambertAnim(p, t);
	//float diff2 = GetLight(p, TIME);
	float diff2 = GetLightAnim(p, t);
	
	vec3 n = (vec4(GetNormalAnim(p, t), 1.0) * CAMERA_MATRIX).xyz;
	vec2 mc_uv = (n.xy + 1.0) / 2.0;
	mc_uv.y = -mc_uv.y;
	vec3 mc_col = texture(matcap_texture, mc_uv).xyz;
	
	ALBEDO = mc_col;
	
	//ALBEDO = vec3(mix(diff, diff2, 0.8));
	float max_depth = min(MAX_DIST, depth);
	if(d >= max_depth){
		ALPHA = 0.0;
	}
}