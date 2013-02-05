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
@synthesize mReferenceImagePullDown;
@synthesize mInputSourcePullDown;
@synthesize mStartButton;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    //prepare members
    mRealTimeTCPIPMode = YES;
    mMocoIsRunning     = NO;
    mRegistrator       = nil;
    
    //++++++++++++++++++++++++++++++++
    //+++++++ Initialize logging +++++
    //++++++++++++++++++++++++++++++++
    mMocoDataLogger = MocoDataLogger::getInstance();
    
    //the standard output path and name base
    mMocoResultImagesNameBase  = @"/tmp/image_mocoAppExport_MOCO_";
    mMocoParametersOutNameBase = @"/tmp/mocoParams_mocoApp";
    
    
    //set the content to the viewControllers' view
    mMocoDrawViewController = [[MocoDrawViewController alloc] initWithNibName:@"MocoDrawView" bundle:nil];
    [mMocoDrawViewController loadView];
    

    //replace the apps drawView with the mocoDrawView and set correct size
    NSView *drawView = [mMocoDrawViewController view];
    NSRect cvFrame = [mAppGraphView frame];
    [[self.window contentView] replaceSubview:mAppGraphView with:drawView];
    [drawView setFrame:cvFrame];
    
    //enable start button judt if everything worked fine
    [mStartButton setEnabled:NO];
    
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
        mMocoDataLogger->addMocoAppLogentry(string("Errror: Could not read configuration from plist file (file not found)."));
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
        NSLog(@"Warning: Could not read plist defaultRegParams.plist (using standard): %@, format: %lu", errDescr, format);
        mMocoDataLogger->addMocoAppLogentry(string("Warning: Could not read plist defaultRegParams.plist (using standard)."));
    }else{
        
        //assign params from plist
        mRegistrationProperty.LoggingLevel              = [[arrayFromPlist objectForKey:@"LoggingLevel"] unsignedIntegerValue];
        mRegistrationProperty.NumberOfThreads           = [[arrayFromPlist objectForKey:@"NumberOfThreads"] unsignedIntegerValue];
        mRegistrationProperty.Smoothing                 = [[arrayFromPlist objectForKey:@"Smoothing"] boolValue];
        mRegistrationProperty.SmoothingSigma            = [[arrayFromPlist objectForKey:@"SmoothingSigma"] unsignedIntegerValue];
        mRegistrationProperty.MaskImagesForRegistration = [[arrayFromPlist objectForKey:@"MaskImagesForRegistration"] boolValue];
        mRegistrationProperty.UseBestFoundParameters    = [[arrayFromPlist objectForKey:@"UseBestFoundParameters"] boolValue];
        mRegistrationProperty.NumberOfIterations        = [[arrayFromPlist objectForKey:@"NumberOfIterations"] unsignedIntegerValue];
        mMocoResultImagesNameBase                       = [[arrayFromPlist objectForKey:@"ResampleOutputBase"] stringByExpandingTildeInPath];
        mMocoParametersOutNameBase                      = [[arrayFromPlist objectForKey:@"MocoParamsOutputBase"] stringByExpandingTildeInPath];
        mMocoDataLogger->setAppLogFileName([[[arrayFromPlist objectForKey:@"MocoAppLogfileName"] stringByExpandingTildeInPath] UTF8String]);
    }
    [mMocoResultImagesNameBase retain];
    [mMocoParametersOutNameBase retain];
    
    
    //check if there is write access to defined directories
    NSFileManager *fm = [NSFileManager defaultManager];
    if ( ![fm createFileAtPath:[mMocoResultImagesNameBase stringByAppendingString:@".tmp"] contents:nil attributes:nil] )
    {
        NSLog(@"Error: Seems as path of result file base (coming from default plist file) does not exist, or no write permission for: %@", mMocoResultImagesNameBase);
        mMocoDataLogger->addMocoAppLogentry(string("Error: Seems as path of result file base (coming from default plist file) does not exist, or having no write permission."));
        return;
    }else
    {
        [fm removeItemAtPath:[mMocoResultImagesNameBase stringByAppendingString:@".tmp"] error:nil];
    }
    if ( ![fm createFileAtPath:[mMocoParametersOutNameBase stringByAppendingString:@".tmp"] contents:nil attributes:nil] )
    {
        NSLog(@"Error: Seems as path of moco param file base (coming from default plist file) does not exist, or there is no write permission for: %@", mMocoParametersOutNameBase);
        mMocoDataLogger->addMocoAppLogentry(string("Error: Seems as path of moco param file base (coming from default plist file) does not exist, or having no write permission."));
        return;
    }else
    {
        [fm removeItemAtPath:[mMocoParametersOutNameBase stringByAppendingString:@".tmp"] error:nil];
    }

    
    if ( mRegistrationProperty.LoggingLevel > 2 ) {
        std::cout << "Params read from plist:   " << std::endl;
        std::cout << "LoggingLevel:             " << mRegistrationProperty.LoggingLevel << std::endl;
        std::cout << "NumberOfThreads:          " << mRegistrationProperty.NumberOfThreads << std::endl;
        std::cout << "Smoothing:                " << mRegistrationProperty.Smoothing << std::endl;
        std::cout << "SmoothingSigma:           " << mRegistrationProperty.SmoothingSigma << std::endl;
        std::cout << "MaskImagesForRegistration:" << mRegistrationProperty.MaskImagesForRegistration << std::endl;
        std::cout << "UseBestFoundParameters:   " << mRegistrationProperty.UseBestFoundParameters << std::endl;
        NSLog(@"OutfileBase: %@", mMocoResultImagesNameBase);
        NSLog(@"OutParamBase: %@", mMocoParametersOutNameBase);
    }
           
    //this is the standard
    [mRegistrationProperty setRegistrationParameters:1000.0 MaxStep:0.019 MinStep:0.00001];
    
    mRegistrationProperty.RegistrationInterpolationMode = LINEAR;
    //mRegistrationProperty.RegistrationInterpolationMode = BSPLINE2;
    
    mRegistrationProperty.ResamplingInterpolationMode   = BSPLINE4;
    mRegistrationProperty.SmoothingKernelWidth  = 32;
        
    
    //+++++++++++++++++++++++++++++++++++++++++
    //+++++++++ Prepare GUI components ++++++++
    //+++++++++++++++++++++++++++++++++++++++++
    
    //prepare input source pull down
    [mInputSourcePullDown removeAllItems];
    [mInputSourcePullDown addItemWithTitle:@""];
    [mInputSourcePullDown addItemWithTitle:@"Online TCP/IP input"];
    [mInputSourcePullDown addItemWithTitle:@"Browse for file ..."];
    [mInputSourcePullDown setTitle: @"Online TCP/IP input"];
    

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
    
    
    //prepare reference image pull down
    [mReferenceImagePullDown removeAllItems];
    [mReferenceImagePullDown addItemWithTitle:@""];
    [mReferenceImagePullDown addItemWithTitle:@"First incoming image"];
    [mReferenceImagePullDown addItemWithTitle:@"Browse for file ..."];
    [mReferenceImagePullDown setTitle: @"First incoming image"];
    
    
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
    
    
    [mStartButton setEnabled:YES];
    
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
        mRegistrationProperty.Smoothing = YES;
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

    if(mMocoIsRunning){ //STOPPING
        
        mMocoIsRunning = NO;
        
        if(mRealTimeTCPIPMode)
        {
            NSLog(@"Stopping Real-Time Moco...");
            mMocoDataLogger->addMocoAppLogentry(string("Stopping Real-Time Moco..."));
            [mRealTimeTCPIPReadingThread cancel];
            mMocoDataLogger->dumpMocoParamsToLogfile();
         }
            
        //clear view and data of the view controller
        [mMocoDrawViewController clearDataAndGraphs];
        
        //dump log infos, because these may be lost otherwise
        mMocoDataLogger->dumpMocoAppLogsToLogfile();
        
        //set all other gui compononts to active again
        [mNumIterationsPullDown setEnabled: YES];
        [mSmoothKernelPullDown setEnabled: YES];
        //[mMaskImagesPullDown setEnabled: YES];
        [mReferenceImagePullDown setEnabled: YES];
        [mInputSourcePullDown setEnabled: YES];
        
        [sender setTitle: @"Start"];
        return;
    }
    else // STARTING
    {
        mMocoIsRunning = YES;
        [sender setTitle: @"Stop"];
        
        
        //set all other gui compononts to inactive
        [mNumIterationsPullDown setEnabled: NO];
        [mSmoothKernelPullDown setEnabled: NO];
        //[mMaskImagesPullDown setEnabled: NO];
        [mReferenceImagePullDown setEnabled: NO];
        [mInputSourcePullDown setEnabled: NO];
        
        
        //+++++ (Re)Initialize the registrator, because regProperties may have changed +++++
        if(mRegistrator == nil)
        {
            mRegistrator = [ [MocoRegistration alloc]	initWithRegistrationProperty:mRegistrationProperty];
        }
        else
        {
            [mRegistrator release]; mRegistrator = nil;
            mRegistrator = [ [MocoRegistration alloc]	initWithRegistrationProperty:mRegistrationProperty];
        }
    }
        
    
    if(mRealTimeTCPIPMode)
    {
        [self runRealTimeTCPIPMotionCorrection];
        
        //set moco params logfile
        mMocoDataLogger->setParamsLogFileName([[mMocoParametersOutNameBase stringByAppendingString:@".txt"] UTF8String]);
    }
    else
    {
        [self runOfflineMotionCorrection];
    }
}


