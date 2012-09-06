//
//  MocoApplicationAppDelegate.m
//  MocoApplication
//
//  Created by Maurice Hollmann on 5/2/12.
//  Copyright (c) 2012 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import "MocoApplicationAppDelegate.h"


#include <iostream>
#include <fstream>

#import "MocoRegistration.h"
#import "MocoTextIO.h"

@implementation MocoApplicationAppDelegate

@synthesize window;
@synthesize mAppGraphView;
@synthesize mNumIterationsPullDown;
@synthesize mSmoothKernelPullDown;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    
    //prepare iterations pull down
    [mNumIterationsPullDown removeAllItems];
    int i;
    for (i=1; i<=10; i++)
    {
        [mNumIterationsPullDown addItemWithTitle: [NSString stringWithFormat:@"%i", i*2]];
    }
    [mNumIterationsPullDown setTitle: @"6"];
    
    
    //prepare smooth pull down
    [mSmoothKernelPullDown removeAllItems];
    for (i=1; i<=16; i++)
    {
        [mSmoothKernelPullDown addItemWithTitle: [NSString stringWithFormat:@"%i", i]];
    }
    [mSmoothKernelPullDown setTitle: @"8"];
    [mSmoothKernelPullDown addItemWithTitle:@"No Smoothing"];
    
    
    // set the content to the viewControllers' view
    mMocoDrawViewController = [[MocoDrawViewController alloc] initWithNibName:@"MocoDrawView" bundle:nil];
    [mMocoDrawViewController loadView];
    

    //replace the apps drawView with the mocoDrawView and set correct size
    NSView *drawView = [mMocoDrawViewController view];
    NSRect cvFrame = [mAppGraphView frame];
     
    [[self.window contentView] replaceSubview:mAppGraphView with:drawView];
    [drawView setFrame:cvFrame];

}





- (IBAction)setNumIterationsByPullDown:(NSPopUpButton *)sender {

    NSString *valSelected = [sender titleOfSelectedItem];
    NSLog(@"Val selected: %@", valSelected);
    [sender setTitle: valSelected];

}



- (IBAction)setSmoothKernelByPullDown:(NSPopUpButton *)sender {
    
    NSString *valSelected = [sender titleOfSelectedItem];
    NSLog(@"Val selected: %@", valSelected);
    [sender setTitle: valSelected];
   
    
}



- (IBAction)startRegistrationMI:(NSMenuItem *)sender {
    //+++++++++++++++++++++++++++++
    //++++ Read the plist file ++++
    //+++++++++++++++++++++++++++++
    NSPropertyListFormat format;
    NSString *errDescr = nil;
    NSString *rootPath =
    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, NO)
     objectAtIndex:0];
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"defaultRegParams.plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath])
    {
        plistPath = [[NSBundle mainBundle] pathForResource:@"defaultRegParams" ofType:@"plist"];
    }
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:plistPath] ) {
        NSLog(@"Errror: Could not read configuration from plist file (file not found): %@", plistPath);
        return;
    }
    
    //read the plist file
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSDictionary *arrayFromPlist = (NSDictionary *) [NSPropertyListSerialization propertyListFromData:plistXML
                                                                                     mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                                                               format:&format
                                                                                     errorDescription:&errDescr];
    
    MocoRegistrationProperty *regProperty = [[MocoRegistrationProperty alloc] init];
    uint16 numberOfIterations;
    
    if (!arrayFromPlist )
    {
        NSLog(@"Error reading plist defaultRegParams.plist: %@, format: %lu", errDescr, format);
        
    }else{
        
//        NSArray *mA = [arrayFromPlist allValues];
//        NSArray *mB = [arrayFromPlist allKeys];
//        
//        int i;
//        for(i=0; i<=[mA count]-1; i++)
//        {
//            NSLog(@"Key: %@", [mB objectAtIndex:i]);
//            NSLog(@"Value: %ld", [[mA objectAtIndex:i] integerValue]);
//        }
        
        //assign params from plist
        regProperty.LoggingLevel              = [[arrayFromPlist objectForKey:@"LoggingLevel"] unsignedIntegerValue];
        regProperty.NumberOfThreads           = [[arrayFromPlist objectForKey:@"NumberOfThreads"] unsignedIntegerValue];
        regProperty.Smoothing                 = [[arrayFromPlist objectForKey:@"Smoothing"] boolValue];
        regProperty.SmoothingSigma            = [[arrayFromPlist objectForKey:@"SmoothingSigma"] unsignedIntegerValue];
        regProperty.MaskImagesForRegistration = [[arrayFromPlist objectForKey:@"MaskImagesForRegistration"] boolValue];
        regProperty.UseBestFoundParameters    = [[arrayFromPlist objectForKey:@"UseBestFoundParameters"] boolValue];
        numberOfIterations                    = [[arrayFromPlist objectForKey:@"NumberOfIterations"] unsignedIntegerValue];
    }
    
    if ( regProperty.LoggingLevel > 2 ) {
        std::cout << "Params read from plist:   " << std::endl;
        std::cout << "LoggingLevel:             " << regProperty.LoggingLevel << std::endl;
        std::cout << "NumberOfThreads:          " << regProperty.NumberOfThreads << std::endl;
        std::cout << "Smoothing:                " << regProperty.Smoothing << std::endl;
        std::cout << "SmoothingSigma:           " << regProperty.SmoothingSigma << std::endl;
        std::cout << "MaskImagesForRegistration:" << regProperty.MaskImagesForRegistration << std::endl;
        std::cout << "UseBestFoundParameters:   " << regProperty.UseBestFoundParameters << std::endl;
    }
    
    //maxStepLength Default AFNI: 0.7 * voxel size
    //numIterations Default AFNI: 19
    //[regProperty setRegistrationParameters:1.0/50.0 MaxStep:0.019 MinStep:0.00001 NumIterations:numberOfIterations];
    [regProperty setRegistrationParameters:1.0/50.0 MaxStep:0.019 MinStep:0.00001 NumIterations:numberOfIterations];
    regProperty.RegistrationInterpolationMode = LINEAR;
    regProperty.ResamplingInterpolationMode   = BSPLINE4;
    regProperty.SmoothingKernelWidth  = 64;
    
    
    
    
    
    
    
    //++++++++++++++++++++++++++++++++++++
    //++++++++++ File definitions ++++++++
    //++++++++++++++++++++++++++++++++++++
    
    
    //++++ 3D test case ++++
