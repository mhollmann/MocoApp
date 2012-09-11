//
//  MocoApplicationAppDelegate.h
//  MocoApplication
//
//  Created by Maurice Hollmann on 5/2/12.
//  Copyright (c) 2012 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <stdio.h>
#include <time.h>
#include <math.h>

#import "MocoDrawViewController.h"
#import "MocoRegistrationProperty.h"


@interface MocoApplicationAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
    
    MocoDrawViewController* mMocoDrawViewController;
    MocoRegistrationProperty* mRegistrationProperty;
    bool mMocoIsRunning;
    
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView *mAppGraphView;

@property (assign) IBOutlet NSPopUpButton *mNumIterationsPullDown;
@property (assign) IBOutlet NSPopUpButton *mSmoothKernelPullDown;
@property (assign) IBOutlet NSPopUpButton *mMaskImagesPullDown;


- (IBAction)setNumIterationsByPullDown:(NSPopUpButton *)sender;
- (IBAction)setSmoothKernelByPullDown:(NSPopUpButton *)sender;
- (IBAction)setMaskImagesByPullDown:(NSPopUpButton *)sender;

- (IBAction)startStopButtonPressed:(NSButton *)sender;

- (IBAction)startRegistrationMI:(NSMenuItem *)sender;

-(double)getTimeDifference:(timeval) startTime endTime:(timeval) endTime;


@end
