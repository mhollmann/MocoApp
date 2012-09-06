//
//  MocoDraw_viewController.h
//  MocoApplication
//
//  Created by Maurice Hollmann on 04/24/12.
//  Copyright (c) 2012 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MocoDrawTranslationView.h"
#import "MocoDrawRotationView.h"

#ifndef MOCO_MAX_NUMBER_SCANS
#define MOCO_MAX_NUMBER_SCANS 5000
#endif

@interface MocoDrawViewController : NSViewController <CPTPlotDataSource> {
    
    //the graph holding the plots
    CPTXYGraph *graph;
    CPTXYGraph *rotGraph;
    
    
    //a counter showing the actual number of plotted scans
    uint16 scanCounter;
    
    //holds the length of the shown plot space
    double plotSpaceXLength;
        
    //used to store values that should be plotted
    NSMutableArray *transArrayX;
    NSMutableArray *transArrayY;
    NSMutableArray *transArrayZ;
    NSMutableArray *rotArrayX;
    NSMutableArray *rotArrayY;
    NSMutableArray *rotArrayZ;

    MocoDrawTranslationView *mMocoDrawTranslationView;
    MocoDrawRotationView *mMocoDrawRotationView;
}

//the views holding the graph plots
@property (assign) IBOutlet MocoDrawTranslationView *mMocoDrawTranslationView;
@property (assign) IBOutlet MocoDrawRotationView *mMocoDrawRotationView;



@property (retain) CPTXYGraph *transGraph;
@property (retain) CPTXYGraph *rotGraph;

@property uint16 scanCounter;
@property double plotSpaceXLength;

@property (retain) NSMutableArray *transArrayX;
@property (retain) NSMutableArray *transArrayY;
@property (retain) NSMutableArray *transArrayZ;
@property (retain) NSMutableArray *rotArrayX;
@property (retain) NSMutableArray *rotArrayY;
@property (retain) NSMutableArray *rotArrayZ;



/**
 * Add values to the graphs controlled by this class. 
 *
 * \param translationX  A value representing translation in X direction in millimeter
 * \param translationY  A value representing translation in Y direction in millimeter
 * \param translationZ  A value representing translation in Y direction in millimeter
 * \param rotationX     A value representing rotation about X-axis (pitch) in degrees
 * \param rotationY     A value representing rotation about Y-axis (roll) in degrees
 * \param rotationZ     A value representing rotation about Z-axis (yaw) in degrees
 *
 */
- (void) addValuesToGraphs:(double)translationX
                        TransY:(double)translationY 
                        TransZ:(double)translationZ
                        RotX:(double)rotationX
                        RotY:(double)rotationY
                    RotZ:(double)rotationZ;
                     

/**
 * Update the graphs controlled by this class. This one must be called each time after values are added that should be shown.
 * Calling should be done in the MAIN LOOP of an application, because this refreshs also the connected views.
 *
 */
- (void) updateGraphs;

@end
