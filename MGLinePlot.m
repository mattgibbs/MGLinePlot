//
//  MGLinePlot.m
//  LCLS
//
//  Created by Matthew Gibbs on 10/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MGLinePlot.h"

@implementation MGLinePlot
@synthesize dataSource=_dataSource, xTickMarks = _xTickMarks, yTickMarks = _yTickMarks, xTickLabels = _xTickLabels, yTickLabels = _yTickLabels, title=_title;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        currentYTickMarks = nil;
        currentXTickMarks = nil;
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [numberFormatter setMaximumFractionDigits:2];
        [numberFormatter setMinimumFractionDigits:2];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(nil != self) {
        // Initialization code
        currentYTickMarks = nil;
        currentXTickMarks = nil;
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [numberFormatter setMaximumFractionDigits:2];
        [numberFormatter setMinimumFractionDigits:2];
    }
    return self;
}

#pragma mark - Line Plot Drawing Functions
-(void)drawBackgroundWithColor:(UIColor *)color{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [color setFill];
    CGContextFillRect(ctx, self.bounds);
}

- (CGGradientRef)fillGradient {
    if(NULL == fillGradient) {
        // lazily create the gradient, then reuse it
        CGFloat colors[8] = {0.7, 0.9, 1.0, 0.3,
                             0.7, 0.9, 1.0, 0.0};
        CGFloat colorStops[2] = {0.0, 1};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        fillGradient = CGGradientCreateWithColorComponents(colorSpace, colors, colorStops, 2);
        CGColorSpaceRelease(colorSpace);
    }
    return fillGradient;
}

