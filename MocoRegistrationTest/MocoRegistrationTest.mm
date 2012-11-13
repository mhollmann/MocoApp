//
//  MocoRegistrationTest.m
//  MocoRegistrationTest
//
//  Created by Maurice Hollmann on 11/5/12.
//  Copyright (c) 2012 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import "MocoRegistrationTest.h"

#import "MocoRegistrationProperty.h"
#import "MocoRegistration.h"

#import "EDDataElementIsis.h"

@implementation MocoRegistrationTest

/*
 Testcases:
 Initialization - regProperty function + order of init steps + error handling
 Align          - expected rp's
 Resample       - expected img data
 */


NSString* mCurDir = @"";
NSString* mFileNameTestDataNii = @"testData.nii";
NSString* mFileNameTestData = @"";
NSString* mFileNameTestMocoParams = @"testData_mocoParams_linear_smoothed5_it12.txt";

- (void)setUp
{
    [super setUp];
    mCurDir = [[NSBundle bundleForClass:[self class] ] resourcePath];
    mFileNameTestData = [NSString stringWithFormat:@"%@/%@", mCurDir, mFileNameTestDataNii];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}



- (void)testAlign
{
    MocoRegistrationProperty *regProperty = [[MocoRegistrationProperty alloc] init];
    STAssertNotNil(regProperty, @"valid init returns nil");
    
    regProperty.LoggingLevel              = 3;
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
    
    //set reference
    MocoRegistration *registrator;
    registrator = [ [MocoRegistration alloc]	initWithRegistrationProperty:regProperty];
    [registrator setReferenceImageWithEDDataElement:refDataEl3D];
    
    int numImages = 5;
    int precisionFactor = 100;//defines the precision needed 100 == 2 decimal positions
    
    int i;
    //start with 2nd image in file
    for (i = 1; i<=numImages-1; i++) {
        
        movingDataEl = [dataEl4D getDataAtTimeStep:i];
        
        //++++ Alignment ++++
        MocoTransformType::Pointer transform = [registrator alignEDDataElementToReference: movingDataEl];
         
        //++++ Send transform parameters to graph plot ++++
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


@end