- (IBAction)setReferenceImageByPulldown:(NSPopUpButton *)sender {
    
    NSString *valSelected = [sender titleOfSelectedItem];
    
    if([valSelected isEqualToString:@"Browse for file ..."])
    {
        
        // Create an modal open dialog
        NSOpenPanel* openDlg = [NSOpenPanel openPanel];
        [openDlg setCanChooseFiles:YES];
        [openDlg setCanChooseDirectories:NO];
        
        NSArray  * fileTypes = [NSArray arrayWithObjects:@"nii",nil];
        
        [openDlg setAllowedFileTypes:fileTypes];
        
        if ( [openDlg runModal ] == NSOKButton )
        {
            NSArray* files = [openDlg URLs];
            NSString* fileName = [[files objectAtIndex:0] path];
            [sender setToolTip:fileName];
            [sender setTitle: fileName];
        }
    }
    else
    {
        [sender setToolTip: @""];
        [sender setTitle: valSelected];
    }
}

- (IBAction)setInputSourceByPullDown:(id)sender {
    
    NSString *valSelected = [sender titleOfSelectedItem];
    
    if([valSelected isEqualToString:@"Browse for file ..."])
    {
        
        // Create an modal open dialog
        NSOpenPanel* openDlg = [NSOpenPanel openPanel];
        [openDlg setCanChooseFiles:YES];
        [openDlg setCanChooseDirectories:NO];
        
        NSArray  * fileTypes = [NSArray arrayWithObjects:@"nii",nil];
        [openDlg setAllowedFileTypes:fileTypes];
        
        if ( [openDlg runModal ] == NSOKButton )
        {
            NSArray* files = [openDlg URLs];
            NSString* fileName = [[files objectAtIndex:0] path];
            [sender setToolTip:fileName];
            [sender setTitle: fileName];
            mRealTimeTCPIPMode = NO;
        }
    }
    else
    {
        [sender setToolTip: @""];
        [sender setTitle: valSelected];
        mRealTimeTCPIPMode = YES;
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
    
    @try {
        
        if (mRegistrationProperty.LoggingLevel > 1)
        {
             mMocoDataLogger->addMocoAppLogentry(string("TCPIP: data arrived ..."));
        }
       
        timeval startTimeAlign, endTimeAlign;
        timeval startTimeResample, endTimeResample;
        
        
        //get data to analyse out of notification
        EDDataElement *inputDataEl4D = [aNotification object];
        EDDataElement *movingDataEl;
        EDDataElement *resultDataEl;
        
        
        //if the first scan is coming in we have to set the reference image
        //either to selected external or to first scan
        bool alignToExternalReference;
        if( [inputDataEl4D getImageSize].timesteps == 1 )
        {
            //set correct reference image
            NSString *valSelected = [mReferenceImagePullDown title];
            if([valSelected isEqualToString:@"First incoming image"])
            {
                [mRegistrator setReferenceImageWithEDDataElement:inputDataEl4D];;
                alignToExternalReference  = NO;
            }else{
                NSLog(@"Reference image: %@", valSelected);
                EDDataElement *refDataEl3D = [MocoRegistration getEDDataElementFromFile:valSelected];
                [mRegistrator setReferenceImageWithEDDataElement:refDataEl3D];
                alignToExternalReference = YES;
            }
        }
        
        
        //+++++++++++++++++++
        //++++ Alignment ++++
        //+++++++++++++++++++
        MocoTransformType::Pointer transform;
        
        double rotAngleX            = 0;
        double rotAngleY            = 0;
        double rotAngleZ            = 0;
        double finalTranslationX    = 0;
        double finalTranslationY    = 0;
        double finalTranslationZ    = 0;
        
        movingDataEl = [inputDataEl4D getDataAtTimeStep:[inputDataEl4D getImageSize].timesteps-1];
        
        if( [inputDataEl4D getImageSize].timesteps > 1 || alignToExternalReference )
        {
            gettimeofday(&startTimeAlign, 0);
            transform = [mRegistrator alignEDDataElementToReference: movingDataEl];
            gettimeofday(&endTimeAlign, 0);
            
            //++++ Send transform parameters to graph plot ++++
            MocoOptimizerType::ParametersType transParameters;
            transParameters = transform->GetParameters();
            MocoTransformType::OffsetType offset = transform->GetOffset();
            MocoVectorType versor_axis = transform->GetVersor().GetAxis();
            double versor_angle = transform->GetVersor().GetAngle();
            rotAngleX              = 180/M_PI * versor_axis[0] * versor_angle;
            rotAngleY              = 180/M_PI * versor_axis[1] * versor_angle;
            rotAngleZ              = 180/M_PI * versor_axis[2] * versor_angle;
            finalTranslationX    = offset[0];
            finalTranslationY    = offset[1];
            finalTranslationZ    = offset[2];
            
        } //endif timesteps > 1 
       
            
        [mMocoDrawViewController addValuesToGraphs:finalTranslationX TransY:finalTranslationY TransZ:finalTranslationZ RotX:rotAngleX RotY:rotAngleY RotZ:rotAngleZ];
                
        //send the reload to the main thread
        dispatch_sync(dispatch_get_main_queue(), ^{
                
            if(mMocoIsRunning)
            {
                [mMocoDrawViewController updateGraphs];
            }
        });

        
        //++++++++++++++++++++
        //++++ Resampling ++++
        //++++++++++++++++++++
        //do resampling just for n>0 or always if an external reference image was given
        
        gettimeofday(&startTimeResample, 0);
        if([inputDataEl4D getImageSize].timesteps > 1 || alignToExternalReference)
        {
            resultDataEl = [mRegistrator resampleMovingEDDataElement:movingDataEl withTransform:transform];
            
            //MH FIXME: a workaround because header params are not correctly copied by itkAdapter
            NSArray *propsToCopy = [NSArray arrayWithObjects:
                                    @"voxelsize",
                                    @"rowVec",
                                    @"sliceVec",
                                    @"columnVec",
                                    @"indexOrigin",
                                    nil];
            
            [resultDataEl copyProps:propsToCopy fromDataElement:movingDataEl];
        }
        else
        {
            resultDataEl = movingDataEl;
        }
        gettimeofday(&endTimeResample, 0);
        
        //set sequence description
        NSDictionary *dic = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects:@"mocoAppExport", nil]
                                                        forKeys: [NSArray arrayWithObjects:@"sequenceDescription", nil] ];
        [resultDataEl setProps:dic];
        
        
        //++++++++++++++++++++++++++++
        //++++ Write result image ++++
        //++++++++++++++++++++++++++++
        NSString *resultFilename = [mMocoResultImagesNameBase stringByAppendingString:[NSString stringWithFormat: @"%.4li",[inputDataEl4D getImageSize].timesteps ]];
        resultFilename = [resultFilename stringByAppendingString:@".nii"];
        //remove the resulting file if it exists
        NSFileManager *fmri = [NSFileManager defaultManager];
        if ([fmri fileExistsAtPath:resultFilename])
        {
            [fmri removeItemAtPath:resultFilename error:nil];
        }
        [resultDataEl WriteDataElementToFile:resultFilename];
        
        
        //store moco parameters in logger
        mMocoDataLogger->addMocoParams(finalTranslationX, finalTranslationY, finalTranslationZ, rotAngleX, rotAngleY, rotAngleZ);
        
        if (mRegistrationProperty.LoggingLevel > 1)
        {
            NSLog(@"Written aligned image to: %@", resultFilename);
            mMocoDataLogger->addMocoAppLogentry(string("Written aligned image to: ")+[resultFilename UTF8String]);

            NSLog(@"Final Parameters:");
            NSLog(@"transX of transform: %f ", finalTranslationX);
            NSLog(@"transY of transform: %f ", finalTranslationY);
            NSLog(@"transZ of transform: %f ", finalTranslationZ);
            NSLog(@"rotX of transform: %f ", rotAngleX);
            NSLog(@"rotY of transform: %f ", rotAngleY);
            NSLog(@"rotZ of transform: %f ", rotAngleZ);
            
            NSLog(@"Time needed for alignment: %f ", [self getTimeDifference:startTimeAlign endTime:endTimeAlign]);
            NSLog(@"Time needed overall:       %f ", [self getTimeDifference:startTimeAlign endTime:endTimeResample]);
        }
        
        if (mRegistrationProperty.LoggingLevel > 2){
            
            //++++ Write original image ++++
            NSString *resultFilename = [mMocoResultImagesNameBase stringByAppendingString:[NSString stringWithFormat: @"orig_%.4li",[inputDataEl4D getImageSize].timesteps ]];
            resultFilename = [resultFilename stringByAppendingString:@".nii"];
            //remove the resulting file if it exists
            NSFileManager *fmri = [NSFileManager defaultManager];
            if ([fmri fileExistsAtPath:resultFilename])
            {
                [fmri removeItemAtPath:resultFilename error:nil];
            }
            [movingDataEl WriteDataElementToFile:resultFilename];
        }
        
    }
    @catch (NSException *exception) {
        
        NSMutableDictionary *errorDict = [NSMutableDictionary dictionary];
        
        [errorDict setObject:[NSString stringWithFormat:@"Error: %@.", [exception reason]] forKey:NSAppleScriptErrorMessage];
        string exString = string("Exception: ")+[[exception reason] UTF8String];
        mMocoDataLogger->addMocoAppLogentry(exString);
        
        //dump logfile in case of an exception
        mMocoDataLogger->dumpMocoAppLogsToLogfile();
    }
}



