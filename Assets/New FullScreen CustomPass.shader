Shader "FullScreen/NewFullScreenCustomPass"
{
    Properties {
        _ContrastThreshold ("Contrast Threshold", Float) = 0.5
        _ContrastInput ("Contrast Input", Float) = 1
        _DivideFactor ("Divide Factor", Float) = 2
        _OutlineWidth ("Outline Width", Float) = 1
        _OutlineColor ("Outline Color", Color) = (1,1,1,1)
        _NormalFactor ("Normal Factor", Float) = 1
        
    }
    
    HLSLINCLUDE

    #pragma vertex Vert

    #pragma target 4.5
    #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch

    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/RenderPass/CustomPass/CustomPassCommon.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/NormalBuffer.hlsl"

    // The PositionInputs struct allow you to retrieve a lot of useful information for your fullScreenShader:
    // struct PositionInputs
    // {
    //     float3 positionWS;  // World space position (could be camera-relative)
    //     float2 positionNDC; // Normalized screen coordinates within the viewport    : [0, 1) (with the half-pixel offset)
    //     uint2  positionSS;  // Screen space pixel coordinates                       : [0, NumPixels)
    //     uint2  tileCoord;   // Screen tile coordinates                              : [0, NumTiles)
    //     float  deviceDepth; // Depth from the depth buffer                          : [0, 1] (typically reversed)
    //     float  linearDepth; // View space Z coordinate                              : [Near, Far]
    // };

    // To sample custom buffers, you have access to these functions:
    // But be careful, on most platforms you can't sample to the bound color buffer. It means that you
    // can't use the SampleCustomColor when the pass color buffer is set to custom (and same for camera the buffer).
    // float4 SampleCustomColor(float2 uv);
    // float4 LoadCustomColor(uint2 pixelCoords);
    // float LoadCustomDepth(uint2 pixelCoords);
    // float SampleCustomDepth(float2 uv);

    // There are also a lot of utility function you can use inside Common.hlsl and Color.hlsl,
    // you can check them out in the source code of the core SRP package.
    
    float _ContrastThreshold;
    float _ContrastInput;
    float _DivideFactor;
    int _OutlineWidth;
    float4 _OutlineColor; 
    SAMPLER(sampler_NormalBufferTexture);
    float _NormalFactor;
    
    // Incorrect result
    float SampleCameraDepthSK(float2 uv)
    {
        return SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, uv * _RTHandleScaleHistory.xy, 0).r;
    }
     
    void DecodeFromNormalBufferNDC(float2 positionNDC, out NormalData normalData)
    {
        float4 normalBuffer = SAMPLE_TEXTURE2D_X(_NormalBufferTexture, sampler_NormalBufferTexture, positionNDC);
        DecodeFromNormalBuffer(normalBuffer, positionNDC, normalData);
    }
    
    float Contrast(float contrastInput, float valueInput){
        return ((valueInput - 0.5f) * contrastInput) + 0.5f;
    }

    float4 FullScreenPass(Varyings varyings) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(varyings);
        float depth = LoadCameraDepth(varyings.positionCS.xy);
        PositionInputs posInput = GetPositionInput(varyings.positionCS.xy, _ScreenSize.zw, depth, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);
        float3 viewDirection = GetWorldSpaceNormalizeViewDir(posInput.positionWS);
        float4 color = float4(0.0, 0.0, 0.0, 0.0);

        // Load the camera color buffer at the mip 0 if we're not at the before rendering injection point
        if (_CustomPassInjectionPoint != CUSTOMPASSINJECTIONPOINT_BEFORE_RENDERING)
            color = float4(CustomPassLoadCameraColor(varyings.positionCS.xy, 0), 1);
            
        float4 finalColor;
        float outlineWidth;
        float distanceSumNormal;
        float distanceSumDepth;
        float distanceSum;
        float distanceXNormal;
        float distanceXDepth;
        float distanceYNormal;
        float distanceYDepth;
        float deviceDepth;
        float linearDepth;
        float md;
        float mn;

        // Add your custom pass code here
        
        // get color
        
        //// Method 1
        ////finalColor = color;
        //
        ////Method2
        //// Load the camera color buffer at the mip 0 if we're not at the before rendering injection point
        //if (_CustomPassInjectionPoint != CUSTOMPASSINJECTIONPOINT_BEFORE_RENDERING)
        //    color = float4(CustomPassSampleCameraColor(varyings.positionCS.xy * _ScreenSize.zw, 0), 1);
        //finalColor = color;
        
        // get device depth
        
        //// Method 1
        ////deviceDepth = depth;
        //
        //// Method 2
        ////deviceDepth = posInput.deviceDepth;
        //
        //// Method 3
        ////deviceDepth = SampleCameraDepth(varyings.positionCS.xy * _ScreenSize.zw);
        //
        //// Method 4 (Incorrect result)
        //deviceDepth = SampleCameraDepthSK(varyings.positionCS.xy * _ScreenSize.zw);
        //
        //finalColor = float4(deviceDepth,deviceDepth,deviceDepth,1);
        
        // get linear depth
        //linearDepth = posInput.linearDepth;
        //finalColor = float4(linearDepth,linearDepth,linearDepth,1);
        
        // get absolute world position
        //float3 positionWS = posInput.positionWS;
        //positionWS = GetAbsolutePositionWS(positionWS);
        //finalColor = float4(positionWS,1);
        
        // get world normal
        NormalData normalData;
        
        // Method 1
        DecodeFromNormalBuffer(posInput.positionSS, normalData);
        
        // Method 2
        //DecodeFromNormalBufferNDC(posInput.positionNDC, normalData);
        
        finalColor = float4(normalData.normalWS,1);
        
        // get UNITY_MATRIX_I_VP
        //if(posInput.positionNDC.x < 0.5 && posInput.positionNDC.y < 0.5)
        //    finalColor = UNITY_MATRIX_I_VP[0];
        //    
        //if(posInput.positionNDC.x > 0.5 && posInput.positionNDC.y < 0.5)
        //    finalColor =  UNITY_MATRIX_I_VP[1];
        //    
        //if(posInput.positionNDC.x < 0.5 && posInput.positionNDC.y > 0.5)
        //    finalColor =  UNITY_MATRIX_I_VP[2];
        //    
        //if(posInput.positionNDC.x > 0.5 && posInput.positionNDC.y > 0.5)
        //    finalColor =  UNITY_MATRIX_I_VP[3];
        
        // get positionNDC[0, 1)
        //float2 positionNDC = posInput.positionNDC;
        //finalColor = float4(positionNDC,0,1);
        
        // get clip space position
        //float4 positionCS = ComputeClipSpacePosition(posInput.positionNDC, posInput.deviceDepth);
        //finalColor = positionCS;
        
        // ddx & ddy outline by device depth
        //md = posInput.deviceDepth * 1000;
        //finalColor = abs(ddx(md)) + abs(ddy(md));
        //finalColor = saturate(finalColor);
        
        // ddx & ddy outline by linear depth
        //md = posInput.linearDepth * 20;
        //finalColor = abs(ddx(md)) + abs(ddy(md));
        //finalColor = saturate(finalColor); 
        
        // ddx & ddy outline by world normal
        //NormalData normalData;
        //
        //DecodeFromNormalBuffer(posInput.positionSS, normalData);
        //
        //mn = normalData.normalWS;
        //finalColor = abs(ddx(mn)) + abs(ddy(mn));
        //finalColor = saturate(finalColor); 
        
        // offset outline by world normal
        linearDepth = posInput.linearDepth;
        outlineWidth = _OutlineWidth;
        outlineWidth = saturate(1 - linearDepth / 1000) * outlineWidth; 
        
        NormalData normalData0;
        NormalData normalData1;
        NormalData normalData2;
        
        DecodeFromNormalBuffer(posInput.positionSS, normalData0);
        DecodeFromNormalBuffer(posInput.positionSS + float2(outlineWidth,0), normalData1);
        DecodeFromNormalBuffer(posInput.positionSS + float2(0,outlineWidth), normalData2);
        
        distanceXNormal = distance(normalData0.normalWS, normalData1.normalWS);
        distanceYNormal = distance(normalData0.normalWS, normalData2.normalWS);
        distanceSumNormal = distanceXNormal + distanceYNormal;
        distanceSumNormal = distanceSumNormal / _DivideFactor; 
        
        // offset outline by device depth
        linearDepth = posInput.linearDepth;
        outlineWidth = _OutlineWidth;
        outlineWidth = saturate(1 - linearDepth / 10000) * outlineWidth;
         
        float2 positionCS0 = varyings.positionCS.xy;
        float depth0 = LoadCameraDepth(positionCS0);
        PositionInputs posInput0 = GetPositionInput(positionCS0, _ScreenSize.zw, depth, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);
        float2 positionCS1 = varyings.positionCS.xy + float2(outlineWidth,0);
        float depth1 = LoadCameraDepth(positionCS1);
        PositionInputs posInput1 = GetPositionInput(positionCS1, _ScreenSize.zw, depth1, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);
        float2 positionCS2 = varyings.positionCS.xy + float2(0,outlineWidth);
        float depth2 = LoadCameraDepth(positionCS2);
        PositionInputs posInput2 = GetPositionInput(positionCS2, _ScreenSize.zw, depth2, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);
        
        distanceXDepth = distance(posInput0.linearDepth, posInput1.linearDepth);
        distanceYDepth = distance(posInput0.linearDepth, posInput2.linearDepth);
        distanceSumDepth = distanceXDepth + distanceYDepth;
        
        //distanceSum = _NormalFactor * distanceSumNormal + (1-_NormalFactor) * distanceSumDepth;
        distanceSum = max(distanceSumDepth, distanceSumNormal);
        
        distanceSum = distanceSum / _DivideFactor;
        distanceSum = Contrast(_ContrastInput, distanceSum);
        distanceSum = saturate(distanceSum);
        
        //color = float4(0,0,0,1);
        finalColor = lerp(color, _OutlineColor, distanceSum);
        //finalColor = color + distanceSum * _OutlineColor;
        
        return finalColor;
        
        // Fade value allow you to increase the strength of the effect while the camera gets closer to the custom pass volume
        float f = 1 - abs(_FadeValue * 2 - 1);
        return float4(color.rgb + f, color.a);
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "Custom Pass 0"

            ZWrite Off
            ZTest Always
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            HLSLPROGRAM
                #pragma fragment FullScreenPass
            ENDHLSL
        }
    }
    Fallback Off
}
