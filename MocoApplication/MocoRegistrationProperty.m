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

@synthesize RegistrationParameters;
@synthesize RegistrationInterpolationMode;
@synthesize ResamplingInterpolationMode;
@synthesize NumberOfIterations;
@synthesize Smoothing;                
@synthesize SmoothingSigma;          
@synthesize SmoothingKernelWidth;     
@synthesize NumberOfThreads;
@synthesize MaskImagesForRegistration;
@synthesize UseBestFoundParameters;   
@synthesize LoggingLevel;
              

- (id) init {
 
    if ( (self = [super init]) ) {
        RegistrationParameters  = (double *) malloc( 3 * sizeof(double) );
        RegistrationParameters[0] = 1000;
        RegistrationParameters[1] = 0.019;
        RegistrationParameters[2] = 0.00001;
                
        RegistrationInterpolationMode = LINEAR;
        ResamplingInterpolationMode   = BSPLINE4;
        NumberOfIterations            = 6;
        
        NumberOfThreads           = 1;
        Smoothing                 = YES;
        SmoothingSigma            = 5;
        SmoothingKernelWidth      = 32;
        MaskImagesForRegistration = YES;
        
        UseBestFoundParameters  = NO;
        LoggingLevel            = 0;
    }
                                         
    
    return self;
}

- (void) setRegistrationParameters:(double)translationScale 
               MaxStep:(double)maxSteplength 
               MinStep:(double)minSteplength {
               
	RegistrationParameters[0] = translationScale;
	RegistrationParameters[1] = maxSteplength;
	RegistrationParameters[2] = minSteplength;
    
}

- (double *) getRegistrationParameters {
    
	return RegistrationParameters;
    
}

- (void) dealloc {
    
    free(RegistrationParameters);
    
    [super dealloc];
}

@end
