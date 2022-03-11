shader_type spatial;
render_mode unshaded;

varying vec3 camPos;

uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float SURF_DIST = 0.01;


float GetDist(vec3 p, mat4 cam){
	vec4 s = vec4(0.0, -0.5, 0.0, 1.0) * cam;
	s.w = 0.5;
	
	vec4 plane = vec4(0.0, -1.0, 0.0, 1.0) * cam;
	plane.w = 0.0;
	
	float sphereDist = length(p-s.xyz) - s.w;
	float planeDist = dot(p, plane.xyz) - plane.w;
	
	float d = min(sphereDist, planeDist);
	return d;
}

vec3 GetNormal(vec3 p, mat4 cam){
	float d = GetDist(p, cam);
	vec2 e = vec2(0.01, 0.0);
	
	vec3 n = d - vec3(
		GetDist(p-e.xyy, cam),
		GetDist(p-e.yxy, cam),
		GetDist(p-e.yyx, cam));
	
	return normalize(n);
}

float RayMarch(vec3 ro, vec3 rd, mat4 cam){
	float dO=0.0;  // dO = current distance
	for(int i=0; i<MAX_STEPS; i++){
		vec3 p = ro + rd*dO;  // step along ray
		float dS = GetDist(p, cam);
		dO += dS;
		if(dO > MAX_DIST || dS<SURF_DIST) break;
	}
	return dO;
}

float GetLight(vec3 p, mat4 cam, float t){
	//vec3 lightPos = (vec4(0.0, -1.0, 0.0, 1.0) * cam).xyz;
	vec3 lightPos = (vec4(sin(t), -2.0, cos(t), 1.0) * cam).xyz;
	vec3 l = normalize(lightPos - p);
	vec3 n = GetNormal(p, cam);
	
	float diff = max(0.0 , dot(n, l));
	float d = RayMarch(p + n*SURF_DIST*2.0, l, cam);
	if(d < length(lightPos - p)){
		diff = 0.0;
	}
	return diff;
}

void vertex(){
	camPos = MODELVIEW_MATRIX[3].xyz;
}

void fragment(){
	//float d = RayMarch(camPos, VIEW, CAMERA_MATRIX);
	float d = RayMarch(camPos, VIEW, CAMERA_MATRIX);
	vec3 p = camPos + VIEW * d;
	float diff = GetLight(p, CAMERA_MATRIX, TIME);
	ALBEDO = vec3(diff);
}