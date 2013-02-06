//
//  EDDataElement.m
//  BARTCommandLine
//
//  Created by Lydia Hellrung on 10/29/09.
//  Copyright 2009 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import "EDDataElement.h"
//#import "EDDataElementVI.h"
#import "EDDataElementIsis.h"
#import "EDDataElementIsisRealTime.h"
//#import <Common/itkImage.h>

/**************************************************
 BARTImageSize is a small class for better handling of the here mostly needed 4-value size
 **************************************************/

@implementation BARTImageSize

@synthesize rows;
@synthesize columns;
@synthesize slices;
@synthesize timesteps;

-(id)init
{
	self = [super init];
	rows = 1;
	columns = 1;
	slices = 1;
	timesteps = 1;
	return self;
}

-(id)initWithRows:(size_t)r andCols:(size_t)c andSlices:(size_t)s andTimesteps:(size_t)t
{
    self = [super init];
	rows = r;
	columns = c;
	slices = s;
	timesteps = t;
	return self;
}

-(id)copyWithZone:(NSZone *)zone
{
	BARTImageSize *newImageSize = [[BARTImageSize allocWithZone: zone] init];
	newImageSize.rows = rows;
	newImageSize.columns = columns;
	newImageSize.slices = slices;
	newImageSize.timesteps = timesteps;
	
	return newImageSize;
}

@end


/**************************************************
 EDDataElement 
 **************************************************/


@implementation EDDataElement

@synthesize mImageType;
@synthesize mImageSize;
@synthesize justatest;



-(id)initWithDataFile:(NSString*)path andSuffix:(NSString*)suffix andDialect:(NSString*)dialect ofImageType:(enum ImageType)iType
{    
	NSFileManager *fm = [[NSFileManager alloc] init];
	if ( NO == [fm fileExistsAtPath:path]){
        [fm release];
		NSLog(@"No file to load");
		return nil;
	}
	
    self = [[EDDataElementIsis alloc] initWithFile:path andSuffix:suffix andDialect:dialect ofImageType:iType];
    [fm release];
    return self;
}

-(id)initEmptyWithSize:(BARTImageSize*)s  ofImageType:(enum ImageType)iType
{
	self = [[EDDataElementIsis alloc] initEmptyWithSize:s ofImageType:(enum ImageType)iType];
    return self;
	
}

-(id)initForRealTimeTCPIPWithSize:(BARTImageSize*)s ofImageType:(enum ImageType)iType
{
	self = [[EDDataElementIsisRealTime alloc] initEmptyWithSize:s ofImageType:(enum ImageType)iType];
    return self;
	
}

-(void)dealloc
{
    if (self->mImageSize != nil) {
        [mImageSize release];
    }
    [super dealloc];
}

-(BARTImageSize*)getImageSize
{
	//NSLog(@"%@", mImageSize);
	return mImageSize;
}

-(id)copyWithZone:(NSZone *)zone
{
   //[self doesNotRecognizeSelector:_cmd];
    return self;
}

@end
