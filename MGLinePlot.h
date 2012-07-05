//
//  MGLinePlot.h
//  LCLS
//
//  Created by Matthew Gibbs on 10/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
@class MGLinePlot;

@protocol MGLinePlotDataSource <NSObject>

-(NSInteger)numberOfDataPointsForLinePlot:(MGLinePlot *)linePlot;
-(NSArray *)xAxisDataForLinePlot:(MGLinePlot *)linePlot;
-(NSArray *)yAxisDataForLinePlot:(MGLinePlot *)linePlot;
-(NSDecimalNumber *)minXValueForLinePlot:(MGLinePlot *)linePlot;
-(NSDecimalNumber *)maxXValueForLinePlot:(MGLinePlot *)linePlot;
-(NSDecimalNumber *)minYValueForLinePlot:(MGLinePlot *)linePlot;
-(NSDecimalNumber *)maxYValueForLinePlot:(MGLinePlot *)linePlot;


@end

@interface MGLinePlot : UIView {
    NSArray *currentYTickMarks;
    NSArray *currentXTickMarks;
    NSNumberFormatter *numberFormatter;
    CGGradientRef fillGradient;
}

@property (nonatomic, assign) id <MGLinePlotDataSource> dataSource;

@property (nonatomic, strong) NSArray *xTickMarks;
@property (nonatomic, strong) NSArray *yTickMarks;
@property (nonatomic, strong) NSArray *xTickLabels;
@property (nonatomic, strong) NSArray *yTickLabels;
@property (nonatomic, strong) NSString *title;

@end
