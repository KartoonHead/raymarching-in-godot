shader_type spatial;
render_mode unshaded;

uniform sampler2D matcap_texture;

uniform vec4 sphereA = vec4(0.0, 0.5, 0.0, 0.5);
uniform vec4 sphereB = vec4(0.0, 0.5, 0.0, 0.5);
uniform vec4 sphereC = vec4(0.0, 0.5, 0.5, 0.5);
uniform float blend = 0.5;

uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float SURF_DIST = 0.01;
uniform int ITERATIONS = 50;
uniform float BAILOUT = 100.0;
uniform float POWER = 1.0;
uniform float AO_DIST = 1.0;
uniform int AO_ITERATIONS = 10;
uniform float AO_POWER = 1.0;


float smin(float a, float b, float k){
	float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
	return mix(b, a, h) - k*h*(1.0-h);
}

float DE( vec3 pos, float t ){
	//vec3 z = mod(pos, 1.0);
	vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	
	float time_pow = (sin(t) + 1.0) * 0.5;
	time_pow = (time_pow + (POWER - 1.0)) * time_pow;
	
	time_pow = POWER;
	
	for(int i=0; i<ITERATIONS; i++){
		r = length(z);
		if(r>BAILOUT){
			break;
		}
		// convert to polar coords
		float theta = acos(z.z/r);
		float phi = atan(z.y, z.x);
		dr = pow(r, time_pow-1.0)*time_pow*dr+1.0;
		
		// scale and rotate the point
		float zr = pow(r, time_pow);
		theta = theta*time_pow;
		phi = phi*time_pow;
		
		// convert back to cartesian coordinates
		z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
		z += pos;
		}
	return 0.5*log(r)*r/dr;
	}

float DE2(vec3 pos) {
	vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	
	for (int i = 0; i < ITERATIONS ; i++) {
		r = length(z);
		if (r>BAILOUT) break;
		
		// convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y,z.x);
		dr =  pow( r, POWER-1.0)*POWER*dr + 1.0;
		
		// scale and rotate the point
		float zr = pow( r,POWER);
		theta = theta*POWER;
		phi = phi*POWER;
		
		// convert back to cartesian coordinates
		z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
		z+=pos;
	}
	return 0.5*log(r)*r/dr;
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
	
	d = DE(p, time);
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

float ao(vec3 p, vec3 n, float t) {
    float dist = AO_DIST;
    float occ = 1.0;
    for (int i = 0; i < AO_ITERATIONS; i++) {
        occ = min(occ, GetDistAnim(p + (dist * n), t) / dist);
        dist *= AO_POWER;
    }
    occ = max(occ, 0.0);
    return occ;
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

mat3 alignMatrix(vec3 dir) {
    vec3 f = normalize(dir);
    vec3 s = normalize(cross(f, vec3(0.48, 0.6, 0.64)));
    vec3 u = cross(s, f);
    return mat3(u, s, f);
}

void fragment(){
	vec3 aoDir[] = { vec3(0.357407, 0.357407, 0.862856),
	vec3(0.357407, 0.862856, 0.357407),
	vec3(0.862856, 0.357407, 0.357407),
	vec3(-0.357407, 0.357407, 0.862856),
	vec3(-0.357407, 0.862856, 0.357407),
	vec3(-0.862856, 0.357407, 0.357407),
	vec3(0.357407, -0.357407, 0.862856),
	vec3(0.357407, -0.862856, 0.357407),
	vec3(0.862856, -0.357407, 0.357407),
	vec3(-0.357407, -0.357407, 0.862856),
	vec3(-0.357407, -0.862856, 0.357407),
	vec3(-0.862856, -0.357407, 0.357407)
	};
	
	vec3 frag_pos = ((CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec3 ro = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 rd = normalize(frag_pos - ro);
	
	float t = TIME * 0.25;

	//float d = RayMarch(ro, rd);
	float d = RayMarchAnim(ro, rd, t);
	vec3 p = ro + rd * d;
	//float diff = GetLightHalfLambert(p, TIME);
	//float diff = GetLightHalfLambertAnim(p, t);
	//float diff2 = GetLight(p, TIME);
	//float diff2 = GetLightAnim(p, t);
	
	vec3 n = (vec4(GetNormalAnim(p, t), 1.0) * CAMERA_MATRIX).xyz;
	
	
	// AO STUFF
	mat3 mat = alignMatrix(n);
    float a0 = 0.0;
    for (int i = 0; i < 12; ++i) {
        vec3 m = mat * aoDir[i];
        a0 += ao(p, m, t) * (0.5 + 0.5 * dot(m, vec3(0.0, 0.0, 1.0)));
    }
	// /AO STUFF
	
	vec2 mc_uv = (n.xy + 1.0) / 2.0;
	mc_uv.y = -mc_uv.y;
	vec3 mc_col = texture(matcap_texture, mc_uv).xyz;
	
	//float lighting = mix(diff, diff2, 0.8);
	ALBEDO = vec3(mc_col * a0);
	//ALBEDO =  mix(vec3(1.0, 0.5, 0.5), vec3(0.0, 1.0, 0.5), lighting);
	
	//ALBEDO = vec3(mix(diff, diff2,0.8));
	if(d >= MAX_DIST){
		ALPHA = 0.0;
	}
}