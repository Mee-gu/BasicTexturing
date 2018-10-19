/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of renderer class which performs Metal setup and per frame rendering
*/

@import simd;
@import MetalKit;

#import "AAPLRenderer.h"
#import "AAPLImage.h"

// Header shared between C code here, which executes Metal API commands, and .metal files, which
//   uses these types as inputs to the shaders
#import "AAPLShaderTypes.h"

// Main class performing the rendering
@implementation AAPLRenderer
{
    // The device (aka GPU) we're using to render
    id<MTLDevice> _device;

    // Our render pipeline composed of our vertex and fragment shaders in the .metal shader file
    id<MTLRenderPipelineState> _pipelineState;

    // The command Queue from which we'll obtain command buffers
    id<MTLCommandQueue> _commandQueue;

    // The Metal texture object
//    id<MTLTexture> _textureDemo;
//    id<MTLTexture> _textureBlend;
    id<MTLTexture> _textureBlend[2];
    id<MTLSamplerState> _sampler;
    

    // The Metal buffer in which we store our vertex data
    id<MTLBuffer> _vertices;

    // Metal texture object to be referenced via an argument buffer
    id<MTLTexture> _texture[2];
    
    id<MTLBuffer> _uniformBuffer;
    // The number of vertices in our vertex buffer
    NSUInteger _numVertices;

    // The current size of our view so we can use this in our render pipeline
    vector_uint2 _viewportSize;
}

#if TARGET_OS_IPHONE
-(const unsigned char*)getUIImageData:(UIImage *)image
{
    CGImageRef cgimage = [image CGImage];
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(cgimage));
    const unsigned char * imageRGBA =  CFDataGetBytePtr(data);
    return imageRGBA;
}

- (id<MTLTexture>)textureForImage:(UIImage *)image
{
    CGImageRef imageRef = [image CGImage];
    
    // Create a suitable bitmap context for extracting the bits of the image
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint8_t *rawData = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    // Flip the context so the positive Y axis points down
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                 width:width
                                                                                                height:height
                                                                                             mipmapped:YES];
    id<MTLTexture> texture = [_device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [texture replaceRegion:region mipmapLevel:0 withBytes:rawData bytesPerRow:bytesPerRow];
    
    free(rawData);
    
    return texture;
}
#endif

- (void)updateUniforms
{
    if (!_uniformBuffer)
    {
        _uniformBuffer = [_device newBufferWithLength:sizeof(Uniforms)
                                                      options:MTLResourceOptionCPUCacheModeDefault];
    }
    
    Uniforms uniforms;
    uniforms.viewportSize = _viewportSize;
//    uniforms.modelViewProjectionMatrix = self.modelViewProjectionMatrix;
//    uniforms.normalMatrix = simd::inverse(simd::transpose(UpperLeft3x3(self.modelViewMatrix)));
    
    memcpy([_uniformBuffer contents], &uniforms, sizeof(Uniforms));
}

-(void) loadResources
{
    MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];
    
    NSError *error;
    
    for(NSUInteger i = 0; i < 2; i++)
    {
        NSString *textureName = [[NSString alloc] initWithFormat:@"Texture%lu", i];
        
        _texture[i] = [textureLoader newTextureWithName:textureName
                                            scaleFactor:1.0
                                                 bundle:nil
                                                options:nil
                                                  error:&error];
        if(!_texture[i])
        {
            [NSException raise:NSGenericException
                        format:@"Could not load texture with name %@: %@", textureName, error.localizedDescription];
        }
        
        _texture[i].label = textureName;
    }
}

/// Initialize with the MetalKit view from which we'll obtain our Metal device
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        _device = mtkView.device;
        
        NSString * imageDemoLocation = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"jpg"];
        UIImage * uiimageDemo = [UIImage imageWithContentsOfFile:imageDemoLocation];// NSBundle加载
        
        NSString * imageBlendLocation = [[NSBundle mainBundle] pathForResource:@"blend" ofType:@"png"];
        UIImage * uiimageBlend = [UIImage imageWithContentsOfFile:imageBlendLocation];
        
        //load jpeg
