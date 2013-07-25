//
//  NSBezierPath-Extras.m
//  MFCGShapeBuilder
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
#import "NSBezierPath-Extras.h"

@implementation NSBezierPath (Extras)

// This method works only in Mac OS X v10.2 and later.
- (CGPathRef)cgPath
{
    NSInteger i, numElements;
 
    // Need to begin a path here.
    CGPathRef           immutablePath = NULL;
 
    // Then draw the path elements.
    numElements = [self elementCount];
    if (numElements > 0)
    {
        CGMutablePathRef    path = CGPathCreateMutable();
        NSPoint             points[3];
        BOOL                didClosePath = YES;
 
        for (i = 0; i < numElements; i++)
        {
            switch ([self elementAtIndex:i associatedPoints:points])
            {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                    break;
 
                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                    didClosePath = NO;
                    break;
 
                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                        points[1].x, points[1].y,
                                        points[2].x, points[2].y);
                    didClosePath = NO;
                    break;
 
                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    didClosePath = YES;
                    break;
            }
        }
 
        // Be sure the path is closed or Quartz may not do valid hit detection.
        if (!didClosePath)
            CGPathCloseSubpath(path);
 
        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
 
    return immutablePath;
}

-(BOOL)containsPoint:(NSPoint)point inFillArea:(BOOL)inFill
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGPathRef   cgPath = [self cgPath];
    
    CGPathDrawingMode mode = kCGPathStroke;
    if (inFill)
    {
        if ([self windingRule])
            mode = kCGPathEOFill;
        else
            mode = kCGPathFill;
    }
    // Save the graphics state so that the path can be
    // removed later.
    CGContextSaveGState(context);
    CGContextAddPath(context, cgPath);
    
   // CGContextFillPath(context);
    
    BOOL isHit = CGContextPathContainsPoint(context, point, mode);
    
    CGContextRestoreGState(context);
    
    return isHit;
}

+(NSBezierPath*)roundRectPath:(NSRect)frame radius:(float)radius
{
	NSBezierPath	*path=[[NSBezierPath alloc] init];
	NSPoint			point=NSMakePoint(frame.origin.x,frame.origin.y+radius);

	[path moveToPoint:point];
	point.y+=frame.size.height-radius-radius;
	[path lineToPoint:point];
	// --- top ---
	NSPoint startPoint=point;
	point.x+=radius;
	[path appendBezierPathWithArcWithCenter:point radius:radius startAngle:180 endAngle:90 clockwise:YES];
	point.y+=radius;
	//[path lineToPoint:point];

	point.x+=frame.size.width-radius-radius;
	[path lineToPoint:point];
	startPoint=point;
	point.y-=radius;	
	[path appendBezierPathWithArcWithCenter:point radius:radius startAngle:90 endAngle:0 clockwise:YES];
	point.x+=radius;	
	//[path lineToPoint:point];
	point.y-=frame.size.height-radius-radius;
	[path lineToPoint:point];
	startPoint=point;
	point.x-=radius;	
	[path appendBezierPathWithArcWithCenter:point radius:radius startAngle:0 endAngle:-90 clockwise:YES];
	point.y-=radius;	
	//[path lineToPoint:point];
	point.x-=frame.size.width-radius-radius;
	[path lineToPoint:point];
	startPoint=point;
	point.y+=radius;	
	[path appendBezierPathWithArcWithCenter:point radius:radius startAngle:-90 endAngle:-180 clockwise:YES];
	//point.x-=radius;	
	//[path lineToPoint:point];
	[path closePath];
	
	return path;
}

+(NSBezierPath*)roundRectPath:(NSRect)frame radii:(float*)radii
{
	float*	radius=radii;
	NSBezierPath	*path=[[NSBezierPath alloc] init];
	NSPoint			point=NSMakePoint(frame.origin.x,frame.origin.y+(*radius));

	[path moveToPoint:point];
	
	// --- top left
	point.y+=frame.size.height-(*radius)-(*radius);
	[path lineToPoint:point];
	if (*radius) {
		point.x+=(*radius);
		if (*radius) [path appendBezierPathWithArcWithCenter:point radius:(*radius) startAngle:180 endAngle:90 clockwise:YES];
		point.y+=(*radius);
		//[path lineToPoint:point];
	}
	
	// --- top right
	radius++;
	point.x+=frame.size.width-(*radius)-(*radius);
	[path lineToPoint:point];
	if (*radius) {
		point.y-=(*radius);	
		[path appendBezierPathWithArcWithCenter:point radius:(*radius) startAngle:90 endAngle:0 clockwise:YES];
		point.x+=(*radius);	
		//[path lineToPoint:point];
	}
	
	// --- bottom right
	radius++;
	point.y-=frame.size.height-(*radius)-(*radius);
	[path lineToPoint:point];
	if (*radius) {
		point.x-=(*radius);	
		[path appendBezierPathWithArcWithCenter:point radius:(*radius) startAngle:0 endAngle:-90 clockwise:YES];
		point.y-=(*radius);	
		//[path lineToPoint:point];
	}
	
	// --- bottom left
	radius++;
	point.x-=frame.size.width-(*radius)-(*radius);
	[path lineToPoint:point];
	if (*radius) {
		point.y+=(*radius);	
		[path appendBezierPathWithArcWithCenter:point radius:(*radius) startAngle:-90 endAngle:-180 clockwise:YES];
		//point.x-=radius;	
		//[path lineToPoint:point];
	}
	
	[path closePath];
	
	return path;
}

@end
