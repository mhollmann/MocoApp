//
//  EDDataElementRealTimeLoader.m
//  BARTApplication
//
//  Created by Torsten Schlumm on 3/22/11.
//  Copyright 2011 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//



#import "DataStorage/io_factory.hpp"
#import "DataStorage/image.hpp"
#import "EDDataElementIsis.h"
#import "BARTNotifications.h"
#import "EDDataElementRealTimeLoader.h"

@interface EDDataElementRealTimeLoader ()

-(void)loadNextVolumeOfImageType:(enum ImageType)imgType;
-(BOOL)isImage:(isis::data::Image)img ofImageType:(enum ImageType)imgType;
@end


@implementation EDDataElementRealTimeLoader

-(id)init
{
	//self = [super init];
	//arrayLoadedDataElements = [[NSMutableArray alloc] initWithCapacity:1];
	//[arrayLoadedDataElements autorelease];
	mDataElementInterest = nil;
	return self;
}

-(void)startRealTimeInputOfImageType
{
	NSLog(@"startRealTimeInputOfImageType START");
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    BARTImageSize *sz = [[BARTImageSize alloc] init];
    
    //MH FIXME: changed to process non-moco data
	//mDataElementInterest = [[EDDataElementIsisRealTime alloc] initEmptyWithSize:sz ofImageType:IMAGE_MOCO];
	//mDataElementRest     = [[EDDataElementIsisRealTime alloc] initEmptyWithSize:sz ofImageType:IMAGE_FCTDATA];
    mDataElementInterest = [[EDDataElementIsisRealTime alloc] initEmptyWithSize:sz ofImageType:IMAGE_FCTDATA];
	mDataElementRest     = [[EDDataElementIsisRealTime alloc] initEmptyWithSize:sz ofImageType:IMAGE_MOCO];
    
    [sz release];
	
	[[NSThread currentThread] setThreadPriority:1.0];
	while (![[NSThread currentThread] isCancelled]) {
		
        //MH FIXME: changed to process non-moco data
        //[self loadNextVolumeOfImageType:IMAGE_MOCO];
	    [self loadNextVolumeOfImageType:IMAGE_FCTDATA];
    }
	NSLog(@"startRealTimeInputOfImageType END");

	[pool drain];
}

-(void)dealloc
{
    [mDataElementInterest release];
    [mDataElementRest release];
    [super dealloc];
}


-(void)loadNextVolumeOfImageType:(enum ImageType)imgType
{
	isis::data::enableLog<isis::util::DefaultMsgPrint>( isis::warning );
	
    NSLog(@"loadNextVolumeOfImageType START");

	std::list<isis::data::Image> tempList = isis::data::IOFactory::load("", ".tcpip", "");
    
    if (0 == tempList.size() && (YES == [[NSThread currentThread] isExecuting])){
        [[NSThread currentThread] cancel];
        NSLog(@"cancel thread now");
        if (1 < [mDataElementInterest getImageSize].timesteps){
            [[NSNotificationCenter defaultCenter] postNotificationName:BARTScannerSentTerminusNotification object:mDataElementInterest];
        }
        else{
            [[NSNotificationCenter defaultCenter] postNotificationName:BARTScannerSentTerminusNotification object:nil];
        }
		
        //TODO : decide by isEmpty()
        if (1 < [mDataElementRest getImageSize].timesteps){
            [mDataElementRest WriteDataElementToFile:@"/tmp/TheNotUsedDataElement.nii"];
        }
        return;
    }
	
    std::list<isis::data::Image>::const_iterator it ;
    for (it = tempList.begin(); it != tempList.end(); it++) {
		if (TRUE == [self isImage:*it ofImageType:imgType]){
            [mDataElementInterest appendVolume:*it];
			[[NSNotificationCenter defaultCenter] postNotificationName:BARTDidLoadNextDataNotification object:mDataElementInterest];
			
        }
		else {
			// TODO what to do with other data
			[mDataElementRest appendVolume:*it];
        }

		
    }
	
}




-(BOOL)isImage:(isis::data::Image)img ofImageType:(enum ImageType)imgType
{
	std::string seqDescr;
	u_int16_t segNr = img.getPropertyAs<u_int16_t>("sequenceNumber");
    std::string imageType = img.getPropertyAs<std::string>("DICOM/ImageType");
    size_t pos = std::string::npos;
	switch (imgType) {
		case IMAGE_MOCO:
			//seqDescr = img.getPropertyAs<std::string>("sequenceDescription");
			pos = imageType.find("MOCO\\WAS_MOSAIC");
			if ( ( static_cast<u_int16_t>(10000) < segNr)
                && ( std::string::npos != pos ) )
            {
				return TRUE;
            }
			return FALSE;
			break;
		case IMAGE_FCTDATA:
			pos = imageType.find("WAS_MOSAIC");
			if ( ( static_cast<u_int16_t>(10000) > segNr)
                && ( std::string::npos != pos ) )
            {
				return TRUE;
            }
			return FALSE;
			break;
		case IMAGE_ANADATA:
			break;
		case IMAGE_TMAP:
			
			break;
		case IMAGE_BETAS:
			
			break;


		default:
			return FALSE;
			break;
	}
	return FALSE;
}

@end
