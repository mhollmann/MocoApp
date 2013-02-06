//
//  MocoRegistrationTest.m
//  MocoRegistrationTest
//
//  Created by Maurice Hollmann on 11/5/12.
//  Copyright (c) 2012 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//
/*
 Testcases:
 
 Initialization
    - regProperty function
        - set/get: OK
        - false / extreme values:
    - order of init steps
    - error handling
 
 Align  
    - call align without reference image set: OK
    - expected rp's
        - offline EDDatalements: OK
        - variations of parameters (smooth, extreme values):
 
 Resample   
    - call resample without reference image set: OK
    - expected img data
      - check transform resampling result: OK 

 */


#import "MocoRegistrationTest.h"

#import "MocoRegistrationProperty.h"
#import "MocoRegistration.h"

#import "EDDataElementIsis.h"

@implementation MocoRegistrationTest

NSString* mCurDir = @"";
NSString* mFileNameTestDataNii = @"testData.nii";
NSString* mFileNameTestDataResult3Nii = @"res_0004.nii";
NSString* mFileNameTestData = @"";
NSString* mFileNameTestDataResult3 = @"";
NSString* mFileNameTestMocoParams = @"testData_mocoParams_linear_smoothed5_it12.txt";

- (void)setUp
{
    [super setUp];
    mCurDir = [[NSBundle bundleForClass:[self class] ] resourcePath];
    mFileNameTestData = [NSString stringWithFormat:@"%@/%@", mCurDir, mFileNameTestDataNii];
    mFileNameTestDataResult3 = [NSString stringWithFormat:@"%@/%@", mCurDir, mFileNameTestDataResult3Nii];
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}



- (void)testInitialization
{
    
    MocoRegistrationProperty *regProperty = [[MocoRegistrationProperty alloc] init];
    STAssertNotNil(regProperty, @"valid init returns nil");

    regProperty.LoggingLevel              = 1;
    regProperty.NumberOfThreads           = 10;
    regProperty.Smoothing                 = YES;
    regProperty.SmoothingSigma            = 5;
    regProperty.MaskImagesForRegistration = NO;
    regProperty.UseBestFoundParameters    = NO;
    regProperty.NumberOfIterations        = 12;
    [regProperty setRegistrationParameters:1000.0 MaxStep:0.019 MinStep:0.00001];
    
    STAssertEquals( 1000.0  , regProperty.RegistrationParameters[0] , @"incorrect value returned for init registrationProperty");
    STAssertEquals( 0.019   , regProperty.RegistrationParameters[1] , @"incorrect value returned for init registrationProperty");
    STAssertEquals( 0.00001 , regProperty.RegistrationParameters[2] , @"incorrect value returned for init registrationProperty");
    
    regProperty.RegistrationInterpolationMode = LINEAR;
    regProperty.ResamplingInterpolationMode   = BSPLINE4;
    regProperty.SmoothingKernelWidth  = 32;
    
    
    //init with default params
    MocoRegistration *registratorDefault = [ [MocoRegistration alloc]	init];
    STAssertNotNil(registratorDefault, @"valid init returns nil");
    
    MocoRegistration *registrator = [ [MocoRegistration alloc]	initWithRegistrationProperty:regProperty];
    STAssertNotNil(registrator, @"valid init returns nil");
}
    

