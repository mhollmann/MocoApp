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
#import "MocoRegistration.h"

#import "EDDataElementIsis.h"
#import "EDDataElementRealTimeLoader.h"

#import "MocoDataLogger.h"

@interface MocoApplicationAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
    
    MocoDrawViewController* mMocoDrawViewController;
    MocoRegistrationProperty* mRegistrationProperty;
    MocoRegistration* mRegistrator;
    MocoDataLogger* mMocoDataLogger;
    
    EDDataElementRealTimeLoader* mRTDataLoader;
    NSThread *mRealTimeTCPIPReadingThread;
    
    NSString *mMocoResultImagesNameBase;
    NSString *mMocoParametersOutNameBase;
     
    bool mMocoIsRunning;
    bool mRealTimeTCPIPMode;
    
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView *mAppGraphView;

@property (assign) IBOutlet NSPopUpButton *mNumIterationsPullDown;
@property (assign) IBOutlet NSPopUpButton *mSmoothKernelPullDown;
@property (assign) IBOutlet NSPopUpButton *mMaskImagesPullDown;
@property (assign) IBOutlet NSPopUpButton *mReferenceImagePullDown;
@property (assign) IBOutlet NSPopUpButton *mInputSourcePullDown;
@property (assign) IBOutlet NSButton *mStartButton;


- (IBAction)setNumIterationsByPullDown:(NSPopUpButton *)sender;
- (IBAction)setSmoothKernelByPullDown:(NSPopUpButton *)sender;
- (IBAction)setMaskImagesByPullDown:(NSPopUpButton *)sender;
- (IBAction)setReferenceImageByPulldown:(NSPopUpButton *)sender;
- (IBAction)setInputSourceByPullDown:(id)sender;

- (IBAction)startStopButtonPressed:(NSButton *)sender;




@end
