//
//  MocoApplicationViewController.h
//  MocoApplication
//
//  Created by Maurice Hollmann on 8/29/12.
//
//

#import <Cocoa/Cocoa.h>
#import <stdio.h>
#include <time.h>
#include <math.h>

#import "MocoDrawViewController.h"




@interface MocoApplicationViewController : NSViewController{

@private
    MocoDrawViewController* mMocoDrawViewController;
    NSView* contentView;

}
//@property (assign) IBOutlet NSView *mMocoApplicationView;
//@property (assign) IBOutlet NSView *mWindowContentView;
@property (assign) IBOutlet NSView *contentView;


-(id)initWithNibNameAndWindow:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil window:(NSWindow *)window;

//- (IBAction)startRegistrationMI:(NSMenuItem *)sender;

//-(double)getTimeDifference:(timeval) startTime endTime:(timeval) endTime;



@end
