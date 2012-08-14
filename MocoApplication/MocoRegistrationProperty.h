//
//  MocoRegistrationProperty.h
//  MotionCorrection
//
//  Created by Karsten Molka on 24.03.11., 
//  Changes Maurice Hollmann 03/12.
//  Copyright 2012 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "itkRegistration.h"

#define BSPLINE2 1
#define BSPLINE3 2
#define BSPLINE4 3
#define BSPLINE5 4
#define SINC2 5
#define SINC3 6
#define SINC4 7
#define SINC5 8
#define SINC6 9
#define LINEAR 10
#define NN 11 


#define METRIC_FAILURE 100
#define IMAGEREAD_FAILURE 101
#define EVOL_SUCCESS 0

@interface MocoRegistrationProperty : NSObject {

@private 
    
    NSString *ParameterOutputFileOffset;
    
    double *RegistrationParameters; 
    double *FinalMovementParameters;
    
    /* interpolation type used for registration*/
    int RegistrationInterpolationMode;
    
    /* interpolation type used for resampling*/
    int ResamplingInterpolationMode;
    
    /* do smoothing for registration */
    bool Smoothing;
    
    /* gaussian variance */
    int SmoothingSigma;
    
    /* kernel size in mm (e.g. 8 for 3mm voxel size) */
    int SmoothingKernelWidth;
    
    /* number of threads used for all processing */
    int NumberOfThreads;
    
    bool UseBestFoundParameters;
    
    short Threshold;
    
    /*do logging; YES / NO; default=NO */
    bool logging;

}


@property(copy) NSString *ParameterOutputFileOffset;


@property(readonly) double *RegistrationParameters;
@property(readonly) double *FinalMovementParameters;

@property int   RegistrationInterpolationMode;
@property int   ResamplingInterpolationMode;
@property bool  Smoothing;
@property int   SmoothingSigma;
@property int   SmoothingKernelWidth;
@property int   NumberOfThreads;
@property bool  UseBestFoundParameters;
@property short Threshold;
@property bool  logging;

- (id) init;
- (void) setRegistrationParameters:(double)translationScale 
               MaxStep:(double)maxSteplength 
               MinStep:(double)minSteplength
               NumIterations:(int)numIterations;
//- (NSString *)description;                       
- (void) dealloc; 

@end
