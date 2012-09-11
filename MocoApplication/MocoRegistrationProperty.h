//
//  MocoRegistrationProperty.h
//  MotionCorrection
//
//  Created by Karsten Molka on 24.03.11., 
//  Changes Maurice Hollmann 03/12.
//  Copyright 2012 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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
    
    NSString *ParameterOutputFileOffset;//MH FIXME: not used
    short Threshold;                    //MH FIXME: not used
    double *FinalMovementParameters;    //MH FIXME: not used
    
    /* array with: translationScale, maxStepLength, minStepLength, numIterations*/
    double *RegistrationParameters;     //MH FIXME: remove fourth parameter (numIterations)
    
    /* interpolation type used for registration*/
    int RegistrationInterpolationMode;
    
    /* interpolation type used for resampling*/
    int ResamplingInterpolationMode;
    
    /* number of iterations used in finding transform*/
    int NumberOfIterations;
    
    /* do smoothing for registration */
    bool Smoothing;
    
    /* gaussian variance */
    int SmoothingSigma;
    
    /* kernel size in mm (e.g. 8 for 3mm voxel size) */
    int SmoothingKernelWidth;
    
    /* number of threads used for all processing */
    int NumberOfThreads;
    
    /* use the transformation with the best metric value the observer sees during iteration*/
    bool UseBestFoundParameters;
    
    /* mask the images before registration, this improves performance of the algorithms*/
    bool MaskImagesForRegistration;
    
    
    /*logging level: 0 no logging, 1, low logging ... 3, all logging messages */
    int LoggingLevel;

}

@property(copy) NSString *ParameterOutputFileOffset;

@property(readonly) double *RegistrationParameters;
@property(readonly) double *FinalMovementParameters;

@property int   RegistrationInterpolationMode;
@property int   ResamplingInterpolationMode;
@property int   NumberOfIterations;
@property bool  Smoothing;
@property int   SmoothingSigma;
@property int   SmoothingKernelWidth;
@property int   NumberOfThreads;
@property bool  MaskImagesForRegistration;
@property bool  UseBestFoundParameters;
@property short Threshold;
@property int   LoggingLevel;

- (id) init;
- (void) setRegistrationParameters:(double)translationScale 
                           MaxStep:(double)maxSteplength 
                           MinStep:(double)minSteplength;

- (double *) getRegistrationParameters;
                      
- (void) dealloc; 

@end
