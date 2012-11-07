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

#import "MocoDataLogger.h"
#import "BARTNotifications.h"


@interface MocoApplicationAppDelegate (PrivateMethods)

    -(void)realTimeTCPIPModeNextDataArrived:(NSNotification*)aNotification;
    -(void)realTimeTCPIPModeLastScanArrived:(NSNotification*)aNotification;

    -(void)runOfflineMotionCorrection;
    -(void)runRealTimeTCPIPMotionCorrection;

    -(double)getTimeDifference:(timeval) startTime endTime:(timeval) endTime;

@end





@implementation MocoApplicationAppDelegate

@synthesize window;
@synthesize mAppGraphView;
@synthesize mNumIterationsPullDown;
@synthesize mSmoothKernelPullDown;
@synthesize mMaskImagesPullDown;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    //prepare members
    mRealTimeTCPIPMode = YES;
    mMocoIsRunning = NO;
    
    //set the content to the viewControllers' view
    mMocoDrawViewController = [[MocoDrawViewController alloc] initWithNibName:@"MocoDrawView" bundle:nil];
    [mMocoDrawViewController loadView];
    

    //replace the apps drawView with the mocoDrawView and set correct size
    NSView *drawView = [mMocoDrawViewController view];
    NSRect cvFrame = [mAppGraphView frame];
    [[self.window contentView] replaceSubview:mAppGraphView with:drawView];
    [drawView setFrame:cvFrame];
    
    
    
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //++++ Read the mRegistrationProperty defaults plist file ++++
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
    
    mRegistrationProperty = [[MocoRegistrationProperty alloc] init];
    
    if (!arrayFromPlist )
    {
        NSLog(@"Error reading plist defaultRegParams.plist: %@, format: %lu", errDescr, format);
        
    }else{
        
        //assign params from plist
        mRegistrationProperty.LoggingLevel              = [[arrayFromPlist objectForKey:@"LoggingLevel"] unsignedIntegerValue];
        mRegistrationProperty.NumberOfThreads           = [[arrayFromPlist objectForKey:@"NumberOfThreads"] unsignedIntegerValue];
        mRegistrationProperty.Smoothing                 = [[arrayFromPlist objectForKey:@"Smoothing"] boolValue];
        mRegistrationProperty.SmoothingSigma            = [[arrayFromPlist objectForKey:@"SmoothingSigma"] unsignedIntegerValue];
        mRegistrationProperty.MaskImagesForRegistration = [[arrayFromPlist objectForKey:@"MaskImagesForRegistration"] boolValue];
        mRegistrationProperty.UseBestFoundParameters    = [[arrayFromPlist objectForKey:@"UseBestFoundParameters"] boolValue];
        mRegistrationProperty.NumberOfIterations        = [[arrayFromPlist objectForKey:@"NumberOfIterations"] unsignedIntegerValue];
    }
    
    if ( mRegistrationProperty.LoggingLevel > 2 ) {
        std::cout << "Params read from plist:   " << std::endl;
        std::cout << "LoggingLevel:             " << mRegistrationProperty.LoggingLevel << std::endl;
        std::cout << "NumberOfThreads:          " << mRegistrationProperty.NumberOfThreads << std::endl;
        std::cout << "Smoothing:                " << mRegistrationProperty.Smoothing << std::endl;
        std::cout << "SmoothingSigma:           " << mRegistrationProperty.SmoothingSigma << std::endl;
        std::cout << "MaskImagesForRegistration:" << mRegistrationProperty.MaskImagesForRegistration << std::endl;
        std::cout << "UseBestFoundParameters:   " << mRegistrationProperty.UseBestFoundParameters << std::endl;
    }
    
    //parameters orig
    //[mRegistrationProperty setRegistrationParameters:1.0/50.0 MaxStep:0.019 MinStep:0.00001];
       
    //this is the standard
    [mRegistrationProperty setRegistrationParameters:1000.0 MaxStep:0.019 MinStep:0.00001];
    
    mRegistrationProperty.RegistrationInterpolationMode = LINEAR;//BSPLINE2;
    mRegistrationProperty.ResamplingInterpolationMode   = BSPLINE4;
    mRegistrationProperty.SmoothingKernelWidth  = 32;
        
    
    //+++++++++++++++++++++++++++++++++++++++++
    //+++++++++ Prepare GUI components ++++++++
    //+++++++++++++++++++++++++++++++++++++++++
    
    //prepare iterations pull down
    [mNumIterationsPullDown removeAllItems];
    int i;
    for (i=1; i<=20; i++)
    {
        [mNumIterationsPullDown addItemWithTitle: [NSString stringWithFormat:@"%i", i*2]];
    }
    [mNumIterationsPullDown setTitle: [NSString stringWithFormat:@"%i", mRegistrationProperty.NumberOfIterations]];
    
    //prepare smooth pull down
    [mSmoothKernelPullDown removeAllItems];
    for (i=1; i<=16; i++)
    {
        [mSmoothKernelPullDown addItemWithTitle: [NSString stringWithFormat:@"%i", i]];
    }
    
    if(mRegistrationProperty.Smoothing)
    {
        [mSmoothKernelPullDown setTitle: [NSString stringWithFormat:@"%i", mRegistrationProperty.SmoothingSigma]];
    }
    else
    {
        [mSmoothKernelPullDown setTitle: @"None"];
    }
    [mSmoothKernelPullDown addItemWithTitle:@"None"];
    
    //prepare maskImages pull down
    [mMaskImagesPullDown removeAllItems];
    [mMaskImagesPullDown addItemWithTitle:@""];
    [mMaskImagesPullDown addItemWithTitle:@"Yes"];
    [mMaskImagesPullDown addItemWithTitle:@"No"];
    if(mRegistrationProperty.MaskImagesForRegistration)
    {
        [mMaskImagesPullDown setTitle: @"Yes"];
    }
    else
    {
        [mMaskImagesPullDown setTitle: @"No"];
    }
    
    
    
    
    //+++++++++++++++++++++++++++++++++++++++++
    //+++++++ Initialize real time loader +++++
    //+++++++++++++++++++++++++++++++++++++++++
    if(mRealTimeTCPIPMode)
    {
        mRTDataLoader = [[EDDataElementRealTimeLoader alloc] init];
        
        //register self as observer for new data
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(realTimeTCPIPModeNextDataArrived:)
													 name:BARTDidLoadNextDataNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(realTimeTCPIPModeLastScanArrived:)
													 name:BARTScannerSentTerminusNotification object:nil];
        
         mRealTimeTCPIPReadingThread = [[NSThread alloc] initWithTarget:mRTDataLoader selector:@selector(startRealTimeInputOfImageType) object:nil];
     }
    
    
}// end applicationDidFinishLaunching



