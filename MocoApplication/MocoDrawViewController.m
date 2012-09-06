//
//  MocoDraw_viewController.m
//  MocoApplication
//
//  Created by willi on 5/6/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "MocoDrawViewController.h"

@implementation MocoDrawViewController

@synthesize mMocoDrawTranslationView;
@synthesize mMocoDrawRotationView;
@synthesize transGraph;
@synthesize rotGraph;

@synthesize scanCounter;
@synthesize plotSpaceXLength;

@synthesize transArrayX;
@synthesize transArrayY;
@synthesize transArrayZ;
@synthesize rotArrayX;
@synthesize rotArrayY;
@synthesize rotArrayZ;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
     
    if (self) {   
        
        //initialize scan counter
        self.scanCounter = 0;
        self.plotSpaceXLength = 52.0;       
        
        //initialize the arrays for transform parameters
        self.transArrayX = [NSMutableArray arrayWithCapacity:MOCO_MAX_NUMBER_SCANS];
        self.transArrayY = [NSMutableArray arrayWithCapacity:MOCO_MAX_NUMBER_SCANS];
        self.transArrayZ = [NSMutableArray arrayWithCapacity:MOCO_MAX_NUMBER_SCANS];
        self.rotArrayX = [NSMutableArray arrayWithCapacity:MOCO_MAX_NUMBER_SCANS];
        self.rotArrayY = [NSMutableArray arrayWithCapacity:MOCO_MAX_NUMBER_SCANS];
        self.rotArrayZ = [NSMutableArray arrayWithCapacity:MOCO_MAX_NUMBER_SCANS];
        
     }
    
    return self;
}