-(void)drawPlot {
    //Generate tick marks if they aren't specified in advance.
    if (self.xTickMarks == nil) {
        //Use default tick mark spacing for x: 7 marks, evenly spaced from data xmin to data xmax.
        //All tick marks are kept in plot coordinates, not graphics coordinates.
        NSUInteger numxLines = 5;
        NSMutableArray *defaultxTickMarks = [NSMutableArray arrayWithCapacity:numxLines];
        NSDecimalNumber *xMax = [self.dataSource maxXValueForLinePlot:self];
        NSDecimalNumber *xMin = [self.dataSource minXValueForLinePlot:self];
        CGFloat xDelta = [[xMax decimalNumberBySubtracting:xMin] doubleValue];
        CGFloat xgridLineSpacing = xDelta / (numxLines - 1);
        for (int i = 0; i < numxLines; i++) {
            NSNumber *tickMark = [NSNumber numberWithFloat:((float)i * xgridLineSpacing) + [xMin doubleValue]];
            [defaultxTickMarks addObject:tickMark];
        }
        currentXTickMarks = [NSArray arrayWithArray:defaultxTickMarks];
    } else {
        currentXTickMarks = self.xTickMarks;
    }
    if (self.yTickMarks == nil) {
        //Use default tick mark spacing for y: 5 marks, evenly spaced from data ymin to data ymax.
        NSUInteger numyLines = 5;
        NSMutableArray *defaultyTickMarks = [NSMutableArray arrayWithCapacity:numyLines];
        NSDecimalNumber *yMax = [self.dataSource maxYValueForLinePlot:self];
        NSDecimalNumber *yMin = [self.dataSource minYValueForLinePlot:self];
        CGFloat yDelta = [[yMax decimalNumberBySubtracting:yMin] doubleValue];
        CGFloat ygridLineSpacing = yDelta / (numyLines - 1);
        for (int i = 0; i < numyLines; i++) {
            NSNumber *tickMark = [NSNumber numberWithFloat:((float)i * ygridLineSpacing) + [yMin doubleValue]];
            [defaultyTickMarks addObject:tickMark];
        }
        currentYTickMarks = [NSArray arrayWithArray:defaultyTickMarks];
    } else {
        currentYTickMarks = self.yTickMarks;
    }
    
    //Sort the tick marks.
    NSComparisonResult (^sortBlock)(id,id) = ^NSComparisonResult(id obj1,id obj2) {
        if ([obj1 doubleValue] > [obj2 doubleValue]) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        
        if ([obj1 doubleValue] < [obj2 doubleValue]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        
        return (NSComparisonResult)NSOrderedSame;
    };
    
    currentXTickMarks = [currentXTickMarks sortedArrayUsingComparator:sortBlock];
    currentYTickMarks = [currentYTickMarks sortedArrayUsingComparator:sortBlock];
    
    NSNumber *minXAxis = [currentXTickMarks objectAtIndex:0];
    NSNumber *maxXAxis = [currentXTickMarks lastObject];
    NSNumber *minYAxis = [currentYTickMarks objectAtIndex:0];
    NSNumber *maxYAxis = [currentYTickMarks lastObject];
    
    //Now that we know the info about the axes and tick marks, we can determine the size of everything, based on label widths and heights!
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    CGFloat labelHeight = 0;
    //if (self.xTickLabels == nil) {
        labelHeight = [[NSString stringWithString:@"1234"] sizeWithFont:font].height;
    //} else {
    //    labelHeight = [[self.xTickLabels lastObject] sizeWithFont:font].height;
    //}
    
    CGFloat xAxisLabelPadding = 5.0; //Padding on both sides of the label
    CGFloat xAxisHeight = labelHeight + xAxisLabelPadding*2;
    
    CGFloat labelWidth = 0;
    if (self.yTickLabels == nil) {
        labelWidth = [[numberFormatter stringFromNumber:minYAxis] sizeWithFont:font].width;
    } else {
        labelWidth = [[self.yTickLabels objectAtIndex:0] sizeWithFont:font].width;
    }
    
    CGFloat yAxisLabelPadding = 5.0;
    CGFloat yAxisWidth = labelWidth + yAxisLabelPadding*2;
    
    CGFloat plotRightSidePadding = 20; //Padding on the right of the graph, its nice to add some so the x labels dont get chopped off early.
    
    //TitleRect will be where a title goes in the future, but for now its just an empty box at the top.
    UIFont *titleFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    CGSize titleSize = [self.title sizeWithFont:titleFont];
    CGRect titleRect = CGRectMake(yAxisWidth, 0, self.bounds.size.width - yAxisWidth - plotRightSidePadding, titleSize.height);
    [[UIColor whiteColor] set];
    [self.title drawInRect:titleRect withFont:titleFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentCenter];
    
    
    CGRect plotRect = CGRectMake(yAxisWidth, titleRect.size.height, self.bounds.size.width - yAxisWidth - plotRightSidePadding, self.bounds.size.height - (titleRect.size.height + xAxisHeight));
    
    //CGRect yAxisRect = CGRectMake(0, titleRect.size.height, yAxisWidth, plotRect.size.height);
    
    //CGRect xAxisRect = CGRectMake(yAxisWidth, titleRect.size.height + plotRect.size.height, plotRect.size.width, xAxisHeight);
    
    //Draw the grid lines.
    UIColor *gridLineColor = [UIColor colorWithRed:74.0/255.0 green:86.0/255.0 blue:126.0/255.0 alpha:1.0];
    [gridLineColor setStroke];
    UIBezierPath *gridlinePath = [UIBezierPath bezierPath];
    [gridlinePath setLineWidth:1];
    CGFloat plotYCoordToContextConversion = (plotRect.size.height / ([maxYAxis doubleValue] - [minYAxis doubleValue]));
    for (NSNumber *yTickMark in currentYTickMarks) {
        CGFloat tickMarkContextYPosition = CGRectGetMaxY(plotRect) - (([yTickMark doubleValue] - [minYAxis doubleValue])* plotYCoordToContextConversion);
        [gridlinePath moveToPoint:CGPointMake(CGRectGetMinX(plotRect), tickMarkContextYPosition)];
        [gridlinePath addLineToPoint:CGPointMake(CGRectGetMaxX(plotRect), tickMarkContextYPosition)];
    }
    
    CGFloat plotXCoordToContextConversion = (plotRect.size.width / ([maxXAxis doubleValue] - [minXAxis doubleValue]));
    for (NSNumber *xTickMark in currentXTickMarks) {
        CGFloat xTickMarkPos = [xTickMark doubleValue] - [minXAxis doubleValue];
        CGFloat tickMarkContextXPosition = xTickMarkPos * plotXCoordToContextConversion + CGRectGetMinX(plotRect);
        [gridlinePath moveToPoint:CGPointMake(tickMarkContextXPosition, CGRectGetMinY(plotRect))];
        [gridlinePath addLineToPoint:CGPointMake(tickMarkContextXPosition, CGRectGetMaxY(plotRect))];
    }
    [gridlinePath stroke];
    
    //Draw the axes labels.
    [[UIColor whiteColor] set];
    if (self.yTickLabels == nil) {
        //If the labels aren't predefined, create them based on the tick marks.
        for (NSNumber *yTickMark in currentYTickMarks) {
            NSString *label = [numberFormatter stringFromNumber:yTickMark];
            CGSize labelSize = [label sizeWithFont:font];
            CGFloat labelContextYPosition = CGRectGetMaxY(plotRect) - (([yTickMark doubleValue] - [minYAxis doubleValue])* plotYCoordToContextConversion + labelSize.height/2.0);
            CGRect labelRect = CGRectMake(yAxisLabelPadding, floor(labelContextYPosition), labelSize.width, labelSize.height);
            [label drawInRect:labelRect withFont:font];
        }
    } else {
        NSUInteger tickCount = [currentYTickMarks count];
        for (int i=0; i<tickCount; i++) {
            NSString *label = [self.yTickLabels objectAtIndex:i];
            NSNumber *yTickMark = [currentYTickMarks objectAtIndex:i];
            CGSize labelSize = [label sizeWithFont:font];
            CGFloat labelContextYPosition = CGRectGetMaxY(plotRect) - (([yTickMark doubleValue] - [minYAxis doubleValue])* plotYCoordToContextConversion + CGRectGetMinY(plotRect) - labelSize.height/2.0);
            CGRect labelRect = CGRectMake(yAxisLabelPadding, floor(labelContextYPosition), labelSize.width, labelSize.height);
            [label drawInRect:labelRect withFont:font];
        }
    }
    
    if (self.xTickLabels == nil) {
        for (NSNumber *xTickMark in currentXTickMarks) {
            NSString *label = [numberFormatter stringFromNumber:xTickMark];
            CGSize labelSize = [label sizeWithFont:font];
            CGFloat labelContextXPosition = ([xTickMark doubleValue] - [minXAxis doubleValue]) * plotXCoordToContextConversion + CGRectGetMinX(plotRect) - labelSize.width/2.0;
            CGRect labelRect = CGRectMake(floor(labelContextXPosition), CGRectGetMaxY(plotRect)+xAxisLabelPadding, labelSize.width, labelSize.height);
            [label drawInRect:labelRect withFont:font];
        }
    } else {
        NSUInteger tickCount = [currentXTickMarks count];
        for (int i=0; i<tickCount; i++) {
            NSString *label = [self.xTickLabels objectAtIndex:i];
            NSNumber *xTickMark = [currentXTickMarks objectAtIndex:i];
            CGSize labelSize = [label sizeWithFont:font];
            CGFloat labelContextXPosition = ([xTickMark doubleValue] - [minXAxis doubleValue]) * plotXCoordToContextConversion + CGRectGetMinX(plotRect) - labelSize.width/2.0;
            CGRect labelRect = CGRectMake(floor(labelContextXPosition), CGRectGetMaxY(plotRect)+xAxisLabelPadding, labelSize.width, labelSize.height);
            [label drawInRect:labelRect withFont:font];
        }
    }
    
    //Draw the plot.
    
    CGContextRef con = UIGraphicsGetCurrentContext();
    CGContextSaveGState(con);
    //Start by making sure the data is clipped to fit inside the plotrect.
    UIBezierPath *plotRectPath = [UIBezierPath bezierPathWithRect:plotRect];
    [plotRectPath addClip];
    
    NSArray *xData = [self.dataSource xAxisDataForLinePlot:self];
    NSArray *yData = [self.dataSource yAxisDataForLinePlot:self];
    NSLog(@"Number of data points: %d",[xData count]);
    [[UIColor colorWithRed:0.7 green:0.9 blue:1.0 alpha:0.8] setStroke];
    UIBezierPath *plotPath = [UIBezierPath bezierPath];
    CGFloat lineWidth = 1.0;
    [plotPath setLineWidth:lineWidth];
    [plotPath setLineJoinStyle:kCGLineJoinRound];
    [plotPath setLineCapStyle:kCGLineCapRound];
    //CGFloat horizontalScale = plotRect.size.width / (maxXValue - minXValue);
    //CGFloat verticalScale = plotRect.size.height / (maxYValue - minYValue);
    CGPoint dataStartPoint = CGPointMake(CGRectGetMinX(plotRect) + ([[xData objectAtIndex:0] doubleValue] - [minXAxis doubleValue]) * plotXCoordToContextConversion, CGRectGetMaxY(plotRect) - (([[yData objectAtIndex:0] doubleValue] - [minYAxis doubleValue]) * plotYCoordToContextConversion));
    [plotPath moveToPoint:dataStartPoint];
    NSUInteger dataCount = [yData count];
    NSUInteger dataIncrement = 1;
    //If there is a lot more data than one datapoint per pixel, don't draw them all, skip some.
    CGFloat largestDimension  = MAX(plotRect.size.width,plotRect.size.height);
    if (dataCount > 2 * largestDimension) {
        dataIncrement = floor(2 * dataCount / largestDimension);
    }
    
    CGFloat maxGradientY = CGRectGetMaxY(plotRect); //We will put the largest datapoint in here so we know where to start a gradient later.
    CGFloat minXfloat = [minXAxis doubleValue];
    CGFloat minYfloat = [minYAxis doubleValue];
    for (NSUInteger i = 1; i < dataCount; i = i + dataIncrement) {
        CGFloat yValue = [[yData objectAtIndex:i] doubleValue];
        CGFloat xValue = [[xData objectAtIndex:i] doubleValue];
        CGPoint dataPoint = CGPointMake(CGRectGetMinX(plotRect) + (xValue - minXfloat) * plotXCoordToContextConversion, CGRectGetMaxY(plotRect) - ((yValue - minYfloat) * plotYCoordToContextConversion));
        if (dataPoint.y < maxGradientY) {
            maxGradientY = dataPoint.y;
        }
        [plotPath addLineToPoint:dataPoint];
    }
    [plotPath stroke];
    //Remove the plotRect clipping mask
    CGContextRestoreGState(con);
    
    //Draw a gradient to make the plot fancy.
    UIBezierPath *fillPath = [UIBezierPath bezierPath];
    [fillPath appendPath:plotPath];
    CGPoint currentPoint = [fillPath currentPoint];
    [fillPath addLineToPoint:CGPointMake(CGRectGetMaxX(plotRect), currentPoint.y)];
    [fillPath addLineToPoint:CGPointMake(CGRectGetMaxX(plotRect), CGRectGetMaxY(plotRect))];
    [fillPath addLineToPoint:CGPointMake(CGRectGetMinX(plotRect), CGRectGetMaxY(plotRect))];
    [fillPath addLineToPoint:CGPointMake(CGRectGetMinX(plotRect), dataStartPoint.y)];
    [fillPath addLineToPoint:CGPointMake(dataStartPoint.x, dataStartPoint.y)];
    [fillPath closePath];
    
    CGContextSaveGState(con);
    [fillPath addClip];
    
    //CGFloat maxGradientY = CGRectGetMaxY(plotRect) - ([[self.dataSource maxYValueForLinePlot:self] doubleValue] - [minYAxis doubleValue])*plotYCoordToContextConversion;
    if (maxGradientY < CGRectGetMinY(plotRect)) {
        maxGradientY = CGRectGetMinY(plotRect);
    }
    CGPoint gradStartPoint = CGPointMake(CGRectGetMinX(plotRect), maxGradientY);
    CGPoint gradEndPoint = CGPointMake(CGRectGetMinX(plotRect), CGRectGetMaxY(plotRect));
    CGContextDrawLinearGradient(con, [self fillGradient], gradStartPoint, gradEndPoint, 0);
    CGContextRestoreGState(con);
    
    //Draw the axes themselves.
    [gridLineColor setStroke];
    UIBezierPath *axesPath = [UIBezierPath bezierPath];
    [axesPath setLineWidth:4.0];
    [axesPath moveToPoint:CGPointMake(CGRectGetMinX(plotRect),CGRectGetMinY(plotRect)-0.5)];
    [axesPath addLineToPoint:CGPointMake(CGRectGetMinX(plotRect),CGRectGetMaxY(plotRect))];
    [axesPath addLineToPoint:CGPointMake(CGRectGetMaxX(plotRect)+0.5, CGRectGetMaxY(plotRect))];
    [axesPath stroke];
    
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [self drawBackgroundWithColor:[UIColor blackColor]];
    [self drawPlot];

}


@end
