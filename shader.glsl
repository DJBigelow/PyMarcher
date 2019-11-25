float glow_intensity = 0.12;
float fog_intensity = 0.5;



vec3 color_scheme(float t) {
    vec3 contrast = vec3(0.5, 0.5, 0.5);
    vec3 brightness = vec3(0.5, 0.5, 0.5);
    vec3 frequency = vec3(0.5, 0.5, 0.5);
    vec3 phase = vec3(0.0, 0.33, 0.66);
    
    return contrast + brightness * cos(6.28318 * (frequency * t + phase));
}



float sphere_sdf( vec3 origin, float radius, vec3 pos) {
    return length(origin - pos) - radius;
}



float box_sdf(vec3 pos, vec3 dim, float rounding) {
 	vec3 q = abs(pos) - dim;
    return length(max(q, 0.0)) + min( max( q.x, max(q.y, q.z)), 0.0) - rounding;
}



float torus_sdf(vec3 pos, vec2 dim) {
    return length(vec2(length(pos.xz) - dim.x, dim.y)) - dim.y;
}



float scene(vec3 pos) {
	float min_distance = sphere_sdf(vec3(-1, -1, -1), 0.5, pos);
    min_distance = min(min_distance, sphere_sdf(vec3(1, -1,-1), 0.5, pos));
    min_distance = min(min_distance, sphere_sdf(vec3(0, 1, -1), 0.5, pos));
    min_distance = min(min_distance, sphere_sdf(vec3(0, -0.25, -1), 0.25, pos));
    return min_distance;    
}

                       
                       
vec4 march(vec3 ray, vec3 pos) {
    vec4 frag_color = vec4(color_scheme(iTime), 1.0);
    
    float dist;
    
    float dist_marched = 0.0;
    
    bool ray_intersect = false;
    
    float min_dist = scene(pos);
    
    for (int i = 0; i < 100; i++) {
     	dist = scene(pos);
        
        min_dist = min(min_dist, dist);
        
        dist_marched += length(ray);
        
        if (dist < 0.01) { 
            ray_intersect = true;        	
            break;
        }
        
        //March forward by dist
        pos += ray*dist;
    }
    
    
	//If there was no intersect, calculate the glow based on the inverse of the minimum distance
    if (!ray_intersect) {
        frag_color *= clamp(glow_intensity / sqrt(pow(min_dist, 2.0) + 0.05), 0.0, 1.0) ;
    }
    
    return frag_color;
}


void rotate(inout vec3 vec, vec2 angle) {
 	vec.yz = cos(angle.y) * vec.yz + sin(angle.y) * vec2(-1, 1) * vec.zy;
    vec.xz = cos(angle.x) * vec.xz + sin(angle.x) * vec2(-1, 1) * vec.zx;
}

    
    
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = 8.0 * (fragCoord - iResolution.xy * 0.5) / iResolution.x;
    
    							//Pixel xy components
    vec3 ray = normalize ( vec3((fragCoord - iResolution.xy * 0.5) / iResolution.x,
                                //Seperation of 'eye' and 'screen'
                               	 1.0) );
    vec3 pos = vec3(0, 0, -8);
    
    vec2 angle = vec2(iTime, 0.3);
    
    rotate(pos, angle);
    rotate(ray, angle);
    
    //fragColor = vec4(step(0.0, scene(ray*8.0 + pos))); 
       
	fragColor = march(ray, pos);
}