- (IBAction)setNumIterationsByPullDown:(NSPopUpButton *)sender {

    NSString *valSelected = [sender titleOfSelectedItem];
    [sender setTitle: valSelected];
    
    mRegistrationProperty.NumberOfIterations = [valSelected intValue];
}



- (IBAction)setSmoothKernelByPullDown:(NSPopUpButton *)sender {
    
    NSString *valSelected = [sender titleOfSelectedItem];
    [sender setTitle: valSelected];
    
    if([valSelected isEqualToString:@"None"])
    {
        mRegistrationProperty.Smoothing = NO;
    }
    else
    {
        mRegistrationProperty.SmoothingSigma = [valSelected intValue];
    }
}



- (IBAction)setMaskImagesByPullDown:(NSPopUpButton *)sender {
    
    NSString *valSelected = [sender titleOfSelectedItem];
    [sender setTitle: valSelected];
    
    if([valSelected isEqualToString:@"Yes"])
    {
        mRegistrationProperty.MaskImagesForRegistration = YES;
    }
    else
    {
        mRegistrationProperty.MaskImagesForRegistration = NO;
    }

}



- (IBAction)startStopButtonPressed:(NSButton *)sender {

    if(mMocoIsRunning){
        mMocoIsRunning = NO;
        
        if(mRealTimeTCPIPMode)
        {
            NSLog(@"Stopping Real-Time Moco...");
            [mRealTimeTCPIPReadingThread cancel];
        }
            
        //clear view and data of the view controller
        [mMocoDrawViewController clearDataAndGraphs];
        
        [sender setTitle: @"Start"];
        return;
    }
    else{
        
        mMocoIsRunning = YES;
        [sender setTitle: @"Stop"];
        
        //+++++ (Re)Initialize the registrator, because regProperties may have changed +++++
        if(mRegistrator == nil)
        {
            NSLog(@"mRegistrator is nil ...");
            mRegistrator = [ [MocoRegistration alloc]	initWithRegistrationProperty:mRegistrationProperty];
        }
        else
        {
            NSLog(@"mRegistrator is NOT nil ...");
            [mRegistrator release]; mRegistrator = nil;
            mRegistrator = [ [MocoRegistration alloc]	initWithRegistrationProperty:mRegistrationProperty];
        }
        
    }
        
    
    if(mRealTimeTCPIPMode)
    {
        [self runRealTimeTCPIPMotionCorrection];
    }
    else
    {
        [self runOfflineMotionCorrection];
    }
    
}



