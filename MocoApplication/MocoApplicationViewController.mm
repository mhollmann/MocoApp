//
//  MocoApplicationViewController.m
//  MocoApplication
//
//  Created by Maurice Hollmann on 8/29/12.
//
//
#import "MocoApplicationViewController.h"



@interface MocoApplicationViewController ()

@end

@implementation MocoApplicationViewController
@synthesize contentView;



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Initialization code here.
        NSLog(@"MocoApplicationViewController initialized ....");
    }
    
    return self;
}



- (id)initWithNibNameAndWindow:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil window:(NSWindow *) window
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Initialization code here.
        NSLog(@"MocoApplicationViewController initialized with window....");
    }
    
    return self;
}



@end
