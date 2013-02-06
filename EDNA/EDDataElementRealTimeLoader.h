/*
 *  EDDataElementRealTimeLoader.h
 *  BARTApplication
 *
 *  Created by Lydia Hellrung on 3/25/11.
 *  Copyright 2011 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
 *
 */


#import "Cocoa/Cocoa.h"

#import "EDDataElementIsisRealTime.h"
#import "EDDataElementIsis.h"

@interface EDDataElementRealTimeLoader : NSObject  
{
	EDDataElementIsisRealTime *mDataElementInterest;
	EDDataElementIsisRealTime *mDataElementRest;
	
    NSMutableArray *arrayLoadedDataElements;
	
}

-(void)startRealTimeInputOfImageType;

@end