-(void)runRealTimeTCPIPMotionCorrection
{
    //start real time reading of images
    if([mRealTimeTCPIPReadingThread isCancelled])
    {
        mRealTimeTCPIPReadingThread = [[NSThread alloc] initWithTarget:mRTDataLoader selector:@selector(startRealTimeInputOfImageType) object:nil];
        [mRealTimeTCPIPReadingThread start];
    }
    else
    {
        [mRealTimeTCPIPReadingThread start];
    }
    
}

-(void)realTimeTCPIPModeNextDataArrived:(NSNotification*)aNotification
{
    
    NSLog(@"TCPIP: Next Data Arrived!");

    timeval startTimeAlign, endTimeAlign;
    timeval startTimeResample, endTimeResample;
    
    
    //get data to analyse out of notification
    EDDataElement *inputData4D = [aNotification object];
    EDDataElement *inputData3D;
    
    if ([inputData4D getImageSize].timesteps == 1)
    {
        //set reference image
        NSLog(@"TCPIP: First image!");
        [mRegistrator setReferenceImageWithEDDataElement:inputData4D];
        
    }else
    {
        
        //++++ Alignment ++++
        gettimeofday(&startTimeAlign, 0);
        
        NSLog(@"TCPIP: aligning image Nr: %ld", [inputData4D getImageSize].timesteps);
        
        inputData3D = [inputData4D getDataAtTimeStep:[inputData4D getImageSize].timesteps-1];
        
        MocoTransformType::Pointer transform = [mRegistrator alignEDDataElementToReference: inputData3D];
        gettimeofday(&endTimeAlign, 0);
        
        //++++ Send transform parameters to graph plot ++++
        MocoOptimizerType::ParametersType transParameters;
        transParameters = transform->GetParameters();
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
            
            if(mMocoIsRunning)
            {
                [mMocoDrawViewController updateGraphs];
            }
            
        });
    } //endif timesteps == 1

    
    //free memory
    //[inputData3D release]; mInputData3D = nil;
    
    
    
    // [mInputData WriteDataElementToFile:@"/tmp/ourdatafromsimulator.nii"];

    //		NSLog(@"Nr of Timesteps in InputData: %lu", [mInputData getImageSize].timesteps);
    //		if (([mInputData getImageSize].timesteps > startAnalysisAtTimeStep-1 ) && ([mInputData getImageSize].timesteps < [mDesignData mNumberTimesteps])) {
    //			[NSThread detachNewThreadSelector:@selector(processDataThread) toTarget:self withObject:nil];
    //		}

}



-(void)realTimeTCPIPModeLastScanArrived:(NSNotification*)aNotification
{
    NSLog(@"TCPIP: Last Scan Arrived!");
    //	NSTimeInterval ti = [[NSDate date] timeIntervalSince1970];
    //	//FIXME: folder from edl
    //    if ( nil != [aNotification object] ){
    //        NSString *fname =[NSString stringWithFormat:@"/tmp/{subjectName}_{sequenceNumber}_volumes_%d_%d.nii", [[aNotification object] getImageSize].timesteps, ti];
    //        [[aNotification object] WriteDataElementToFile:fname];
    //    }
}


