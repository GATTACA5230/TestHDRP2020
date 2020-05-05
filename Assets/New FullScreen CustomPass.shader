Shader "FullScreen/NewFullScreenCustomPass"
{
    Properties {
        _ContrastThreshold ("Contrast Threshold", Float) = 0.5
        _ContrastInput ("Contrast Input", Float) = 1
        _DivideFactor ("Divide Factor", Float) = 2
        _OutlineWidth ("Outline Width", Int) = 1
        _OutlineColor ("Outline Color", Color) = (1,1,1,1)
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

        // Add your custom pass code here
        
        // get color
        //return color;
        
        // get device depth
        //float deviceDepth = depth;
        //deviceDepth = posInput.deviceDepth;
        //float4 depthColor = float4(deviceDepth,deviceDepth,deviceDepth,1);
        //return depthColor;
        
        // get linear depth
        //float linearDepth = posInput.linearDepth;
        //float4 linearDepthColor = float4(linearDepth,linearDepth,linearDepth,1);
        //return linearDepthColor;
        
        // get world position
        //float3 positionWS = posInput.positionWS;
        //positionWS = GetAbsolutePositionWS(positionWS);
        //return float4(positionWS,1);
        
        // get world normal
        //NormalData normalData;
        //DecodeFromNormalBuffer(posInput.positionSS, normalData);
        //return float4(normalData.normalWS,1);
        
        // get UNITY_MATRIX_I_VP
        //if(posInput.positionNDC.x < 0.5 && posInput.positionNDC.y < 0.5)
        //    return UNITY_MATRIX_I_VP[0];
        //    
        //if(posInput.positionNDC.x > 0.5 && posInput.positionNDC.y < 0.5)
        //    return UNITY_MATRIX_I_VP[1];
        //    
        //if(posInput.positionNDC.x < 0.5 && posInput.positionNDC.y > 0.5)
        //    return UNITY_MATRIX_I_VP[2];
        //    
        //if(posInput.positionNDC.x > 0.5 && posInput.positionNDC.y > 0.5)
        //    return UNITY_MATRIX_I_VP[3];
        
        // get positionNDC[0, 1)
        //float2 positionNDC = posInput.positionNDC;
        //return float4(positionNDC,0,1);
        
        // get clip space position
        //float4 positionCS = ComputeClipSpacePosition(posInput.positionNDC, posInput.deviceDepth);
        //return positionCS;
        
        // ddx & ddy outline by device depth
        //float md = posInput.deviceDepth * 1000;
        //float finalColor = abs(ddx(md)) + abs(ddy(md));
        //finalColor = saturate(finalColor); 
        //return finalColor;
        
        // offset outline by world normal
        float linearDepth = posInput.linearDepth;
        int outlineWidth = _OutlineWidth;
        outlineWidth = saturate(1 - linearDepth / 10000) * 3; 
        
        NormalData normalData0;
        NormalData normalData1;
        NormalData normalData2;
        DecodeFromNormalBuffer(posInput.positionSS, normalData0);
        DecodeFromNormalBuffer(posInput.positionSS + float3(outlineWidth,0,0), normalData1);
        DecodeFromNormalBuffer(posInput.positionSS + float3(0,outlineWidth,0), normalData2);
        float distanceX = distance(normalData0.normalWS, normalData1.normalWS);
        float distanceY = distance(normalData0.normalWS, normalData2.normalWS);
        float distance = distanceX + distanceY;
        distance = distance / _DivideFactor; 
        
        distance = ((distance - 0.5f) * _ContrastInput) + 0.5f;
        distance = saturate(distance);
        float4 finalColor = lerp(color, _OutlineColor, distance);
                
        return finalColor;
        
        // Fade value allow you to increase the strength of the effect while the camera gets closer to the custom pass volume
        //float f = 1 - abs(_FadeValue * 2 - 1);
        //return float4(color.rgb + f, color.a);
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
