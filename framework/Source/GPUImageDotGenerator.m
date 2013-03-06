#import "GPUImageDotGenerator.h"

NSString *const kGPUImageDotVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 
 uniform float crosshairWidth;
 
 varying lowp vec2 centerLocation;
 varying lowp float pointSpacing;

 attribute vec4 inputTextureCoordinate;
 varying vec2 textureCoordinate;
 
 void main()
 {
     //gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
     
     //gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
     gl_Position = vec4(((position.xy * 2.0) - 1.0), 0.0, 1.0);
     gl_PointSize = crosshairWidth + 1.0;
     pointSpacing = 1.0 / crosshairWidth;
     centerLocation = vec2(pointSpacing * ceil(crosshairWidth / 2.0), pointSpacing * ceil(crosshairWidth / 2.0));
 }
);

NSString *const kGPUImageDotFragmentShaderString = SHADER_STRING
(

 uniform lowp vec3 crosshairColor;
 varying lowp vec2 centerLocation;
 varying lowp float pointSpacing;
 
 uniform sampler2D inputImageTexture;
 varying highp vec2 textureCoordinate;


 void main()
 {
     lowp vec2 distanceFromCenter = abs(centerLocation - gl_PointCoord.xy);
     //lowp float axisTest = step(pointSpacing, gl_PointCoord.y) * step(distanceFromCenter.x, 0.09) + step(pointSpacing, gl_PointCoord.x) * step(distanceFromCenter.y, 0.09);
     
     //gl_FragColor = vec4(crosshairColor * axisTest, axisTest);
    
     //lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
	 //lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     
     lowp float xd = distanceFromCenter.x * distanceFromCenter.x;
     lowp float yd = distanceFromCenter.y * distanceFromCenter.y;
     lowp float radius = 0.5;
     lowp float border = 0.1;
     lowp vec4 textureColor;
     
     lowp vec2 m = vec2(0.5, 0.5);
     lowp float dist = radius - sqrt(xd + yd);

     lowp float green = 0.0;
     if (dist > border) {
         green = 1.0;
         gl_FragColor = vec4(0.0, green, 0.0, 1.0);
     } else if (dist > 0.0) {
         green = dist / border;
         
         //green = max(green, textureColor.a);
         
         gl_FragColor = vec4(0.0, green, 0.0, green);
         //gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);

     } else {
          gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
     }
     
 
     //gl_FragColor = vec4(0.0, 1.0 - distanceFromCenter.y, 0.0, 1.0);
     
     
     //float border = 0.01;
     //float radius = 0.5;
     //vec4 color0 = vec4(0.0, 0.0, 0.0, 1.0);
     //vec4 color1 = vec4(1.0, 1.0, 1.0, 1.0);
     
     //vec2 m = vec2(0.5, 0.5);
     //float dist = radius - sqrt(m.x * m.x + m.y * m.y);
     //
     //float t = 0.0;
     //if (dist > border)
     //    t = 1.0;
     //else if (dist > 0.0)
     //    t = dist / border;
     
     //gl_FragColor = mix(color0, color1, t);
     

 
 }
);


@implementation GPUImageDotGenerator

@synthesize crosshairWidth = _crosshairWidth;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageDotVertexShaderString fragmentShaderFromString:kGPUImageDotFragmentShaderString]))
    {
        return nil;
    }
    
    runSynchronouslyOnVideoProcessingQueue(^{
        crosshairWidthUniform = [filterProgram uniformIndex:@"crosshairWidth"];
        crosshairColorUniform = [filterProgram uniformIndex:@"crosshairColor"];
        
        self.crosshairWidth = 2.0;
        [self setCrosshairColorRed:0.0 green:1.0 blue:0.0];
    });
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    
    return self;
}

#pragma mark -
#pragma mark Rendering

- (void)renderCrosshairsFromArray:(GLfloat *)crosshairCoordinates count:(NSUInteger)numberOfCrosshairs frameTime:(CMTime)frameTime;
{
    if (self.preventRendering)
    {
        return;
    }
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext setActiveShaderProgram:filterProgram];
        
        [self setFilterFBO];
        
        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, crosshairCoordinates);
        
        glDrawArrays(GL_POINTS, 0, numberOfCrosshairs);
        
        [self informTargetsAboutNewFrameAtTime:frameTime];
    });
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    // Prevent rendering of the frame by normal means
}

#pragma mark -
#pragma mark Accessors

- (void)setCrosshairWidth:(CGFloat)newValue;
{
    _crosshairWidth = newValue;
    
    [self setFloat:_crosshairWidth forUniform:crosshairWidthUniform program:filterProgram];
}

- (void)setCrosshairColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;
{
    GPUVector3 crosshairColor = {redComponent, greenComponent, blueComponent};
    
    [self setVec3:crosshairColor forUniform:crosshairColorUniform program:filterProgram];
}

@end
