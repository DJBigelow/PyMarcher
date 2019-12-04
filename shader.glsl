const float glow_intensity = 0.15;
const float fog_intensity = 0.5;
const float EPSILON = 0.0001;
const int MAX_STEPS = 255;
const float MAX_DISTANCE = 100.0;
const float MIN_DISTANCE = 0.01;

vec3 color_scheme(float t) {
    					   //R    G    B
    vec3 contrast = 	vec3(0.5, 0.5, 0.5);
    vec3 brightness = 	vec3(0.5, 0.3, 0.5);
    vec3 frequency = 	vec3(0.5, 0.5, 0.5);
    vec3 phase = 		vec3(0.0, 0.33, 0.66);
    
    return contrast + brightness * cos(6.28318 * (frequency * t + phase));
}



//----------------------------------------------------------------------------------
float sphere_sdf( vec3 origin, float radius, vec3 pos) {
    return length(origin - pos) - radius;
}



//----------------------------------------------------------------------------------
float box_sdf(vec3 pos, vec3 origin, vec3 dim, float rounding) {
 	vec3 q = abs(pos - origin) - dim;
    return length(max(q, 0.0)) + min( max( q.x, max(q.y, q.z)), 0.0) - rounding;
}



//----------------------------------------------------------------------------------
float scene_sdf(vec3 pos) {
	float min_distance = sphere_sdf(vec3(-1.0, -1.0, 1.0), 0.5, pos);
	min_distance = min(min_distance, sphere_sdf(vec3(1, -1, 1), 0.5, pos));
    min_distance = min(min_distance, sphere_sdf(vec3(0, 1, 1), 0.5, pos));
    min_distance = min(min_distance, sphere_sdf(vec3(0, -0.25, 1), 0.25, pos));
    min_distance = min(min_distance, box_sdf(pos, vec3(0, -0.25, 1), vec3(0.25, 0.25, 0.5), 0.1));
    //min_distance = min(min_distance, );*/
    return min_distance;    
}

   

//----------------------------------------------------------------------------------                    
float march(vec3 pos, vec3 ray) {   
    
    float dist;
    
    float dist_marched = 0.0;
    
    for (int i = 0; i < MAX_STEPS; i++) {
     	dist = scene_sdf(pos);             
        
        dist_marched += dist;
        
        if (dist < 0.01) { 
        //    ray_intersect = true;        	
            return dist_marched;
        }
        
        if (dist_marched > MAX_DISTANCE) {
            return MAX_DISTANCE;
        }
        
        //March forward by dist
        pos += ray*dist;
    }
    
    return MAX_DISTANCE;
}


//----------------------------------------------------------------------------------
void rotate(inout vec3 vec, vec2 angle) {
 	vec.yz = cos(angle.y) * vec.yz + sin(angle.y) * vec2(-1, 1) * vec.zy;
    vec.xz = cos(angle.x) * vec.xz + sin(angle.x) * vec2(-1, 1) * vec.zx;
}




//----------------------------------------------------------------------------------
vec3 estimate_normal(vec3 pos) {
	return normalize(vec3(
    	scene_sdf(vec3(pos.x + EPSILON, pos.y, pos.z)) - scene_sdf(vec3(pos.x - EPSILON, pos.y, pos.z)),
        scene_sdf(vec3(pos.x, pos.y + EPSILON, pos.z)) - scene_sdf(vec3(pos.x, pos.y - EPSILON, pos.z)),
        scene_sdf(vec3(pos.x, pos.y, pos.z + EPSILON)) - scene_sdf(vec3(pos.x, pos.y, pos.z - EPSILON))
    ));
}




//----------------------------------------------------------------------------------
//In Phong's illumination model, light is reflected off of a surface in three parts.
//
//The first is ambient light, which is constant regardless of viewing angles, surface
//normals, or the positions of light sources.
//
//The second part is diffuse light. Diffuse light is when light strikes a surface and 
//is scattered in all directions. This means that diffuse lighting is independent of 
//viewing angles.
//
//The third is specularity light, which is light that is reflected about the normal of 
//the surface and hits the eye directly.
vec3 phong_illumination(vec3 k_amb, 
                        vec3 k_diff, 
                        vec3 k_spec,
                       	float shininess,
                       	vec3 point,
                       	vec3 cam_pos) {
    
    vec3 ambient_intensity = vec3(0.5, 0.5, 0.5);

    vec3 base_color = ambient_intensity * k_amb;
    
    vec3 light_pos = vec3(4.0, 2.0, 4.0);
    //rotate(light_pos, vec2(iTime, 0.0));
    vec3 light_intensity = vec3(0.5, 0.5, 0.5);
    
    //Normal of the surface at point
    vec3 normal = estimate_normal(point);
    
    //Vector pointing from the surface to the light source
    vec3 L = normalize(light_pos - point);
    
    //Vector pointing from the surface to the camera
    vec3 V = normalize(cam_pos - point);
    
    //Vector of the direction of light reflected off the surface
    vec3 R = normalize(reflect(-L, normal));
    
    
    vec3 phong_light_contribution;  
    vec3 diffuse_light;
    vec3 spec_light;
    
    float dot_LN = clamp(dot(L, normal), 0.0, 1.0);
    float dot_RV = clamp(dot(R,V), 0.0, 1.0);
    
  	
    diffuse_light = k_diff * dot_LN;          	  
    spec_light = k_spec * pow(dot_RV, shininess) ;
   
    
    
    return base_color += light_intensity * (diffuse_light * spec_light);
}



//----------------------------------------------------------------------------------
vec3 cam_direction(float fov, vec2 viewport_size, vec2 frag_coord) {
 	vec2 xy = frag_coord - viewport_size / 2.0;
    float z = -viewport_size.y * 2.0 / tan(radians(fov));
    return normalize(vec3(xy, z));
}



//----------------------------------------------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{ 
    							//Transform from pixel coordinates to uv coordinates
    vec3 cam_dir = cam_direction(45.0, iResolution.xy, fragCoord);
    vec3 cam_pos = vec3(0, 0, 8.0);    
    vec2 angle = vec2(iTime, 0.0);
    
   
    vec3 k_amb = 0.5*color_scheme(iTime);
    vec3 k_diff = color_scheme(iTime);
    vec3 k_spec = vec3(1.0, 1.0, 1.0);
    float shininess = 10.0;
    
    rotate(cam_pos, angle);
    rotate(cam_dir, angle);
    
    float min_distance = march(cam_pos, cam_dir);
    
    vec3 closest_point = cam_pos + cam_dir * min_distance;
    
   
    if(min_distance >= MAX_DISTANCE) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0); 
        return;
    }
    //If the ray intersected, calculate the shading of the object
    fragColor = vec4(phong_illumination(k_amb, k_diff, k_spec, shininess, closest_point, cam_pos), 1.0);

    //If the ray did not intersect, calculate the glow
 
            //clamp(glow_intensity / sqrt(pow(min_distance, 2.0) + 0.05), 0.0, 1.0) * vec4(0.5, 0.25, 0.2, 1.0 );
    
	
}