- (void)testAlign
{
    MocoRegistrationProperty *regProperty = [[MocoRegistrationProperty alloc] init];
    STAssertNotNil(regProperty, @"valid init returns nil");
    
    regProperty.LoggingLevel              = 1;
    regProperty.NumberOfThreads           = 1;
    regProperty.Smoothing                 = YES;
    regProperty.SmoothingSigma            = 5;
    regProperty.MaskImagesForRegistration = NO;
    regProperty.UseBestFoundParameters    = NO;
    regProperty.NumberOfIterations        = 12;

    //this is the standard for comparison 
    [regProperty setRegistrationParameters:1000.0 MaxStep:0.019 MinStep:0.00001];

    regProperty.RegistrationInterpolationMode = LINEAR;
    regProperty.SmoothingKernelWidth  = 32;

    
    if (![[NSFileManager defaultManager] fileExistsAtPath:mFileNameTestData])
    {
        STFail(@"Did not find test data file.");
        return;
    }
    
    //Expected moco parameters
    // 0.0148 0.0856 0.0063    0.0315 -0.0370 -0.0053
    // 0.0017 0.0399 0.0113   -0.0439 -0.0216  0.0123
    // 0.2376 -0.0811 -0.2526 -0.2421  0.0229  0.2147
    // 0.2492 -0.0867 -0.2597 -0.2883  0.0394  0.2229
    NSArray *resValuesTX = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0148], [NSNumber numberWithFloat:0.0017], [NSNumber numberWithFloat:0.2376], [NSNumber numberWithFloat:0.2492], nil];
    NSArray *resValuesTY = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0856], [NSNumber numberWithFloat:0.0399], [NSNumber numberWithFloat:-0.0811], [NSNumber numberWithFloat:-0.0867], nil];
    NSArray *resValuesTZ = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0063], [NSNumber numberWithFloat:0.0113], [NSNumber numberWithFloat:-0.2526], [NSNumber numberWithFloat:-0.2597], nil];
    NSArray *resValuesRX = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0315], [NSNumber numberWithFloat:-0.0439], [NSNumber numberWithFloat:-0.2421], [NSNumber numberWithFloat:-0.2883], nil];
    NSArray *resValuesRY = [NSArray arrayWithObjects:[NSNumber numberWithFloat:-0.0370], [NSNumber numberWithFloat:-0.0216], [NSNumber numberWithFloat:0.0229], [NSNumber numberWithFloat:0.0394], nil];
    NSArray *resValuesRZ = [NSArray arrayWithObjects:[NSNumber numberWithFloat:-0.0053], [NSNumber numberWithFloat:0.0123], [NSNumber numberWithFloat:0.2147], [NSNumber numberWithFloat:0.2229], nil];    
    
    
    //load data
    EDDataElement *dataEl4D = [MocoRegistration getEDDataElementFromFile: mFileNameTestData];
    EDDataElement *refDataEl3D = [dataEl4D getDataAtTimeStep:0];
    
    STAssertNotNil(dataEl4D, @"load valid nifti returns nil");
	STAssertNotNil(refDataEl3D, @"valid timeStep selection returns nil");
	
	//STAssertEquals([[dataEl4D getProps:propListi] count], (NSUInteger) 0, @"empty list for getProps not returning zero size dict");
	//STAssertNoThrow([dataEl4D setProps:nil], @"empty dict for setProps throws exception");

    EDDataElement *movingDataEl;
    
    
    MocoRegistration *registrator;
    registrator = [ [MocoRegistration alloc]	initWithRegistrationProperty:regProperty];
    STAssertNotNil(registrator, @"valid init returns nil");
    
    //+++ check if calling align without having set the reference throws an exeption +++
    MocoTransformType::Pointer testTransform;
    STAssertThrows( testTransform = [registrator alignEDDataElementToReference: refDataEl3D] , @"Calling align without having set the reference image must throw an exception!");
    
    //set reference
    [registrator setReferenceImageWithEDDataElement:refDataEl3D];
    
    
    int numImages = 5;
    int precisionFactor = 100;//defines the precision needed 100 == 2 decimal positions
    
    int i;
    //start with 2nd image in file
    for (i = 1; i<=numImages-1; i++) {
        
        movingDataEl = [dataEl4D getDataAtTimeStep:i];
        
        //++++ Alignment with correctly set reference image ++++
        MocoTransformType::Pointer transform = [registrator alignEDDataElementToReference: movingDataEl];
         
        MocoOptimizerType::ParametersType transParameters;
        transParameters = transform->GetParameters();
        MocoTransformType::OffsetType offset = transform->GetOffset();
        MocoVectorType versor_axis = transform->GetVersor().GetAxis();
        double versor_angle = transform->GetVersor().GetAngle();
        
        //the computed values should be the same for defined decimal positions
        NSInteger tX = [[NSNumber numberWithDouble: offset[0] * precisionFactor] integerValue];
        NSInteger tY = [[NSNumber numberWithDouble: offset[1] * precisionFactor] integerValue];
        NSInteger tZ = [[NSNumber numberWithDouble: offset[2] * precisionFactor] integerValue];
        
        NSInteger rX = [[NSNumber numberWithDouble: 180/M_PI * versor_axis[0] * versor_angle * precisionFactor] integerValue];
        NSInteger rY = [[NSNumber numberWithDouble: 180/M_PI * versor_axis[1] * versor_angle * precisionFactor] integerValue];
        NSInteger rZ = [[NSNumber numberWithDouble: 180/M_PI * versor_axis[2] * versor_angle * precisionFactor] integerValue];
                
        CGFloat vtX = [[resValuesTX objectAtIndex:i-1] floatValue]*precisionFactor;
        CGFloat vtY = [[resValuesTY objectAtIndex:i-1] floatValue]*precisionFactor;
        CGFloat vtZ = [[resValuesTZ objectAtIndex:i-1] floatValue]*precisionFactor;
        
        CGFloat vrX = [[resValuesRX objectAtIndex:i-1] floatValue]*precisionFactor;
        CGFloat vrY = [[resValuesRY objectAtIndex:i-1] floatValue]*precisionFactor;
        CGFloat vrZ = [[resValuesRZ objectAtIndex:i-1] floatValue]*precisionFactor;
        
        STAssertEquals( [[NSNumber numberWithFloat: vtX] integerValue] , tX , @"incorrect value returned for reg param");
        STAssertEquals( [[NSNumber numberWithFloat: vtY] integerValue] , tY , @"incorrect value returned for reg param");
        STAssertEquals( [[NSNumber numberWithFloat: vtZ] integerValue] , tZ , @"incorrect value returned for reg param");
        
        STAssertEquals( [[NSNumber numberWithFloat: vrX] integerValue] , rX , @"incorrect value returned for reg param");
        STAssertEquals( [[NSNumber numberWithFloat: vrY] integerValue] , rY , @"incorrect value returned for reg param");
        STAssertEquals( [[NSNumber numberWithFloat: vrZ] integerValue] , rZ , @"incorrect value returned for reg param");
    }
    
}