//        _textureDemo = [self textureForImage:uiimageDemo];
//        _textureBlend = [self textureForImage:uiimageBlend];
        _textureBlend[0] = [self textureForImage:uiimageDemo];
        _textureBlend[1] = [self textureForImage:uiimageBlend];
        
        
        // Load data for resources
        [self loadResources];

        // Set up a simple MTLBuffer with our vertices which include texture coordinates
        static const AAPLVertex quadVertices[] =
        {
            // Pixel positions, Texture coordinates
            { {  250,  -250 },  { 1.f, 0.f } },
            { { -250,  -250 },  { 0.f, 0.f } },
            { { -250,   250 },  { 0.f, 1.f } },

            { {  250,  -250 },  { 1.f, 0.f } },
            { { -250,   250 },  { 0.f, 1.f } },
            { {  250,   250 },  { 1.f, 1.f } },
        };

        // Create our vertex buffer, and initialize it with our quadVertices array
        _vertices = [_device newBufferWithBytes:quadVertices
                                         length:sizeof(quadVertices)
                                        options:MTLResourceStorageModeShared];
        
        // Calculate the number of vertices by dividing the byte length by the size of each vertex
        _numVertices = sizeof(quadVertices) / sizeof(AAPLVertex);

        /// Create our render pipeline
        MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
        vertexDescriptor.attributes[0].format = MTLVertexFormatFloat2;
        vertexDescriptor.attributes[0].bufferIndex = 0;
        vertexDescriptor.attributes[0].offset = offsetof(AAPLVertex, position);
        
        vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
        vertexDescriptor.attributes[1].bufferIndex = 0;
        vertexDescriptor.attributes[1].offset = offsetof(AAPLVertex, textureCoordinate);
        
        vertexDescriptor.layouts[0].stride = sizeof(AAPLVertex);
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
        
        MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
        samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
        samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
        _sampler = [_device newSamplerStateWithDescriptor:samplerDescriptor];
        
        
        // Load all the shader files with a .metal file extension in the project
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

        // Load the vertex function from the library
        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"xlatMtlMain1"];

        // Load the fragment function from the library
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"xlatMtlMain2"];

        // Set up a descriptor for creating a pipeline state object
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Texturing Pipeline";
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.vertexDescriptor = vertexDescriptor;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;

        NSError *error = NULL;
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                 error:&error];
        if (!_pipelineState)
        {
            // Pipeline State creation could fail if we haven't properly set up our pipeline descriptor.
            //  If the Metal API validation is enabled, we can find out more information about what
            //  went wrong.  (Metal API validation is enabled by default when a debug build is run
            //  from Xcode)
            NSLog(@"Failed to created pipeline state, error %@", error);
        }

        // Create the command queue
        _commandQueue = [_device newCommandQueue];
    }

    return self;
}

/// Called whenever view changes orientation or is resized
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // Save the size of the drawable as we'll pass these
    //   values to our vertex shader when we draw
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

/// Called whenever the view needs to render a frame
- (void)drawInMTKView:(nonnull MTKView *)view
{

    [self updateUniforms];
    
    // Create a new command buffer for each render pass to the current drawable
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    // Obtain a renderPassDescriptor generated from the view's drawable textures
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;

    if(renderPassDescriptor != nil)
    {
        // Create a render command encoder so we can render into something
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        // Set the region of the drawable to which we'll draw.
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];

        [renderEncoder setRenderPipelineState:_pipelineState];

        [renderEncoder setVertexBuffer:_vertices
                                offset:0
                              atIndex:AAPLVertexInputIndexVertices];

//        [renderEncoder setVertexBytes:&_viewportSize
//                               length:sizeof(_viewportSize)
//                              atIndex:AAPLVertexInputIndexViewportSize];
        
        [renderEncoder setVertexBuffer:_uniformBuffer
                                offset:0
                               atIndex:1];

        // Set the texture object.  The AAPLTextureIndexBaseColor enum value corresponds
        ///  to the 'colorMap' argument in our 'samplingShader' function because its
        //   texture attribute qualifier also uses AAPLTextureIndexBaseColor for its index

        //for array of textures, you should use set each array element accessed with the [n] subscript syntax
        [renderEncoder setFragmentTexture:_textureBlend[0]
                                  atIndex:2];
//        [renderEncoder setFragmentSamplerState:_sampler atIndex:AAPLTextureIndexBaseColor];
        
        [renderEncoder setFragmentTexture:_textureBlend[1]
                                  atIndex:3];
//        [renderEncoder setFragmentSamplerState:_sampler atIndex:1];

        [renderEncoder setFragmentTexture:_texture[0]
                                  atIndex:0];
        [renderEncoder setFragmentTexture:_texture[1]
                                  atIndex:1];
        [renderEncoder setFragmentSamplerState:_sampler atIndex:0];
        // Draw the vertices of our triangles
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:_numVertices];

        [renderEncoder endEncoding];

        // Schedule a present once the framebuffer is complete using the current drawable
        [commandBuffer presentDrawable:view.currentDrawable];
    }


    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
}

@end
