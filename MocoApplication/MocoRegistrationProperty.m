//
//  RegistrationProperty.m
//  MotionCorrection
//
//  Created by Karsten Molka on 24.03.11.
//  Changes Maurice Hollmann 03/12.
//  Copyright 2011 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import "MocoRegistrationProperty.h"


@implementation MocoRegistrationProperty

@synthesize ParameterOutputFileOffset;

@synthesize RegistrationParameters;
@synthesize FinalMovementParameters;

@synthesize RegistrationInterpolationMode;
@synthesize ResamplingInterpolationMode;
@synthesize Smoothing;                
@synthesize SmoothingSigma;          
@synthesize SmoothingKernelWidth;     
@synthesize NumberOfThreads;          
@synthesize UseBestFoundParameters;   
@synthesize Threshold;                

@synthesize logging;               

- (id) init {
 
    if ( (self = [super init]) ) {
        RegistrationParameters  = (double *) malloc( 4 * sizeof(double) ); 
        FinalMovementParameters = (double *) malloc( 6 * sizeof(double) );
        
        RegistrationInterpolationMode = LINEAR;
        ResamplingInterpolationMode   = LINEAR;

        NumberOfThreads         = 1;
        Smoothing               = YES;
        SmoothingSigma          = 1;
        SmoothingKernelWidth    = 8;
        UseBestFoundParameters  = NO;
        Threshold               = 0;
        logging                 = NO;
    }
                                         
    
    return self;
}

- (void) setRegistrationParameters:(double)translationScale 
               MaxStep:(double)maxSteplength 
               MinStep:(double)minSteplength
               NumIterations:(int)numIterations {
               
	RegistrationParameters[0] = translationScale;
	RegistrationParameters[1] = maxSteplength;
	RegistrationParameters[2] = minSteplength;
	RegistrationParameters[3] = numIterations;
    
}

- (void) dealloc {
    
    free(RegistrationParameters);
    free(FinalMovementParameters);    
    
    [super dealloc];
}

@end
