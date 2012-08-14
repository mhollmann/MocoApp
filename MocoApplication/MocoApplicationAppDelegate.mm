//
//  MocoApplicationAppDelegate.m
//  MocoApplication
//
//  Created by willi on 5/2/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "MocoApplicationAppDelegate.h"
#import "MocoDrawViewController.h"

#import "MocoTextIO.h"

#include <iostream>
#include <fstream>

@implementation MocoApplicationAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    NSLog(@"Application finished launching ...");
    
    mMocoDrawViewController = [[MocoDrawViewController alloc] initWithNibName:@"MocoDrawView" bundle:nil];
     
    [mMocoDrawViewController loadView];
    [self.window setContentView:[mMocoDrawViewController view]];   
       
}



- (IBAction)startRegistrationMI:(id)sender {
    
    
    //*****************************
    //**** Read the plist file ****
    //*****************************
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
        plistPath = @"/Users/mhollmann/Programming/MOCO_REGISTRATION_BART/defaultRegParams.plist";
    }
        
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSDictionary *arrayFromPlist = (NSDictionary *) [NSPropertyListSerialization propertyListFromData:plistXML
                                                                                     mutabilityOption:NSPropertyListMutableContainersAndLeaves 
                                                                                               format:&format 
                                                                                     errorDescription:&errDescr];
    
    
    MocoRegistrationProperty *regProperty = [[MocoRegistrationProperty alloc] init];
    
    if (!arrayFromPlist )
    {
        NSLog(@"Error reading plist defaultRegParams.plist: %@, format: %lu", errDescr, format);
        
    }else{
        
        //assign params from plist
        regProperty.logging         = [[arrayFromPlist objectForKey:@"logging"] boolValue];
        regProperty.NumberOfThreads = [[arrayFromPlist objectForKey:@"NumberOfThreads"] unsignedIntegerValue];
        regProperty.Smoothing       = [[arrayFromPlist objectForKey:@"Smoothing"] boolValue];
    }
    
    
    if ( regProperty.logging ) {
        std::cout << "Params read from plist: " << std::endl;
        std::cout << "NumberOfThreads: " << regProperty.NumberOfThreads << std::endl;
        std::cout << "Smoothing:       " << regProperty.Smoothing << std::endl;
    } else {
        std::cout << "Logging not enabled! " << std::endl;
        regProperty.NumberOfThreads = 2;
        regProperty.Smoothing       = YES;
    }
    
     
    regProperty.SmoothingSigma = 8 / 2.35482;
    regProperty.SmoothingKernelWidth = 64;
    regProperty.UseBestFoundParameters = YES;
    regProperty.logging = YES;
    
    //maxStepLength Default AFNI: 0.7 * voxel size
    //numIterations Default AFNI: 19
    //[regProperty setRegistrationParameters:1.0/50.0 MaxStep:0.019 MinStep:0.00001 NumIterations:10];
    [regProperty setRegistrationParameters:1.0/50.0 MaxStep:0.019 MinStep:0.00001 NumIterations:8];
    regProperty.RegistrationInterpolationMode = LINEAR; 
    regProperty.ResamplingInterpolationMode   = BSPLINE4;
    
    
    
    
    
    
    
    //************************************
    //********** File definitions ********
    //************************************    
    
    //****4D register to first ****
    //NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/MocoApplication/MocoApplication/data/data4D_HMMT_201226.nii";
    //int numImages = 389;
    
    
    
    
    NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/MocoApplication/MocoApplication/data/spmCompare/inceptNF_FD4T_NF4.nii";
    int numImages = 269;
    NSString *mocoMovParamsOutFile = @"/Users/mhollmann/Projekte/Project_MOCOApplication/MocoApplication/MocoApplication/data/spmCompare/mocoApp_mocoParameters.txt";
    
    
    
    
//    NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/MocoApplication/MocoApplication/data/dataKarsten/data03_funk_64_64_3T_normal.nii";
//    int numImages = 506;
//    NSString *mocoMovParamsOutFile = @"/Users/mhollmann/Projekte/Project_MOCOApplication/MocoApplication/MocoApplication/data/dataKarsten/mocoApp_mocoParameters.txt";
//    
    
    
    
    
    
    
    //************************************
    //**** Start registration process ****
    //************************************

    //a registrator holding interfaces of itk reg functionality
    MocoRegistration *registrator = [ [MocoRegistration alloc]	initWithRegistrationProperty:regProperty ];
    
    
    /* This is done in a async process to unblock the main thread */
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
           
        
             
            if (regProperty.logging){        
    
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
        
        
        //remove the resulting file if it exists
        NSFileManager *fm = [NSFileManager defaultManager];
        
        if ([fm fileExistsAtPath:mocoMovParamsOutFile])
        {
            [fm removeItemAtPath:mocoMovParamsOutFile error:nil];
        }
        std::string mocoMovParamsOutFileString = [mocoMovParamsOutFile UTF8String];
        
        //std::ofstream *txtFile;
        //txtFile->open(mocoMovParamsOutFileString.c_str(), ios::out | ios::app);
        
        //For writing the resulting parameters
        MocoTextIO mocoTxtWriter;
        
       
        for (i = 0; i<=numImages-1; i++) {
            
            NSString *lineToWrite = [NSString stringWithFormat:@"%f %f %f %f %f %f", 
                                     [[mMocoDrawViewController.transArrayX objectAtIndex:i] doubleValue], 
                                     [[mMocoDrawViewController.transArrayY objectAtIndex:i] doubleValue], 
                                     [[mMocoDrawViewController.transArrayZ objectAtIndex:i] doubleValue], 
                                     [[mMocoDrawViewController.rotArrayX objectAtIndex:i] doubleValue], 
                                     [[mMocoDrawViewController.rotArrayY objectAtIndex:i] doubleValue], 
                                     [[mMocoDrawViewController.rotArrayZ objectAtIndex:i] doubleValue] ];
            //NSLog(@"LineToWrite: %@", lineToWrite);
            
            
            mocoTxtWriter.appendLineToFile(mocoMovParamsOutFileString, [lineToWrite UTF8String]);
            //mocoTxtWriter.appendLineToStream(txtFile, [lineToWrite UTF8String]);
            
        }
        
//        if (txtFile->is_open())
//        {
//            txtFile->close();
//        }
        
        
        
        
        
        
        
        
        
    });//end dispatch async
   
    
    
    
        
    
    
    
    
    
    
    
    
    
} //end startRegistration



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