-(void)awakeFromNib
{
	[super awakeFromNib];    
    
    
    //*************************************************
    //****** Initialize Translation Graph Stuff *******
    //*************************************************    
    //*** Create the graph holding translations *** 
	self.transGraph = [ (CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:NSRectToCGRect([mMocoDrawTranslationView bounds]) ];
    mMocoDrawTranslationView.hostedGraph = transGraph;
    
    // Graph title
	self.transGraph.title = @"Moco Translation Parameters";
	CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
	textStyle.color				   = [CPTColor blackColor];
	textStyle.fontName			   = @"Helvetica-Bold";
	textStyle.fontSize			   = 14.0;
	textStyle.textAlignment		   = CPTTextAlignmentCenter;
	transGraph.titleTextStyle		   = textStyle;
	transGraph.titleDisplacement		   = CGPointMake(0.0, 6.0);
	transGraph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    
	// Graph padding
	transGraph.paddingLeft	= 18.0;
	transGraph.paddingTop	= 18.0;
	transGraph.paddingRight	= 10.0;
	transGraph.paddingBottom = 10.0;
    
    
    // Line styles
	CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
	axisLineStyle.lineWidth = 1.0;
	axisLineStyle.lineCap	= kCGLineCapRound;
        
	CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
	majorGridLineStyle.lineWidth = 0.8;
	majorGridLineStyle.lineColor = [CPTColor grayColor];
    
	CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
	minorGridLineStyle.lineWidth = 0.25;
	minorGridLineStyle.lineColor = [CPTColor blueColor];
    
    
    // Axes with automatic labeling policies
	// Label x axis with a fixed interval policy
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)transGraph.axisSet;
	CPTXYAxis *x		  = axisSet.xAxis;
	x.separateLayers			  = NO;
    CPTPlotRange *glxRange		  = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-5.0f) length:CPTDecimalFromFloat(5000.0f)];
    x.gridLinesRange              = glxRange;
    x.labelExclusionRanges        = [NSArray arrayWithObjects: [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-30.0f) length:CPTDecimalFromFloat(30.0f)], nil];
	x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(-4.0); //describes where the y axis is crossing
    x.majorTickLength			  = 3.0; //describes the length (in y direction) of the tick marks
	x.majorTickLineStyle		  = axisLineStyle;
	x.majorGridLineStyle		  = nil;//majorGridLineStyle;
	x.minorTicksPerInterval		  = 3;
	x.tickDirection				  = CPTSignNone;
	x.axisLineStyle				  = axisLineStyle;
	x.minorTickLength			  = 1.0;
	x.minorGridLineStyle		  = nil;//minorGridLineStyle;
    x.title						  = @"Scans";
	x.titleTextStyle			  = textStyle;
	x.titleOffset				  = 25.0;
	//x.alternatingBandFills		  = [NSArray arrayWithObjects:[[CPTColor redColor] colorWithAlphaComponent:0.1], //[[CPTColor greenColor] colorWithAlphaComponent:0.1], nil];
	x.labelingPolicy			  = CPTAxisLabelingPolicyAutomatic;
    
    
    
	// Label y with an automatic label policy.
	CPTXYAxis *y = axisSet.yAxis;
	y.separateLayers		= NO;
    CPTPlotRange *glyRange		  = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromFloat(5000.0f)];
    y.gridLinesRange              = glyRange;
    y.labelExclusionRanges        = [NSArray arrayWithObjects: [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-30.0f) length:CPTDecimalFromFloat(26.0f)], nil];
    
 	y.minorTicksPerInterval = 1;
	y.tickDirection			= CPTSignNone;
	y.axisLineStyle			= axisLineStyle;
	y.majorTickLength		= 3.0;
	y.majorTickLineStyle	= axisLineStyle;//majorGridLineStyle;
	y.majorGridLineStyle	= nil;//majorGridLineStyle;
	y.minorTickLength		= 1.0;
	y.minorGridLineStyle	= nil;//minorGridLineStyle;
	y.title					= @"Movement in mm";
	y.titleTextStyle		= textStyle;
	y.titleOffset			= 25.0;
	//y.alternatingBandFills	= [NSArray arrayWithObjects:[[CPTColor blueColor] colorWithAlphaComponent:0.1], [NSNull null], nil];
	y.labelingPolicy		= CPTAxisLabelingPolicyAutomatic;
    // Set axes
	transGraph.axisSet.axes = [NSArray arrayWithObjects:x, y, nil, nil];
    
    
        
    //********************
    //***** the plots ****
    //********************
    //the plot for movement in X direction
    CPTScatterPlot *movXPlot = [[[CPTScatterPlot alloc] initWithFrame:[mMocoDrawTranslationView bounds]] autorelease];
	movXPlot.identifier = @"movXPlot";
    CPTMutableLineStyle *lineStyle = [[movXPlot.dataLineStyle mutableCopy] autorelease]; 
    lineStyle.lineColor =  [CPTColor blueColor]; 
    movXPlot.dataLineStyle = lineStyle; 
	movXPlot.dataSource = self;
	[transGraph addPlot:movXPlot];
	

    //the plot for movement in Y direction
	CPTScatterPlot *movYPlot = [[[CPTScatterPlot alloc] initWithFrame:[mMocoDrawTranslationView bounds]] autorelease];
	movYPlot.identifier = @"movYPlot";
    lineStyle = [[movYPlot.dataLineStyle mutableCopy] autorelease]; 
    lineStyle.lineColor =  [CPTColor greenColor]; 
    movYPlot.dataLineStyle = lineStyle; 
	movYPlot.dataSource = self;
	[transGraph addPlot:movYPlot];

    
    //the plot for movement in Z direction
	CPTScatterPlot *movZPlot = [[[CPTScatterPlot alloc] initWithFrame:[mMocoDrawTranslationView bounds]] autorelease];
	movZPlot.identifier = @"movZPlot";
    lineStyle = [[movZPlot.dataLineStyle mutableCopy] autorelease]; 
    lineStyle.lineColor =  [CPTColor redColor]; 
    movZPlot.dataLineStyle = lineStyle; 
	movZPlot.dataSource = self;
	[transGraph addPlot:movZPlot];
        
    
    // Setup plot space    
	CPTXYPlotSpace *plotSpace = (id)transGraph.defaultPlotSpace;
	plotSpace.allowsUserInteraction = YES;
    
	CPTPlotRange *xRange		= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-3.0f) length:CPTDecimalFromFloat(self.plotSpaceXLength)];
 	plotSpace.xRange = xRange;
	CPTPlotRange *yRange		= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-5.0f) length:CPTDecimalFromFloat(8.8f)];	
    plotSpace.yRange = yRange;    
    
    
	// Restrict y range to a global range
	//CPTPlotRange *globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-2.0f) length:CPTDecimalFromFloat(4.0f)];
	//plotSpace.globalYRange = globalYRange;
    
    /*  USE IF NEEDED
      
    // Auto scale the plot space to fit the plot data
    //[plotSpace scaleToFitPlots:[NSArray arrayWithObjects:movXPlot, nil, nil]];
      
	// set the x and y shift to match the new ranges
	CGFloat length = xRange.lengthDouble;
	self.plotSpaceXShift = length - 3.0;
	length		= yRange.lengthDouble;
	self.plotSpaceYShift = length - 2.0;
     
     */

    
    
    
    
    
    
    //*************************************************
    //******* Initialize Rotation Graph Stuff *********
    //*************************************************

    //*** Create the graph holding translations *** 
	self.rotGraph = [ (CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:NSRectToCGRect([mMocoDrawRotationView bounds]) ];
    mMocoDrawRotationView.hostedGraph = rotGraph;
    
    // Graph title
	self.rotGraph.title = @"Moco Rotation Parameters";
	rotGraph.titleTextStyle		   = textStyle;
	rotGraph.titleDisplacement		   = CGPointMake(0.0, 6.0);
	rotGraph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    
	// Graph padding
	rotGraph.paddingLeft	= 18.0;
	rotGraph.paddingTop	    = 18.0;
	rotGraph.paddingRight	= 10.0;
	rotGraph.paddingBottom  = 10.0;
    
        
    // Axes with automatic labeling policies
	// Label x axis with a fixed interval policy
	CPTXYAxisSet *raxisSet = (CPTXYAxisSet *)rotGraph.axisSet;
	CPTXYAxis *rx		  = raxisSet.xAxis;
	rx.separateLayers			  = NO;
    CPTPlotRange *rglxRange		  = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-5.0f) length:CPTDecimalFromFloat(5000.0f)];
    rx.gridLinesRange              = rglxRange;
    rx.labelExclusionRanges        = [NSArray arrayWithObjects: [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-30.0f) length:CPTDecimalFromFloat(30.0f)], nil];
	rx.orthogonalCoordinateDecimal = CPTDecimalFromDouble(-4.0); //describes where the y axis is crossing
                                                                
    rx.majorTickLength			  = 3.0; //describes the length (in y direction) of the tick marks
	rx.majorTickLineStyle		  = axisLineStyle;
	rx.majorGridLineStyle		  = nil;//majorGridLineStyle;
	rx.minorTicksPerInterval	  = 3;
	rx.tickDirection			  = CPTSignNone;
	rx.axisLineStyle			  = axisLineStyle;
	rx.minorTickLength			  = 1.0;
	rx.minorGridLineStyle		  = nil;//minorGridLineStyle;
    rx.title					  = @"Scans";
	rx.titleTextStyle			  = textStyle;
	rx.titleOffset				  = 25.0;
	rx.labelingPolicy			  = CPTAxisLabelingPolicyAutomatic;
    
    
    
	// Label y with an automatic label policy.
	CPTXYAxis *ry = raxisSet.yAxis;
	ry.separateLayers		= NO;
    CPTPlotRange *rglyRange		  = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromFloat(5000.0f)];
    ry.gridLinesRange              = rglyRange;
    ry.labelExclusionRanges        = [NSArray arrayWithObjects: [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-30.0f) length:CPTDecimalFromFloat(26.0f)], nil];
 	ry.minorTicksPerInterval = 1;
	ry.tickDirection			= CPTSignNone;
	ry.axisLineStyle			= axisLineStyle;
	ry.majorTickLength		= 3.0;
	ry.majorTickLineStyle	= axisLineStyle;//majorGridLineStyle;
	ry.majorGridLineStyle	= nil;//majorGridLineStyle;
	ry.minorTickLength		= 1.0;
	ry.minorGridLineStyle	= nil;//minorGridLineStyle;
	ry.title				= @"Rotation in degree";
	ry.titleTextStyle		= textStyle;
	ry.titleOffset			= 25.0;
	//y.alternatingBandFills	= [NSArray arrayWithObjects:[[CPTColor blueColor] colorWithAlphaComponent:0.1], [NSNull null], nil];
	ry.labelingPolicy		= CPTAxisLabelingPolicyAutomatic;
    // Set axes
	rotGraph.axisSet.axes = [NSArray arrayWithObjects:rx, ry, nil, nil];
    
    
    
    //********************
    //***** the plots ****
    //********************
    //the plot for rotation about X axis
    CPTScatterPlot *rotXPlot = [[[CPTScatterPlot alloc] initWithFrame:[mMocoDrawRotationView bounds]] autorelease];
	rotXPlot.identifier = @"rotXPlot";
    CPTMutableLineStyle *rlineStyle = [[rotXPlot.dataLineStyle mutableCopy] autorelease]; 
    rlineStyle.lineColor =  [CPTColor blueColor]; 
    rotXPlot.dataLineStyle = rlineStyle; 
	rotXPlot.dataSource = self;
	[rotGraph addPlot:rotXPlot];
	
    
    //the plot for rotation about Y axis
	CPTScatterPlot *rotYPlot = [[[CPTScatterPlot alloc] initWithFrame:[mMocoDrawRotationView bounds]] autorelease];
	rotYPlot.identifier = @"rotYPlot";
    rlineStyle = [[rotYPlot.dataLineStyle mutableCopy] autorelease]; 
    rlineStyle.lineColor =  [CPTColor greenColor]; 
    rotYPlot.dataLineStyle = rlineStyle; 
	rotYPlot.dataSource = self;
	[rotGraph addPlot:rotYPlot];
    
    
    //the plot for rotation about Z axis
	CPTScatterPlot *rotZPlot = [[[CPTScatterPlot alloc] initWithFrame:[mMocoDrawRotationView bounds]] autorelease];
	rotZPlot.identifier = @"rotZPlot";
    rlineStyle = [[rotZPlot.dataLineStyle mutableCopy] autorelease]; 
    rlineStyle.lineColor =  [CPTColor redColor]; 
    rotZPlot.dataLineStyle = rlineStyle; 
	rotZPlot.dataSource = self;
	[rotGraph addPlot:rotZPlot];
    
    
    // Setup plot space    
	CPTXYPlotSpace *rplotSpace = (id)rotGraph.defaultPlotSpace;
	plotSpace.allowsUserInteraction = YES;

    //use the xRange of the standard defined plot space also for the rotation graph 
 	rplotSpace.xRange = xRange;
	CPTPlotRange *ryRange		= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-5.0f) length:CPTDecimalFromFloat(8.8f)];	
    rplotSpace.yRange = ryRange;
    
    
}


