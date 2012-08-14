//
//  MocoApplicationAppDelegate.h
//  MocoApplication
//
//  Created by willi on 5/2/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <stdio.h>
#include <time.h>
#include <math.h>


#import "MocoRegistration.h"
#import "MocoDrawViewController.h"

@interface MocoApplicationAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
    MocoDrawViewController* mMocoDrawViewController;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)startRegistrationMI:(id)sender;

-(double)getTimeDifference:(timeval) startTime endTime:(timeval) endTime;

@end