-(void)runOfflineMotionCorrection
{
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
    //    NSString *mocoResultImagesNameBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/realignedImages/mocoApp_data03/data03_img_";
    
    
    //Original Karsten's data01
    NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/data04_vol_dset1.nii";
    int numImages = 542;
    NSString *mocoMovParamsOutFileBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/mocoApp/data04_mocoParams_mocoApp";
    NSString *mocoResultImagesNameBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/realignedImages/mocoApp_data04/data04_img_";
    
    
    //4D zoomedInEPI
    //    NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/data06_zoomedEPI_1_5mm_106_96_30_528_7T.nii";
    //    int numImages = 527;
    //    NSString *mocoMovParamsOutFileBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/mocoApp/data06_mocoParams_mocoApp";
    //    NSString *mocoResultImagesNameBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/realignedImages/mocoApp_data06/data06_img_";
    
    
    //Kid1 Brauer low motion
    //    NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/data07_kid_lowMovement.nii";
    //    int numImages = 584;
    //    NSString *mocoMovParamsOutFileBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/mocoApp/data07_mocoParams_mocoApp";
    //    NSString *mocoResultImagesNameBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/realignedImages/mocoApp_data07/data07_img_";
    
    
    //Kid2 Brauer too much motion
    //    NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/data09_kid_tooMuchMovement.nii";
    //    int numImages = 488;
    //    NSString *mocoMovParamsOutFileBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/mocoApp/data09_mocoParams_mocoApp";
    //    NSString *mocoResultImagesNameBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/realignedImages/mocoApp_data09/data09_img_";
    
    //Kid3 Brauer medium motion
//    NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/data10_kid_mediumMotion_KE2K.nii";
//    int numImages = 539;
//    NSString *mocoMovParamsOutFileBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/mocoApp/data10_mocoParams_mocoApp";
//    NSString *mocoResultImagesNameBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/realignedImages/mocoApp_data10/data10_img_";
    
    //Kid4 Brauer medium motion
//    NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/data11_kid_mediumMotion_SP3K.nii";
//    int numImages = 494;
//    NSString *mocoMovParamsOutFileBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/mocoApp/data11_mocoParams_mocoApp";
//    NSString *mocoResultImagesNameBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/realignedImages/mocoApp_data11/data11_img_";
    
    
    //amynf test - strong trend over time
//    NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/data12_RP1T_amyNF.nii";
//    int numImages = 259;
//    NSString *mocoMovParamsOutFileBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/mocoApp/data12_mocoParams_mocoApp";
//    NSString *mocoResultImagesNameBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/compare/realignedImages/mocoApp_data12/data12_img_";
    
   
//        NSString *file4D = @"/Users/mhollmann/Projekte/Project_MOCOApplication/MocoApplication/testfiles/testData.nii";
//        int numImages = 4;
//        NSString *mocoMovParamsOutFileBase = @"/Users/mhollmann/Projekte/Project_MOCOApplication/MocoApplication/testfiles/testData_mocoParams";
    
    
    
    //++++++++++++++++++++++++++++++++++++
    //++++ Start registration process ++++
    //++++++++++++++++++++++++++++++++++++
    
    //this is done in an async process to unblock the main thread
    dispatch_queue_t imageProcessingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    
    dispatch_async(imageProcessingQueue, ^{
        
        timeval startTimeAlign, endTimeAlign;
        timeval startTimeResample, endTimeResample;
        
        //prepare moco parmaeter logging
        NSString *mocoMovParamsOutFile;
        //determine correct name for moco-param logfile
        if(mRegistrationProperty.RegistrationInterpolationMode == LINEAR)
        {mocoMovParamsOutFile = [mocoMovParamsOutFileBase stringByAppendingString:@"_linear"];}
        else if (mRegistrationProperty.RegistrationInterpolationMode == BSPLINE2)
        {mocoMovParamsOutFile = [mocoMovParamsOutFileBase stringByAppendingString:@"_bspline2"];}
        else if (mRegistrationProperty.RegistrationInterpolationMode == BSPLINE4)
        {mocoMovParamsOutFile = [mocoMovParamsOutFileBase stringByAppendingString:@"_bspline4"];}
        
        if( mRegistrationProperty.MaskImagesForRegistration )
        {mocoMovParamsOutFile = [mocoMovParamsOutFile stringByAppendingString:@"_masked"];}
        
        if(mRegistrationProperty.Smoothing)
        {mocoMovParamsOutFile = [mocoMovParamsOutFile stringByAppendingString: [NSString stringWithFormat: @"_smoothed%i", mRegistrationProperty.SmoothingSigma ]];}
        
        mocoMovParamsOutFile = [mocoMovParamsOutFile stringByAppendingString: [NSString stringWithFormat:@"_it%i.txt", mRegistrationProperty.NumberOfIterations]];
        
        //remove the resulting file if it exists
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:mocoMovParamsOutFile])
        {[fm removeItemAtPath:mocoMovParamsOutFile error:nil];}
        std::string mocoMovParamsOutFileString = [mocoMovParamsOutFile UTF8String];

        MocoDataLogger *mocoLogger = new MocoDataLogger(mocoMovParamsOutFileString, mocoMovParamsOutFileString);
        
        
        
        //MH FIXME: Todo ITK image reader etc...
        
        
        EDDataElement *dataEl4D = [MocoRegistration getEDDataElementFromFile:file4D];
        EDDataElement *refDataEl3D = [dataEl4D getDataAtTimeStep:0];
        
        EDDataElement *resultDataEl;
        EDDataElement *movingDataEl;
        
        //set reference
        [mRegistrator setReferenceImageWithEDDataElement:refDataEl3D];
        
        int i;
        for (i = 1; i<=numImages; i++) {
            
            if(!mMocoIsRunning){
                break;
            }
             
            movingDataEl = [dataEl4D getDataAtTimeStep:i];
            
            //++++ Alignment ++++
            gettimeofday(&startTimeAlign, 0);
            MocoTransformType::Pointer transform = [mRegistrator alignEDDataElementToReference: movingDataEl];
            gettimeofday(&endTimeAlign, 0);
            
            
            //++++ Send transform parameters to graph plot ++++
            MocoOptimizerType::ParametersType transParameters;
            transParameters = transform->GetParameters();
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
            
            //store data in the logger
            mocoLogger->addMocoParams(finalTranslationX, finalTranslationY, finalTranslationZ, rotAngleX, rotAngleY, rotAngleZ);
            
            
            //send the reload to the main thread
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                if(mMocoIsRunning)
                {
                    [mMocoDrawViewController updateGraphs];
                }
            });
            
              //++++ Resampling ++++
            gettimeofday(&startTimeResample, 0);
            resultDataEl = [mRegistrator resampleMovingEDDataElement:movingDataEl withTransform:transform];
            gettimeofday(&endTimeResample, 0);
            
              /*
            //++++ Write result image ++++
            NSString *resultFilename = [mocoResultImagesNameBase stringByAppendingString:[NSString stringWithFormat: @"%.4i",i ]];
            resultFilename = [resultFilename stringByAppendingString:@".nii"];
            //remove the resulting file if it exists
            NSFileManager *fmri = [NSFileManager defaultManager];
            if ([fmri fileExistsAtPath:resultFilename])
            {
                [fmri removeItemAtPath:resultFilename error:nil];
            }
            [resultDataEl WriteDataElementToFile:resultFilename];
            if (mRegistrationProperty.LoggingLevel > 1){
                NSLog(@"Written aligned image to: %@", resultFilename);
            }
            */
            
            
            if (mRegistrationProperty.LoggingLevel > 1){
                
                NSLog(@"**** VIEW CONTROLLER ****");
                NSLog(@"transX of transform: %f ", finalTranslationX);
                NSLog(@"transY of transform: %f ", finalTranslationY);
                NSLog(@"transZ of transform: %f ", finalTranslationZ);
                NSLog(@"rotX of transform: %f ", rotAngleX);
                NSLog(@"rotY of transform: %f ", rotAngleY);
                NSLog(@"rotZ of transform: %f ", rotAngleZ);
                
                ; std::cout << "Time needed for alignment: " << [self getTimeDifference:startTimeAlign endTime:endTimeAlign] << " s" << std::endl;
            }
            
        }//endfor
        
        
        
        
        //*****************************************
        //****** Write params to txt file *********
        //*****************************************
        mocoLogger->dumpMocoParamsToLogfile();
        if (mRegistrationProperty.LoggingLevel > 0)
        {
            NSLog(@"Written mocoParams to file: %@", mocoMovParamsOutFile);
        }
        delete mocoLogger;
         
    });//end dispatch async
} // end runOfflineMotionCorrection




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