//implemented for protocol 
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot 
{
	return self.scanCounter;
}


//implemented for protocol 
-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum  
			   recordIndex:(NSUInteger)index
{
    
    //NSLog(@"Plot Identifier: %@", plot.identifier);
    
    //return the index for the X component of the data point
	if(fieldEnum == CPTScatterPlotFieldX)
	{ 
        return [NSNumber numberWithDouble:index]; 
    }
	else
	{ 
        //return the value for the Y component of the data point
		if(plot.identifier == @"movXPlot")
		{ 
            return [self->transArrayX objectAtIndex:index];            
        }
		else if(plot.identifier == @"movYPlot")
        {    
            return [self->transArrayY objectAtIndex:index];
        }    
        else if(plot.identifier == @"movZPlot")
        {
            return [self->transArrayZ objectAtIndex:index];
        }    
        
        //return the value for the Y component of the data point
		if(plot.identifier == @"rotXPlot")
		{ 
            return [self->rotArrayX objectAtIndex:index];            
        }
		else if(plot.identifier == @"rotYPlot")
        {    
            return [self->rotArrayY objectAtIndex:index];
        }    
        else if(plot.identifier == @"rotZPlot")
        {
            return [self->rotArrayZ objectAtIndex:index];
        }    

	}
    
    return nil;
}