//    NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/test3D.nii";
//    int numImages = 0;
//    NSString *mocoMovParamsOutFileBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/mocoApp/testCase";
    
    
    //++++ 4D register to first ++++    
    //Normal motion
//    NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/data01_funk_64_64_3T_normal.nii";
//    int numImages = 506;
//    NSString *mocoMovParamsOutFileBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/mocoApp/data01_mocoParams_mocoApp";
    
    
    //A lot of motion
//    NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/data03_FD4T_NF4.nii";
//    int numImages = 269;
//    NSString *mocoMovParamsOutFileBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/mocoApp/data03_mocoParams_mocoApp";
    
    
    //Original Karsten's data01 
    NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/data04_vol_dset1.nii";
    int numImages = 542;
    NSString *mocoMovParamsOutFileBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/mocoApp/data04_mocoParams_mocoApp";
    
    
    
    
    //++++++++++++++++++++++++++++++++++++
    //++++ Start registration process ++++
    //++++++++++++++++++++++++++++++++++++
    
    //a registrator holding interfaces of itk reg functionality
    MocoRegistration *registrator = [ [MocoRegistration alloc]	initWithRegistrationProperty:regProperty ];
    
    
    
    //[registrator maskITKImage];
    //return;
    
    
    
    // This is done in an async process to unblock the main thread
    dispatch_queue_t imageProcessingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    
    dispatch_async(imageProcessingQueue, ^{
        
        timeval startTimeAlign, endTimeAlign;
        
        EDDataElement *dataEl4D = [registrator getEDDataElementFromFile:file4D];
        EDDataElement *refDataEl3D = [dataEl4D getDataAtTimeStep:0];
        
        //set reference
        [registrator setReferenceEDDataElement:refDataEl3D];
        
        int i;
        for (i = 1; i<=numImages; i++) {
            
            EDDataElement *movingDataEl = [dataEl4D getDataAtTimeStep:i];
            
            //do alignment
            gettimeofday(&startTimeAlign, 0);
            MocoTransformType::Pointer transform = [registrator alignEDDataElementToReference: movingDataEl];
            gettimeofday(&endTimeAlign, 0);
            
            MocoOptimizerType::ParametersType transParameters;
            transParameters = transform->GetParameters();
            
            //MHFIXME:
            //The problem using offset might be, that the center of rotation is different in the interpretations:
            //1. final transform raw parameters 3-5: centered rotation about the middle of the image
            //2. final transform offset:             rotation is centered at 0,0,0 of physical space: different transformations!
            //What is SPM showing??? Rotation about 0,0,0  or image center? Probably 0,0,0!
            MocoTransformType::OffsetType offset = transform->GetOffset();
            MocoVectorType versor_axis = transform->GetVersor().GetAxis();
            double versor_angle = transform->GetVersor().GetAngle();
            
            double rotAngleX              = 180/M_PI * versor_axis[0] * versor_angle;
            double rotAngleY              = 180/M_PI * versor_axis[1] * versor_angle;
            double rotAngleZ              = 180/M_PI * versor_axis[2] * versor_angle;
            double finalTranslationX    = offset[0];
            double finalTranslationY    = offset[1];
            double finalTranslationZ    = offset[2];
            
            
            [mMocoDrawViewController addValuesToGraphs:finalTranslationX TransY:finalTranslationY TransZ:finalTranslationZ RotX:rotAngleX RotY:rotAngleY RotZ:rotAngleZ];
            
            
            //send the reload to the main thread
            dispatch_sync(dispatch_get_main_queue(), ^{
                [mMocoDrawViewController updateGraphs];
            });
            
            
            
            if (regProperty.LoggingLevel > 1){
                
                NSLog(@"**** VIEW CONTROLLER ****");
                NSLog(@"transX of transform: %f ", finalTranslationX);
                NSLog(@"transY of transform: %f ", finalTranslationY);
                NSLog(@"transZ of transform: %f ", finalTranslationZ);
                NSLog(@"rotX of transform: %f ", rotAngleX);
                NSLog(@"rotY of transform: %f ", rotAngleY);
                NSLog(@"rotZ of transform: %f ", rotAngleZ);
                
                std::cout << "Time needed for alignment: " << [self getTimeDifference:startTimeAlign endTime:endTimeAlign] << " s" << std::endl;
            }
            
        }//endfor
        
        
        
        
        //*****************************************
        //****** Write params to txt file *********
        //*****************************************
        NSString *mocoMovParamsOutFile;
        
        //determine correct name for outfile
        if(regProperty.RegistrationInterpolationMode == LINEAR)
        {
            mocoMovParamsOutFile = [mocoMovParamsOutFileBase stringByAppendingString:@"_linear"];
        }
        else if (regProperty.RegistrationInterpolationMode == BSPLINE2)
        {
            mocoMovParamsOutFile = [mocoMovParamsOutFileBase stringByAppendingString:@"_bspline2"];
        }
        else if (regProperty.RegistrationInterpolationMode == BSPLINE4)
        {
            mocoMovParamsOutFile = [mocoMovParamsOutFileBase stringByAppendingString:@"_bspline4"];
        }
        
        
        if( regProperty.MaskImagesForRegistration )
        {
            mocoMovParamsOutFile = [mocoMovParamsOutFile stringByAppendingString:@"_masked"];
        }
        
        if(regProperty.Smoothing)
        {
             mocoMovParamsOutFile = [mocoMovParamsOutFile stringByAppendingString: [NSString stringWithFormat: @"_smoothed%i", regProperty.SmoothingSigma]];
        }
 
        
        mocoMovParamsOutFile = [mocoMovParamsOutFile stringByAppendingString: [NSString stringWithFormat:@"_it%i.txt", numberOfIterations]];
        
        
        //remove the resulting file if it exists
        NSFileManager *fm = [NSFileManager defaultManager];
        
        if ([fm fileExistsAtPath:mocoMovParamsOutFile])
        {
            [fm removeItemAtPath:mocoMovParamsOutFile error:nil];
        }
        std::string mocoMovParamsOutFileString = [mocoMovParamsOutFile UTF8String];
        
        
        //For writing the resulting parameters
        MocoTextIO mocoTxtWriter;
        
        //first line zeros
        NSString *lineToWrite = [NSString stringWithFormat:@"%f %f %f %f %f %f", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
        mocoTxtWriter.appendLineToFile(mocoMovParamsOutFileString, [lineToWrite UTF8String]);
        
        for (i = 0; i<=numImages-1; i++) {
            
            NSString *lineToWrite = [NSString stringWithFormat:@"%f %f %f %f %f %f",
                                     [[mMocoDrawViewController.transArrayX objectAtIndex:i] doubleValue],
                                     [[mMocoDrawViewController.transArrayY objectAtIndex:i] doubleValue],
                                     [[mMocoDrawViewController.transArrayZ objectAtIndex:i] doubleValue],
                                     [[mMocoDrawViewController.rotArrayX objectAtIndex:i] doubleValue],
                                     [[mMocoDrawViewController.rotArrayY objectAtIndex:i] doubleValue],
                                     [[mMocoDrawViewController.rotArrayZ objectAtIndex:i] doubleValue] ];
            
            //not fast but not prone to disruptions
            mocoTxtWriter.appendLineToFile(mocoMovParamsOutFileString, [lineToWrite UTF8String]);
            
        }
        
        if (regProperty.LoggingLevel > 0)
        {
            NSLog(@"Written mocoParams to file: %@", mocoMovParamsOutFile);
        }
        
        
        [registrator dealloc];
        
        
    });//end dispatch async
    
}





-(double)getTimeDifference:(timeval) startTime endTime:(timeval) endTime
{
    
    //calculate difference between timevals
    double  diffSec, diffUSec;
    
    if ( endTime.tv_sec == startTime.tv_sec ) {
        
        diffSec  = 0;
        diffUSec = endTime.tv_usec - startTime.tv_usec;
    } else {
        
        if( endTime.tv_usec < startTime.tv_usec ) {
            
            diffSec  = endTime.tv_sec - startTime.tv_sec - 1;
            diffUSec = 1000000 - startTime.tv_usec + endTime.tv_usec;
        } else {
            
            diffSec  = endTime.tv_sec - startTime.tv_sec;
            diffUSec = endTime.tv_usec - startTime.tv_usec;
            
        }
    }
    
    
    return diffSec+diffUSec/1000000;
}




@end
