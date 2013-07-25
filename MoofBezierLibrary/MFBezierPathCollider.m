//
//  MFBezierPathCollider.m
//  PathIntersectionLab
/*
 
 .  /\/\/\__/\/\/\   .   Copyright (c)2013 Tristan Leblanc                .
 .  \/\/\/..\/\/\/   .   MooseFactory Software                            .
 .       |  |        .   tristan@moosefactory.eu                          .
 .       (oo)        .                                                    .
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "MFBezierPathCollider.h"

#define MFBezierPathCollide_TestContextSize 1

@interface MFBezierPathCollider ( Private )
    -(BOOL)createTestContext;
    -(CGContextRef)create16BitsGrayContextOfSize:(NSSize)inSize;

    -(void)drawPath:(CGPathRef)Path withClip:(CGPathRef)clipPath inContext:(CGContextRef)ctx;
    -(void)drawPaths:(CGPathRef*)Paths numPaths:(NSInteger)numPaths withClip:(CGPathRef)clipPath inContext:(CGContextRef)ctx;
@end


@implementation MFBezierPathCollider

-(id)initWithView:(NSView*)view
{
    if ( self = [super init] ) {
        if ( ! [self createTestContext]) {
            NSLog(@"MFBezierPathCollider - Can't create TestContext...");
        }
        [self attachToView:view];
    }
    return self;
}

-(void)dealloc
{
    if (testContext) CGContextRelease(testContext);
    if (computeContext) CGContextRelease(computeContext);
    [super dealloc];
}

-(void)attachToView:(NSView*)inView
{
    if (!inView) {
        NSLog(@"MFBezierPathCollider - Passed View is NULL..");
        return;
    }    
    if ( ![self setComputeContextSize:inView.bounds.size]) {
        NSLog(@"MFBezierPathCollider - Can't create Compute Context...");
    }
}

-(BOOL)setComputeContextSize:(NSSize)size
{
    if ( NSEqualSizes(contextSize,size) && computeContext ) {
        return YES;
    }
    if (computeContext) CGContextRelease(computeContext);
    computeContext = NULL;
    contextSize = size;
    if ( ( size.width < 1.0f ) || ( size.height < 1.0f ) ) {
        NSLog(@"MFBezierPathCollider - Can't create context with a null dimension..");
        return NO;
    }
    
    computeContext = [self create16BitsGrayContextOfSize:size];
    NSLog(@"Compute Context Created");
    return (computeContext!=NULL);
}

-(BOOL)pathIntersectPath:(CGPathRef)testPath versus:(CGPathRef)path
{
    CGRect box1 = CGPathGetBoundingBox(testPath);
    CGRect box2 = CGPathGetBoundingBox(path);
    if (!CGRectIntersectsRect(box1, box2)) return NO;
    
    [self drawPath:path withClip:testPath inContext:computeContext];
    CGImageRef img = CGBitmapContextCreateImage(computeContext);
    
    CGRect  onePixSquare = CGRectMake(0.0f,0.0f,1.0f,1.0f);
    CGContextClearRect(testContext, onePixSquare);
    CGContextDrawImage(testContext, onePixSquare, img);
    long*   data = CGBitmapContextGetData(testContext);
    return (*data!=0);
}

// To Do
/*
-(BOOL)pathIntersectPaths:(CGPathRef)testPath versus:(CGPathRef*)paths numPaths:(NSInteger)numPaths
{
    [self drawPaths:paths numPaths:numPaths withClip:testPath inContext:computeContext];
    CGImageRef img = CGBitmapContextCreateImage(computeContext);
    
    CGRect  onePixSquare = CGRectMake(0.0f,0.0f,1.0f,1.0f);
    CGContextClearRect(testContext, onePixSquare);
    CGContextDrawImage(testContext, onePixSquare, img);
    long*   data = CGBitmapContextGetData(testContext);
    return (*data!=0);
}
*/
@end

#pragma -
#pragma Private

@implementation MFBezierPathCollider (Private)


-(BOOL)createTestContext
{
    if (!testContext) {
        testContext = [self create16BitsGrayContextOfSize:NSMakeSize(MFBezierPathCollide_TestContextSize,MFBezierPathCollide_TestContextSize)];
    }
    return (testContext!=NULL);
}


-(CGContextRef)create16BitsGrayContextOfSize:(NSSize)inSize
{
    size_t w = (size_t)inSize.width;
    size_t h = (size_t)inSize.height;
    size_t nComps = 1;
    size_t bits = 16;
    size_t bitsPerPix = bits*nComps;
    size_t bytesPerRow= bitsPerPix*w;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    
    CGContextRef bmContext = CGBitmapContextCreate(NULL, w, h, bits, bytesPerRow, cs, 0);
    CGContextSetFillColorSpace(bmContext,cs);
    CGContextSetStrokeColorSpace(bmContext,cs);
    return bmContext;
}

-(void)drawPath:(CGPathRef)Path withClip:(CGPathRef)clipPath inContext:(CGContextRef)ctx
{
    CGContextSaveGState(ctx);
    CGRect bounds = NSMakeRect(0.0f,0.0f,contextSize.width,contextSize.height);
    CGContextClearRect(ctx, bounds);    
    CGFloat clipedColor[] = {1.0f,1.0f,1.0f,1.0f}; // Full white
    CGContextSetFillColor(ctx,clipedColor);
    
    CGContextAddPath(ctx, clipPath);
    CGContextClip(ctx);
    CGContextAddPath(ctx, Path);
    CGContextFillPath(ctx);
    CGContextRestoreGState(ctx);
}


-(void)drawPaths:(CGPathRef*)Paths numPaths:(NSInteger)numPaths withClip:(CGPathRef)clipPath inContext:(CGContextRef)ctx
{
    CGContextSaveGState(ctx);
    CGRect bounds = NSMakeRect(0.0f,0.0f,contextSize.width,contextSize.height);
    CGContextClearRect(ctx, bounds);
    CGFloat clipedColor[] = {1.0,1.0,1.0,1.0}; // Full white
    CGContextSetFillColor(ctx,clipedColor);
    
    CGContextAddPath(ctx, clipPath);
    CGContextClip(ctx);
    CGPathRef* aPath = Paths;
    for (int i=0;i<numPaths;i++) {
        CGContextAddPath(ctx, *aPath);
        aPath++;
    }
    CGContextFillPath(ctx);
    CGContextRestoreGState(ctx);
}

@end