- (void)testResample
{
    MocoRegistrationProperty *regProperty = [[MocoRegistrationProperty alloc] init];
    regProperty.LoggingLevel              = 3;
    regProperty.NumberOfThreads           = 1;
    regProperty.Smoothing                 = YES;
    regProperty.SmoothingSigma            = 5;
    regProperty.MaskImagesForRegistration = NO;
    regProperty.UseBestFoundParameters    = NO;
    regProperty.NumberOfIterations        = 12;
    [regProperty setRegistrationParameters:1000.0 MaxStep:0.019 MinStep:0.00001];
    regProperty.RegistrationInterpolationMode = LINEAR;
    regProperty.SmoothingKernelWidth  = 32;

    MocoRegistration *registrator;
    registrator = [ [MocoRegistration alloc]	initWithRegistrationProperty:regProperty];
    STAssertNotNil(registrator, @"valid init returns nil");
    
    
    //+++++ transform values expected +++++
    /* for resampling the third test image
    Matrix:
    0.999993 -0.00374773 0.000392405
    0.00374604 0.999984 0.00422586
    -0.000408236 -0.00422436 0.999991
    Offset: [0.23762, -0.0811229, -0.252632]
    Center: [3.43672, 4.61626, 26.7917]
    Translation: [0.230808, 0.0448957, -0.273777]
    Inverse:
    0.999993 0.00374604 -0.000408236
    -0.00374773 0.999984 -0.00422436
    0.000392405 0.00422586 0.999991
    Singular: 0
    Versor: [-0.00211257, 0.000200161, 0.00187345, 0.999996 ]
    */
    MocoTransformType::Pointer  transform = MocoTransformType::New();
    
    MocoTransformType::InputPointType centerPoint;
    centerPoint = transform->GetCenter();
    centerPoint[0] = 3.43672;
    centerPoint[1] = 4.61626;
    centerPoint[2] = 26.7917;
    transform->SetCenter(centerPoint);
    
    MocoTransformType::ParametersType params;
    params = transform->GetParameters();
    params[0] = -0.00211257;
    params[1] =  0.000200161;
    params[2] =  0.00187345;
    params[3] =  0.230808;
    params[4] =  0.0448957;
    params[5] = -0.273777;
    
    transform->SetParameters(params);
    
    //set up images
    EDDataElement *dataEl4D    = [MocoRegistration getEDDataElementFromFile: mFileNameTestData];
    EDDataElement *movDataEl3D;
    movDataEl3D = [dataEl4D getDataAtTimeStep:3];
    EDDataElement *resultDataEl;
    
    //MH FIXME: Is there an ISIS debug warning if loading a 3D image??? (EDDatalElement initWithDataFile)
    EDDataElement *resultCompareDataEl = [MocoRegistration getEDDataElementFromFile: mFileNameTestDataResult3];
    
    //Check call with MISSING reference image
    STAssertThrows(resultDataEl = [registrator resampleMovingEDDataElement:movDataEl3D withTransform:transform], @"Calling resampling without having set the reference image must throw an exception!");
    
    //Go on with correctly set reference image
    [registrator setReferenceImageWithEDDataElement:[dataEl4D getDataAtTimeStep:0]];
    resultDataEl = [registrator resampleMovingEDDataElement:movDataEl3D withTransform:transform];
        
    //MH FIXME: a workaround because header params are not correctly copied by itkAdapter
    NSArray *propsToCopy = [NSArray arrayWithObjects:
                                @"voxelsize",
                                @"rowVec",
                                @"sliceVec",
                                @"columnVec",
                                @"indexOrigin",
                                nil];
    [resultDataEl copyProps:propsToCopy fromDataElement:movDataEl3D];
    NSDictionary *dic = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects:@"mocoAppExport", nil]
                                                        forKeys: [NSArray arrayWithObjects:@"sequenceDescription", nil] ];
    [resultDataEl setProps:dic];
        
    
    //Now compare the resampling result to expected result
    dispatch_queue_t processingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(processingQueue, ^{
    
        BARTImageSize *sizeData = [resultCompareDataEl getImageSize];
    
        for (size_t sliceNum = 1; sliceNum < sizeData.slices; sliceNum++){
             for (size_t rowNum = 1; rowNum < sizeData.rows; rowNum++){
                for (size_t colNum = 1; colNum < sizeData.columns; colNum++){
                    float valComp  = [resultCompareDataEl getFloatVoxelValueAtRow: rowNum col: colNum slice: sliceNum timestep:0];
                    float valRes   = [resultDataEl getFloatVoxelValueAtRow: rowNum col: colNum slice: sliceNum timestep:0];
                    STAssertEqualsWithAccuracy(valComp, valRes, 0.001, @"Resampling gives incorrect voxel values!");
                }
            }
        }
        
    });// end dispatch_async


}


@end