- (void)addValuesToGraphs:(double)translationX TransY:(double)translationY TransZ:(double)translationZ RotX:(double)rotationX RotY:(double)rotationY RotZ:(double)rotationZ
{
    
    [self.transArrayX addObject:[NSNumber numberWithDouble:translationX]];
    [self.transArrayY addObject:[NSNumber numberWithDouble:translationY]];
    [self.transArrayZ addObject:[NSNumber numberWithDouble:translationZ]];
    [self.rotArrayX addObject:[NSNumber numberWithDouble:rotationX]];
    [self.rotArrayY addObject:[NSNumber numberWithDouble:rotationY]];
    [self.rotArrayZ addObject:[NSNumber numberWithDouble:rotationZ]];
    
    self.scanCounter++; 
     
}


-(void)updateGraphs
{
    [self.transGraph reloadData];
    [self.rotGraph reloadData];
    
    
    //set new plot ranges if needed
    if(self.scanCounter >= self.plotSpaceXLength-(self.plotSpaceXLength*0.05))
    {
        
        self.plotSpaceXLength = self.plotSpaceXLength + 20;
        
        CPTXYPlotSpace *plotSpace		  = (CPTXYPlotSpace *)transGraph.defaultPlotSpace;
        CPTPlotRange *newRange		= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(self.plotSpaceXLength*-0.06) length:CPTDecimalFromFloat(self.plotSpaceXLength)];	
        plotSpace.xRange = newRange;
        
        
        CPTXYPlotSpace *rplotSpace		  = (CPTXYPlotSpace *)rotGraph.defaultPlotSpace;
        rplotSpace.xRange = newRange;
        
    }

}



- (void)dealloc
{
    [transGraph release];
    [rotGraph release];
    
    [transArrayX release];
    [transArrayY release];
    [transArrayZ release];
    [rotArrayX release];
    [rotArrayY release];
    [rotArrayZ release];
    
    
    [super dealloc];
}

@end