-(void)realTimeTCPIPModeLastScanArrived:(NSNotification*)aNotification
{
    NSLog(@"TCPIP: Last Scan Arrived!");
    mMocoDataLogger->addMocoAppLogentry(string("Last scan arrived. "));
}


-(void)runOfflineMotionCorrection
{
    
    //set input image - just nifti 4D at the moment
    NSString *file4D;
    NSString *valSelected = [mInputSourcePullDown title];
    if([valSelected isEqualToString:@"Online TCP/IP input"])
    {
        NSLog(@"Offline moco can not run in TCP/IP input mode. Please check GUI settings.");
        return;
        
    }else{
        NSLog(@"Input image: %@", valSelected);
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm isReadableFileAtPath:valSelected])
        {
            NSLog(@"Did not find input image: %@", valSelected);
            mMocoDataLogger->addMocoAppLogentry(string("Did not find input image: ")+[valSelected UTF8String]);
            return;
        }
        file4D = valSelected;
    }
    

    //++++++++++++++++++++++++++++++++++++
    //++++ Start registration process ++++
    //++++++++++++++++++++++++++++++++++++
    
    //this is done in an async process to unblock the main thread
    dispatch_queue_t imageProcessingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    
    dispatch_async(imageProcessingQueue, ^{
        
        timeval startTimeAlign, endTimeAlign;
        timeval startTimeResample, endTimeResample;
         
        
        //+++ prepare file name for moco parameter logging +++
        NSString *mocoMovParamsOutFile;
        
        //add the first 6 chars from filename
        NSString* fName = [[file4D lastPathComponent] stringByDeletingPathExtension];
        mocoMovParamsOutFile = [mMocoParametersOutNameBase stringByAppendingString:@"_" ];
        mocoMovParamsOutFile = [mocoMovParamsOutFile stringByAppendingString:[fName substringWithRange:NSMakeRange(0, 6)] ];

        //determine correct name for moco-param logfile
        if(mRegistrationProperty.RegistrationInterpolationMode == LINEAR)
        {mocoMovParamsOutFile = [mocoMovParamsOutFile stringByAppendingString:@"_linear"];}
        else if (mRegistrationProperty.RegistrationInterpolationMode == BSPLINE2)
        {mocoMovParamsOutFile = [mocoMovParamsOutFile stringByAppendingString:@"_bspline2"];}
        else if (mRegistrationProperty.RegistrationInterpolationMode == BSPLINE4)
        {mocoMovParamsOutFile = [mocoMovParamsOutFile stringByAppendingString:@"_bspline4"];}
        if( mRegistrationProperty.MaskImagesForRegistration )
        {mocoMovParamsOutFile = [mocoMovParamsOutFile stringByAppendingString:@"_masked"];}
        if(mRegistrationProperty.Smoothing)
        {mocoMovParamsOutFile = [mocoMovParamsOutFile stringByAppendingString: [NSString stringWithFormat: @"_smoothed%i", mRegistrationProperty.SmoothingSigma ]];}
        mocoMovParamsOutFile = [mocoMovParamsOutFile stringByAppendingString: [NSString stringWithFormat:@"_it%i.txt", mRegistrationProperty.NumberOfIterations]];
        NSLog(@"Out: %@",mocoMovParamsOutFile);
        mMocoDataLogger->setParamsLogFileName([mocoMovParamsOutFile UTF8String]);
        
        
        
        EDDataElement *resultDataEl;
        EDDataElement *movingDataEl;
        bool alignToExternalReference;
        
        //load the 4D image
        EDDataElement *dataEl4D = [MocoRegistration getEDDataElementFromFile:file4D];
        
        //set reference image 
        NSString *valSelected = [mReferenceImagePullDown title];
        if([valSelected isEqualToString:@"First incoming image"])
        {
            NSLog(@"Reference image set to first one!");
            EDDataElement *refDataEl3D = [dataEl4D getDataAtTimeStep:0];
            [mRegistrator setReferenceImageWithEDDataElement:refDataEl3D];
            alignToExternalReference  = NO;
            
        }else{
            
            NSLog(@"Reference image: %@", valSelected);
            EDDataElement *refDataEl3D = [MocoRegistration getEDDataElementFromFile:valSelected];
            [mRegistrator setReferenceImageWithEDDataElement:refDataEl3D];
            alignToExternalReference = YES;
        }
        
        if (mRegistrationProperty.LoggingLevel > 1){
            NSLog(@"Starting alignment ...");
            mMocoDataLogger->addMocoAppLogentry(string("Starting alignment for data: ")+[file4D UTF8String]);
        }
        
        int i;
        for (i = 0; i<=[dataEl4D getImageSize].timesteps-1; i++) {
            
            if(!mMocoIsRunning){
                break;
            }
             
            MocoTransformType::Pointer transform;
            
            double rotAngleX            = 0;
            double rotAngleY            = 0;
            double rotAngleZ            = 0;
            double finalTranslationX    = 0;
            double finalTranslationY    = 0;
            double finalTranslationZ    = 0;
            
            movingDataEl = [dataEl4D getDataAtTimeStep:i];
             
            //do alignment just for n>0
            if(i > 0 || alignToExternalReference)
            {
            
                //++++ Alignment ++++
                gettimeofday(&startTimeAlign, 0);
                transform = [mRegistrator alignEDDataElementToReference: movingDataEl];
                gettimeofday(&endTimeAlign, 0);
            
            
                MocoOptimizerType::ParametersType transParameters;
                transParameters = transform->GetParameters();
                MocoTransformType::OffsetType offset = transform->GetOffset();
                MocoVectorType versor_axis = transform->GetVersor().GetAxis();
                double versor_angle = transform->GetVersor().GetAngle();
                rotAngleX              = 180/M_PI * versor_axis[0] * versor_angle;
                rotAngleY              = 180/M_PI * versor_axis[1] * versor_angle;
                rotAngleZ              = 180/M_PI * versor_axis[2] * versor_angle;
                finalTranslationX    = offset[0];
                finalTranslationY    = offset[1];
                finalTranslationZ    = offset[2];
            }
            
            
            //++++ Send transform parameters to graph plot ++++
            [mMocoDrawViewController addValuesToGraphs:finalTranslationX TransY:finalTranslationY TransZ:finalTranslationZ RotX:rotAngleX RotY:rotAngleY RotZ:rotAngleZ];
            
            //store data in the logger
            mMocoDataLogger->addMocoParams(finalTranslationX, finalTranslationY, finalTranslationZ, rotAngleX, rotAngleY, rotAngleZ);
            
            
            //send the reload to the main thread
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                if(mMocoIsRunning)
                {
                    [mMocoDrawViewController updateGraphs];
                }
            });
            
            
            //++++++++++++++++++++
            //++++ Resampling ++++
            //++++++++++++++++++++
            //do resampling just for n>0 or always if an external reference image was given
            gettimeofday(&startTimeResample, 0);
            if(i >  0 || alignToExternalReference)
            {
                resultDataEl = [mRegistrator resampleMovingEDDataElement:movingDataEl withTransform:transform];
                
                //MH FIXME: a workaround because header params are not correctly copied by itkAdapter
                 NSArray *propsToCopy = [NSArray arrayWithObjects:
                                        @"voxelsize",
                                        @"rowVec",
                                        @"sliceVec",
                                        @"columnVec",
                                        @"indexOrigin",
                                        nil];
                
                [resultDataEl copyProps:propsToCopy fromDataElement:movingDataEl];
                 
            }
            else
            {
                resultDataEl = movingDataEl;
            }
            gettimeofday(&endTimeResample, 0);
            
            
            //set sequence description
            NSDictionary *dic = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects:@"mocoAppExport", nil]
                                                            forKeys: [NSArray arrayWithObjects:@"sequenceDescription", nil] ];
            [resultDataEl setProps:dic];
            
            
            //++++ Write result image ++++
            NSString *resultFilename = [mMocoResultImagesNameBase stringByAppendingString:[NSString stringWithFormat: @"%.4i",i+1 ]];
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
                mMocoDataLogger->addMocoAppLogentry(string("Written aligned image to: ")+[resultFilename UTF8String]);
            }
            
            if (mRegistrationProperty.LoggingLevel > 1){
                
                NSLog(@"**** VIEW CONTROLLER ****");
                NSLog(@"transX of transform: %f ", finalTranslationX);
                NSLog(@"transY of transform: %f ", finalTranslationY);
                NSLog(@"transZ of transform: %f ", finalTranslationZ);
                NSLog(@"rotX of transform: %f ", rotAngleX);
                NSLog(@"rotY of transform: %f ", rotAngleY);
                NSLog(@"rotZ of transform: %f ", rotAngleZ);
                
                NSLog(@"Time needed for alignment: %f ", [self getTimeDifference:startTimeAlign endTime:endTimeAlign]);
                NSLog(@"Time needed overall:       %f ", [self getTimeDifference:startTimeAlign endTime:endTimeResample]);
            }
            
        }//endfor
        
        //+++++++++++++++++++++++++++++++++++++++++
        //++++++ Write params to log file +++++++++
        //+++++++++++++++++++++++++++++++++++++++++
        mMocoDataLogger->dumpMocoParamsToLogfile();
        if (mRegistrationProperty.LoggingLevel > 0)
        {
            NSLog(@"Written mocoParams to file: %@", mocoMovParamsOutFile);
            mMocoDataLogger->addMocoAppLogentry(string("Written moco parameters to: ")+[mocoMovParamsOutFile UTF8String]);
        }
        
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


-(void) applicationWillTerminate:(NSNotification *)notification
{
    
    //dump logfile in case of an exception
    mMocoDataLogger->dumpMocoAppLogsToLogfile();


}


@end
