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
#define INTERPOLATOR_NN 11 

#define METRIC_FAILURE 100
#define IMAGEREAD_FAILURE 101
#define EVOL_SUCCESS 0

@interface MocoRegistrationProperty : NSObject {

@private 

    double *RegistrationParameters;
    int     RegistrationInterpolationMode;
    int     ResamplingInterpolationMode;
    int     NumberOfIterations;
    bool    Smoothing;
    int     SmoothingSigma;
    int     SmoothingKernelWidth;
    int     NumberOfThreads;
    bool    UseBestFoundParameters;
    bool    MaskImagesForRegistration;
    int     LoggingLevel;

}

/** @property  RegistrationParameters
 *  @brief     Three algo parameters: translationScale, maxStepLength, minStepLength
 *             Always set property using: setRegistrationParameters.
 */
@property(readonly) double *RegistrationParameters;

/** @property  RegistrationInterpolationMode
 *  @brief     Interpolation during alignment: LINEAR, BSPLINE(2-5) , SINC(2-6), INTERPOLATOR_NN
 *             Defines which interpolation is done during alignment. LINEAR is usually fast and good!
 */
@property int   RegistrationInterpolationMode;

/** @property  ResamplingInterpolationMode
 *  @brief     Interpolation during resampling: LINEAR, BSPLINE(2-5) , SINC(2-6), INTERPOLATOR_NN
 *             Defines which interpolation is done for resampling.
 *             This should be high quality (usually BSPLINE4 or better).
 */
@property int   ResamplingInterpolationMode;

/** @property  NumberOfIterations
 *  @brief     Number of iterations used to find transformation
 *             Basic rule: as more movement is in the data, as more iterations are needed
 */
@property int   NumberOfIterations;

/** @property  Smoothing
 *  @brief     Boolean that depicts if smoothing should be done
 */
@property bool  Smoothing;

/** @property  SmoothingSigma
 *  @brief     The gaussian variance for smoothing in mm (e.g. 5)
 */
@property int   SmoothingSigma;

/** @property  SmoothingKernelWidth
 *  @brief     Kernel width for smoothing in mm (e.g. 32) 
 */
@property int   SmoothingKernelWidth;

/** @property  NumberOfThreads
 *  @brief     The number of threads that should be used to parallelize alignment and resampling (e.g. 16).
 *             The more threads are used the faster is the processing.
 */
@property int   NumberOfThreads;


/** @property  MaskImagesForRegistration
 *  @brief     Boolean that depicts if the images should be masked for alignment.
 *             Masking makes the alignment more stable and faster, because the metric is not
 *             computed over background voxels.
 */
@property bool  MaskImagesForRegistration;

/** @property  UseBestFoundParameters
 *  @brief     Boolean that depicts if the best parameters from all iteration should be used.
 *             The best parameters are often reprsenting local minima in metric, so usually this
 *             value should be false.
 */
@property bool  UseBestFoundParameters;



/** @property  LoggingLevel
 *  @brief     logging level (0-3): 0: no logging, 1: low logging ... 3: all logging messages 
 */
@property int   LoggingLevel;

- (id) init;

- (void) setRegistrationParameters:(double)translationScale
                           MaxStep:(double)maxSteplength 
                           MinStep:(double)minSteplength;

- (double *) getRegistrationParameters;
                      
- (void) dealloc; 

@end
