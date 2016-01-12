varying vec3 v_positionEC;
varying vec3 v_normalEC;
varying vec2 v_st;


vec4 windowToEye(vec4 fragCoord)
{
  vec2 uv = fragCoord.xy / czm_viewport.zw;
  float z_window = czm_unpackDepth(texture2D(czm_globeDepthTexture, uv));
  if (z_window == 1.0)
    discard;
  
  float near = czm_depthRange.near;
  float far = czm_depthRange.far;
  
  vec3 ndcPos;
  ndcPos.x = 2.0 * (fragCoord.x - czm_viewport.x) / czm_viewport.z - 1.0;
  ndcPos.y = 2.0 * (fragCoord.y - czm_viewport.y) / czm_viewport.w - 1.0;
  ndcPos.z = (2.0 * z_window - near - far) / (far - near);
    
  vec4 clipPos;
  clipPos.w = czm_projection[3][2] / (ndcPos.z - (czm_projection[2][2] / czm_projection[2][3]));
  clipPos.xyz = ndcPos * clipPos.w;
  
  return czm_inverseProjection * clipPos;
  //return vec4(ndcPos, 1.0);
}


void main()
{
    vec3 positionToEyeEC = -v_positionEC; 
        
    // get fragment 3D pos in eye coordinates using depth buffer value at fragment location
    vec4 v_posEC = windowToEye(gl_FragCoord);
    
    // get vertex pos in video cam reference frame
    vec4 camPosEC = czm_modelViewRelativeToEye * czm_translateRelativeToEye(camPosHigh_1, camPosLow_2);    
    vec4 v_posCam = v_posEC - camPosEC;
    
    // project to video cam plane
    //vec4 st = czm_projection*mat4(camAtt_3)*mat4(czm_inverseViewRotation)*v_posCam;
    //st /= st.w;    
    vec3 lookRay = camAtt_3*czm_inverseViewRotation3D*v_posCam.xyz;
    vec3 st = camProj_4 * (lookRay / lookRay.z);
    st.y = 1.0 - st.y;
    
    if (st.x < 0.0 || st.x > 1.0 || st.y < 0.0 || st.y > 1.0)
        discard;
    //st.x = clamp(st.x, 0.0, 1.0);
    //st.y = clamp(st.y, 0.0, 1.0);
    
    vec3 normalEC = normalize(v_normalEC);
#ifdef FACE_FORWARD
    normalEC = faceforward(normalEC, vec3(0.0, 0.0, 1.0), -normalEC);
#endif

    czm_materialInput materialInput;
    materialInput.normalEC = normalEC;
    materialInput.positionToEyeEC = positionToEyeEC;
    materialInput.st = vec2(st.x, st.y);
    czm_material material = czm_getMaterial(materialInput);    
    
#ifdef FLAT    
    gl_FragColor = vec4(material.diffuse + material.emission, material.alpha);
#else
    gl_FragColor = czm_phong(normalize(positionToEyeEC), material);
#endif

    //float depth = pow(v_posEC.z * 0.5 + 0.5, 8.0);
    //gl_FragColor = vec4(depth, depth, depth, 1.0);
}
