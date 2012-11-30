//
//  EDDataElementIsis.m
//  BARTApplication
//
//  Created by Lydia Hellrung on 5/4/10.
//  Copyright 2010 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

//#define _GLIBCXX_FULLY_DYNAMIC_STRING 1
//#undef _GLIBCXX_DEBUG
//#undef _GLIBCXX_DEBUG_PEDANTIC

#import "EDDataElementIsis.h"

// ISIS includes
#include "DataStorage/image.hpp"
#include "DataStorage/io_factory.hpp"

// C++ includes
#include <iostream>

@implementation EDDataElementIsis

-(id)init
{
    if (self = [super init]) {
        self->mImageSize = nil;
        self->mITKAdapter = NULL;
    }
    
    return self;    
}



-(id)initWithFile:(NSString*)path andSuffix:(NSString*)suffix andDialect:(NSString*)dialect ofImageType:(enum ImageType)iType
{
	self = [self init];
    mImageSize = [[BARTImageSize alloc] init];
	// set  isis loglevels
	//isis::data::ImageList images;
	std::list<isis::data::Image> images;
	isis::image_io::enableLog<isis::util::DefaultMsgPrint>( isis::warning );
	isis::data::enableLog<isis::util::DefaultMsgPrint>( isis::warning );
	isis::util::enableLog<isis::util::DefaultMsgPrint>( isis::warning );
	
	// the most important thing - load with isis factory
	mIsisImageList = isis::data::IOFactory::load( [path cStringUsingEncoding:NSUTF8StringEncoding], [suffix cStringUsingEncoding:NSUTF8StringEncoding], [dialect cStringUsingEncoding:NSUTF8StringEncoding]);

	//set the type of the image
	mImageType = iType;
	// that's unusual 
    //uint s = mIsisImageList.size();
    if (1 < mIsisImageList.size()) {
        NSLog(@"hmmm, several pics in one image");
	}
	
	//get the type of the orig image
	mDataTypeID = (mIsisImageList.front()).getMajorTypeID();
	
	// make a real copy including conversion to float
	isis::data::MemImage<float> memImg = ((mIsisImageList.front()));
	//splice the whatever build image to a slice-chunked one (each 2D is a single chunk - easier access later on)
    memImg.spliceDownTo(isis::data::sliceDim);
	// give this copy to our class element
	mIsisImage = new isis::data::Image(memImg); 
	// get our class params from the image itself
	mImageSize.rows = mIsisImage->getNrOfRows(); // getDimSize(isis::data::colDim)
    mImageSize.columns = mIsisImage->getNrOfColumns();
    mImageSize.slices = mIsisImage->getNrOfSlices();
    mImageSize.timesteps = mIsisImage->getNrOfTimesteps();
    mRepetitionTimeInMs = mIsisImage->getPropertyAs<u_int16_t>("repetitionTime");
	
	// the image type is now just important for writing
	
 	return self;
}


-(id)initEmptyWithSize:(BARTImageSize*)s ofImageType:(enum ImageType)iType
{
    if ((self = [self init])) {
		
		mImageSize = [s copy];
        mDataTypeID = isis::data::ValueArray<float>::staticID;
		mImageType = iType;
        
        
        // empty isis image
        std::list<isis::data::Chunk> chList;
        
        // create it with each slice and each timestep as a chunk and with type float (loaded ones are converted)
        for (size_t ts = 0; ts < mImageSize.timesteps; ts++){
            for (size_t sl = 0; sl < mImageSize.slices; sl++){
                isis::data::MemChunk<float> ch(mImageSize.columns, mImageSize.rows);
                ch.setPropertyAs<isis::util::fvector3>("indexOrigin", isis::util::fvector3(0,0,sl));//sl
                ch.setPropertyAs<u_int32_t>("acquisitionNumber", sl+ts*mImageSize.slices);//sl+ts*mImageSize.slices
                ch.setPropertyAs<u_int16_t>("sequenceNumber", 1);
                ch.setPropertyAs<isis::util::fvector3>("voxelSize", isis::util::fvector3(1,1,1));
                ch.setPropertyAs<isis::util::fvector3>("rowVec", isis::util::fvector3(1,0,0));
                ch.setPropertyAs<isis::util::fvector3>("columnVec", isis::util::fvector3(0,1,0));
                ch.setPropertyAs<isis::util::fvector3>("sliceVec", isis::util::fvector3(0,0,1));
                chList.push_back(ch);
            }
        }
        
        mIsisImage = new isis::data::Image(chList);
    }
    return self;
}
-(void)dealloc
{
    if (self->mITKAdapter != NULL) {
        delete self->mITKAdapter;
    }
    if (self->mIsisImage != NULL) {
        delete self->mIsisImage;
    }
	[super dealloc];
}

-(id)initFromImage:(isis::data::Image) img  ofImageType:(enum ImageType)imgType
{
	self = [self init];
    mImageSize = [[BARTImageSize alloc] init];
	mIsisImage = new isis::data::Image(img);
	mImageType = imgType;
    
    mDataTypeID = img.getMajorTypeID();
	mImageSize.rows = mIsisImage->getNrOfRows(); // getDimSize(isis::data::colDim)
    mImageSize.columns = mIsisImage->getNrOfColumns();
    mImageSize.slices = mIsisImage->getNrOfSlices();
    mImageSize.timesteps = mIsisImage->getNrOfTimesteps();
    mRepetitionTimeInMs = (mIsisImage->getPropertyAs<u_int16_t>("repetitionTime"));
	
	return self;
}

-(short)getShortVoxelValueAtRow: (int)r col:(int)c slice:(int)s timestep:(int)t
{	
	//TODO we dont want to use this!!
	return (short)mIsisImage->voxel<float>(c,r,s,t);	//else {
}

-(float)getFloatVoxelValueAtRow: (int)r col:(int)c slice:(int)s timestep:(int)t
{
	float val = 0.0;
	if ([self sizeCheckRows:r Cols:c Slices:s Timesteps:t]){
			val = (float)mIsisImage->voxel<float>(c,r,s,t);
		}
    return val;
}

-(void)setVoxelValue:(NSNumber*)val atRow: (unsigned int)r col:(unsigned int)c slice:(unsigned int)sl timestep:(unsigned int)t
{
	if ([self sizeCheckRows:r Cols:c Slices:sl Timesteps:t]){
		mIsisImage->voxel<float>(c,r,sl,t) = [val floatValue];}
}

-(BOOL)WriteDataElementToFile:(NSString*)path
{
	return [self WriteDataElementToFile:path withOverwritingSuffix:@"" andDialect:@""];
}

-(BOOL)WriteDataElementToFile:(NSString*)path withOverwritingSuffix:(NSString*)suffix andDialect:(NSString*)dialect
{
	//isis::data::ImageList imgList;
	//mDataTypeID = isis::data::TypePtr<int8_t>::staticID;
	std::list<isis::data::Image> imgList;
	switch (mDataTypeID) {
		case isis::data::ValueArray<int8_t>::staticID:
		{
			imgList.push_back( isis::data::TypedImage<int8_t> (*mIsisImage));
			break;
		}
		case isis::data::ValueArray<u_int8_t>::staticID:
		{
			imgList.push_back(  isis::data::TypedImage<u_int8_t> (*mIsisImage));
			break;
		}
		case isis::data::ValueArray<int16_t>::staticID:
		{
			imgList.push_back( isis::data::TypedImage<int16_t> (*mIsisImage));
			break;
		}
		case isis::data::ValueArray<u_int16_t>::staticID:
		{
			imgList.push_back(  isis::data::TypedImage<u_int16_t> (*mIsisImage));
			break;
		}
		case isis::data::ValueArray<int32_t>::staticID:
		{
			imgList.push_back(  isis::data::TypedImage<int32_t> (*mIsisImage));
			break;
		}
		case isis::data::ValueArray<u_int32_t>::staticID:
		{
			imgList.push_back(  isis::data::TypedImage<u_int32_t> (*mIsisImage));
			break;
		}
		case isis::data::ValueArray<float>::staticID:
		{
			imgList.push_back(  isis::data::TypedImage<float> (*mIsisImage));
			break;
		}
		case isis::data::ValueArray<double>::staticID:
		{
			imgList.push_back(  isis::data::TypedImage<double> (*mIsisImage));
			break;
		}
			
		default:
			NSLog(@"writeDataElementToFile failed due to unknown data type");
			return FALSE;
	}

	return isis::data::IOFactory::write( imgList, [path cStringUsingEncoding:NSUTF8StringEncoding], [suffix cStringUsingEncoding:NSUTF8StringEncoding], [dialect cStringUsingEncoding:NSUTF8StringEncoding] );
}

-(BOOL)sliceIsZero:(int)slice
{
	// TODO quite slowly at the moment check performance
	return TRUE;
	//isis::util::_internal::TypeBase::Reference minV, maxV;
//	mIsisImage->getChunk(0,0,slice, 0, false).getMinMax(minV, maxV);
//	//NSLog(@"slice is zero: %.2f", maxV->is<float>());
//	if (float(0.0) == maxV->is<float>()){
//		return TRUE;}
//	else {
//		return TRUE;}

}

-(void)setImageProperty:(enum ImagePropertyID)key withValue:(id) value
{	
	isis::util::fvector3 vec;
	switch (key) {
        case PROPID_NAME:
			mIsisImage->setPropertyAs<std::string>("GLM/name", [value UTF8String]);
            break;
        case PROPID_MODALITY:
            
            
            break;
        case PROPID_DF:
            break;
        case PROPID_PATIENT:
			mIsisImage->setPropertyAs<std::string>("subjectName", [value UTF8String]);
            break;
        case PROPID_VOXEL:
            break;
        case PROPID_REPTIME:
            break;
        case PROPID_TALAIRACH:
            break;
        case PROPID_FIXPOINT:
            break;
        case PROPID_CA:
            break;
        case PROPID_CP:
            break;
        case PROPID_EXTENT:
            break;
        case PROPID_BETA:
            break;
		case PROPID_READVEC:
			if ( 0 != [value count] ){
				for (unsigned int i = 0; i<3; i++){
					vec[i] = [[value objectAtIndex:i] floatValue];}}
			mIsisImage->setPropertyAs<isis::util::fvector3>("rowVec", vec);
			break;
		case PROPID_PHASEVEC:
			if ( 0 != [value count] ){
				for (unsigned int i = 0; i<3; i++){
					vec[i] = [[value objectAtIndex:i] floatValue];}}
			mIsisImage->setPropertyAs<isis::util::fvector3>("columnVec", vec);
			break;
		case PROPID_SLICEVEC:
			for (unsigned int i = 0; i<3; i++){
				vec[i] = [[value objectAtIndex:i] floatValue];}
			mIsisImage->setPropertyAs<isis::util::fvector3>("sliceVec", vec);
			break;
		case PROPID_SEQNR:
			mIsisImage->setPropertyAs<uint16_t>("sequenceNumber", [value unsignedShortValue]);
			break;
		case PROPID_VOXELSIZE:
			for (unsigned int i = 0; i<3; i++){
				vec[i] = [[value objectAtIndex:i] floatValue];}
			mIsisImage->setPropertyAs<isis::util::fvector3>("voxelSize", vec);
			break;
		case PROPID_ORIGIN:
			for (unsigned int i = 0; i<3; i++){
				vec[i] = [[value objectAtIndex:i] floatValue];}
			mIsisImage->setPropertyAs<isis::util::fvector3>("indexOrigin", vec);
			break;
        default:
            break;
	}
}

-(id)getImageProperty:(enum ImagePropertyID)key
{	
	id ret = nil;
	std::string strtest;
	
	
	switch (key) {
        case PROPID_NAME:
			ret = [[[NSString alloc ] initWithCString:(mIsisImage->getPropertyAs<std::string>("GLM/name")).c_str() encoding:NSUTF8StringEncoding] autorelease];
			break;
        case PROPID_MODALITY:
            
            
            break;
        case PROPID_DF:
            break;
        case PROPID_PATIENT:
			ret = [[[NSString alloc ] initWithCString:(mIsisImage->getPropertyAs<std::string>("subjectName")).c_str() encoding:NSUTF8StringEncoding] autorelease];
			break;
        case PROPID_VOXEL:
            break;
        case PROPID_REPTIME:
            break;
        case PROPID_TALAIRACH:
            break;
        case PROPID_FIXPOINT:
            break;
        case PROPID_CA:
            break;
        case PROPID_CP:
            break;
        case PROPID_EXTENT:
            break;
        case PROPID_BETA:
            break;
		case PROPID_READVEC:
			ret = [[[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("rowVec")[0]], [NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("rowVec")[1]], [NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("rowVec")[2]], nil ] autorelease];
			break;
		case PROPID_PHASEVEC:
			ret = [[[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("columnVec")[0]], [NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("columnVec")[1]], [NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("columnVec")[2]], nil ] autorelease];
			break;
		case PROPID_SLICEVEC:
			ret = [[[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("sliceVec")[0]], [NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("sliceVec")[1]], [NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("sliceVec")[2]], nil ] autorelease];
			break;
		case PROPID_SEQNR:
			ret = [NSNumber numberWithUnsignedShort:1];
			break;
		case PROPID_VOXELSIZE:
			ret = [[[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("voxelSize")[0]], [NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("voxelSize")[1]], [NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("voxelSize")[2]], nil ] autorelease];
			break;
		case PROPID_ORIGIN:
			ret = [[[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("indexOrigin")[0]], [NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("indexOrigin")[1]], [NSNumber numberWithFloat:mIsisImage->getPropertyAs<isis::util::fvector3>("indexOrigin")[2]], nil ] autorelease];
			break;
        default:
            break;
	}
	return ret;
}

-(EDDataElement*)getDataAtTimeStep:(size_t)tstep
{
    std::list<isis::data::Chunk> chList;
    BARTImageSize *s = [[BARTImageSize alloc] initWithRows:mImageSize.rows andCols:mImageSize.columns andSlices:mImageSize.slices andTimesteps:1];
    
    EDDataElementIsis* retElement = nil;
    if ([self sizeCheckRows:1 Cols:1 Slices:1 Timesteps:tstep]){
        for (size_t i = 0; i < mImageSize.slices; i++){
            chList.push_back(mIsisImage->getChunk(0,0,i,tstep));
        }
    
        isis::data::Image retImg(chList);
        retElement = [[[EDDataElementIsis alloc] initFromImage:retImg ofImageType:IMAGE_FCTDATA] autorelease];
    }
    
    [s release];
    return retElement;
}

-(float*)getSliceData:(uint)sliceNr atTimestep:(uint)tstep
{	
	if ([self sizeCheckRows:1 Cols:1 Slices:sliceNr Timesteps:tstep]){
		isis::data::MemChunkNonDel<float> chSlice(mImageSize.columns, mImageSize.rows);
		mIsisImage->getChunk(0,0, sliceNr, tstep, false).copySlice(0, 0, chSlice, 0, 0);
		return (( boost::shared_ptr<float> ) chSlice.getValueArray<float>()).get();
	}
	return NULL;

}

-(float*)getTimeseriesDataAtRow:(uint)row atCol:(uint)col atSlice:(uint)sl fromTimestep:(uint)tstart toTimestep:(uint)tend
{	
	if ([self sizeCheckRows:row Cols:col Slices:sl Timesteps:tend] and (tstart < tend) ){
		uint nrTimesteps = tend-tstart+1;
		isis::data::MemChunkNonDel<float> chTimeSeries(nrTimesteps, 1);
		for (uint i = tstart; i < tend+1; i++){
			chTimeSeries.voxel<float>(i-tstart,0) = mIsisImage->getChunk(0,0,sl,i, false).voxel<float>(col, row);}
		return (( boost::shared_ptr<float> ) chTimeSeries.getValueArray<float>()).get();
	}
	return NULL;
}

-(float*)getRowDataAt:(uint)row atSlice:(uint)sl atTimestep:(uint)tstep
{	
    if ([self sizeCheckRows:row Cols:1 Slices:sl Timesteps:tstep] ){
		isis::data::MemChunkNonDel<float> rowChunk(mImageSize.columns, 1);
		isis::data::Chunk sliceCh = mIsisImage->getChunk(0,0,sl,tstep, false);
		for (uint i = 0; i < mImageSize.columns; i++){
			rowChunk.voxel<float>(i, 0) = sliceCh.voxel<float>(i, row, 0, 0);}
		return (( boost::shared_ptr<float> ) rowChunk.getValueArray<float>()).get();
	}
	return NULL;
}

-(float*)getColDataAt:(uint)col atSlice:(uint)sl atTimestep:(uint)tstep
{	
	if ([self sizeCheckRows:1 Cols:col Slices:sl Timesteps:tstep] ){
		isis::data::MemChunkNonDel<float> colChunk(mImageSize.rows, 1);
		isis::data::Chunk sliceCh = mIsisImage->getChunk(0,0,sl,tstep, false);
		for (uint i = 0; i < mImageSize.rows; i++){
			colChunk.voxel<float>(i, 0) = sliceCh.voxel<float>(col, i, 0, 0);}
		return (( boost::shared_ptr<float> ) colChunk.getValueArray<float>()).get();
	}
	return NULL;
}

-(void)setRowAt:(uint)row atSlice:(uint)sl	atTimestep:(uint)tstep withData:(float*)data
{	
    if ([self sizeCheckRows:row Cols:1 Slices:sl Timesteps:tstep] ){
		isis::data::MemChunk<float> dataToCopy(data, mImageSize.columns);
		isis::data::Chunk sliceCh = mIsisImage->getChunk(0,0,sl,tstep, false);
		for (uint i = 0; i < mImageSize.columns; i++){
			sliceCh.voxel<float>(i, row, 0, 0) = dataToCopy.voxel<float>(i, 0);}
	}
	return;
	
}

-(void)setColAt:(uint)col atSlice:(uint)sl atTimestep:(uint)tstep withData:(float*)data
{	
	if ([self sizeCheckRows:1 Cols:col Slices:sl Timesteps:tstep] ){
		isis::data::MemChunk<float> dataToCopy(data, mImageSize.rows);
		isis::data::Chunk sliceCh = mIsisImage->getChunk(0,0,sl,tstep, false);
		for (uint i = 0; i < mImageSize.rows; i++){
			sliceCh.voxel<float>(col, i, 0, 0) = dataToCopy.voxel<float>(i, 0);}
	}
	return;
}


-(void)print
{
	mIsisImage->print(std::cout, true);
}

-(BOOL)sizeCheckRows:(uint)r Cols:(uint)c Slices:(uint)s Timesteps:(uint)t
{
	if (r < mImageSize.rows       and
		c < mImageSize.columns    and
		s < mImageSize.slices     and
		t < mImageSize.timesteps ){
		return YES;}
	return NO;

}

-(void)copyProps:(NSArray*)propList fromDataElement:(EDDataElement*)srcElement
{
	[self setProps: [srcElement getProps:propList]];
}


-(NSDictionary*)getProps:(NSArray*)propList
{
	NSMutableArray *propValues = [[NSMutableArray alloc] init];
	for (NSString *str in propList) {				// type is fvector3
		if ( [[str lowercaseString] isEqualToString:@"indexorigin"]
		or [[str lowercaseString] isEqualToString:@"rowvec"]
		or [[str lowercaseString] isEqualToString:@"columnvec"]
		or [[str lowercaseString] isEqualToString:@"slicevec"]
		or [[str lowercaseString] isEqualToString:@"capos"]
		or [[str lowercaseString] isEqualToString:@"cppos"]
		or [[str lowercaseString] isEqualToString:@"voxelsize"]
		or [[str lowercaseString] isEqualToString:@"voxelgap"])
		{
			isis::util::fvector3 prop = mIsisImage->getPropertyAs<isis::util::fvector3>([str  cStringUsingEncoding:NSISOLatin1StringEncoding]);
			NSArray* ret = [[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:prop[0]], [NSNumber numberWithFloat:prop[1]], [NSNumber numberWithFloat:prop[2]], nil ] ;
			[propValues addObject:ret];
		}
		else if( [[str lowercaseString] isEqualToString:@"acquisitionnumber"]) //type is u_int32_t
		{
			u_int32_t prop = mIsisImage->getPropertyAs<u_int32_t>([str  cStringUsingEncoding:NSISOLatin1StringEncoding]);
			NSNumber* ret = [NSNumber numberWithUnsignedLong:prop] ;
			[propValues addObject:ret];
		}
		else if ( [[str lowercaseString] isEqualToString:@"repetitiontime"]	// type is u_int16_t
		or   [[str lowercaseString] isEqualToString:@"sequencenumber"]
		or   [[str lowercaseString] isEqualToString:@"subjectage"]
		or   [[str lowercaseString] isEqualToString:@"subjectweight"]
		or   [[str lowercaseString] isEqualToString:@"flipangle"]
		or   [[str lowercaseString] isEqualToString:@"numberofaverages"] )
		{
			u_int16_t prop = mIsisImage->getPropertyAs<u_int16_t>([str  cStringUsingEncoding:NSISOLatin1StringEncoding ]);
			NSNumber* ret = [NSNumber numberWithUnsignedInt:prop] ;
			[propValues addObject:ret];
		}
		else if ( [[str lowercaseString] isEqualToString:@"echotime"]	 // type is float
		or   [[str lowercaseString] isEqualToString:@"acquisitiontime"] )
		{
			float prop = mIsisImage->getPropertyAs<float>([str  cStringUsingEncoding:NSISOLatin1StringEncoding]);
			NSNumber* ret = [NSNumber numberWithFloat:prop] ;
			[propValues addObject:ret];
		}
		else									// everything else is interpreted as string (conversion by isis)
		{
            std::string prop = "";
			if (mIsisImage->hasProperty([str cStringUsingEncoding:NSISOLatin1StringEncoding]))
            {
				prop = mIsisImage->getPropertyAs<std::string>([str  cStringUsingEncoding:NSISOLatin1StringEncoding]);
            }
			NSString* ret = [[NSString stringWithCString:prop.c_str() encoding:NSISOLatin1StringEncoding] autorelease];
			[propValues addObject:ret];
            
		}
	} 
		
	NSDictionary *propDict = [[NSDictionary alloc] initWithObjects:propValues forKeys:propList];
    [propValues release];
	return [propDict autorelease];
}

-(void)setProps:(NSDictionary*)propDict
{
	[propDict retain];
	for (NSString *str in [propDict allKeys]) {		// type is fvector3
		if ( [[str lowercaseString] isEqualToString:@"indexorigin"]
			or [[str lowercaseString] isEqualToString:@"rowvec"]
			or [[str lowercaseString] isEqualToString:@"columnvec"]
			or [[str lowercaseString] isEqualToString:@"slicevec"]
			or [[str lowercaseString] isEqualToString:@"capos"]
			or [[str lowercaseString] isEqualToString:@"cppos"]
			or [[str lowercaseString] isEqualToString:@"voxelsize"]
			or [[str lowercaseString] isEqualToString:@"voxelgap"])
		{
			isis::util::fvector3 prop;
            if (YES == [[propDict valueForKey:str] isKindOfClass:[NSArray class]]){
                //fvector3 consists of 3 values - if array is longer will be ignored
                size_t maxCount = [[propDict valueForKey:str] count] < 3 ? [[propDict valueForKey:str] count] : 3;
				for (size_t i = 0; i < maxCount; i++){
					prop[i] = [[[propDict valueForKey:str] objectAtIndex:i] floatValue];}
				mIsisImage->setPropertyAs<isis::util::fvector3>([str cStringUsingEncoding:NSISOLatin1StringEncoding], prop);
			}
		}
		else if( [[str lowercaseString] isEqualToString:@"acquisitionnumber"]) //type is u_int32_t
		{
			if (YES == [[propDict valueForKey:str] isKindOfClass:[NSNumber class]]){
				u_int32_t prop = [[propDict valueForKey:str] unsignedLongValue];
				mIsisImage->setPropertyAs<u_int32_t>([str  cStringUsingEncoding:NSISOLatin1StringEncoding], prop);}
		}
		else if ( [[str lowercaseString] isEqualToString:@"repetitiontime"] // type is u_int16_t
			or   [[str lowercaseString] isEqualToString:@"sequencenumber"]
			or   [[str lowercaseString] isEqualToString:@"subjectage"]
			or   [[str lowercaseString] isEqualToString:@"subjectweight"]
			or   [[str lowercaseString] isEqualToString:@"flipangle"]
			or   [[str lowercaseString] isEqualToString:@"numberofaverages"] )
		{
			if (YES == [[propDict valueForKey:str] isKindOfClass:[NSNumber class]]){
				u_int16_t prop = [[propDict valueForKey:str] unsignedIntValue];
				mIsisImage->setPropertyAs<u_int16_t>([str  cStringUsingEncoding:NSISOLatin1StringEncoding], prop);}
		}
		else if ( [[str lowercaseString] isEqualToString:@"echotime"]  // type is float
			or   [[str lowercaseString] isEqualToString:@"acquisitiontime"] )
		{
			if (YES == [[propDict valueForKey:str] isKindOfClass:[NSNumber class]]){
				float prop = [[propDict valueForKey:str] floatValue];
				mIsisImage->setPropertyAs<float>([str  cStringUsingEncoding:NSISOLatin1StringEncoding], prop);}
		}
		else									// everything else is interpreted as string (conversion by isis)
 		{
			if (YES == [[propDict valueForKey:str] isKindOfClass:[NSString class]]){
				std::string prop = [[propDict valueForKey:str]  cStringUsingEncoding:NSISOLatin1StringEncoding];
				NSLog(@"%s", prop.c_str());
				mIsisImage->setPropertyAs<std::string>([str  cStringUsingEncoding:NSISOLatin1StringEncoding], prop.c_str());
            }
		}
	} 
   	[propDict release];
	
}

-(BOOL)isValid
{
	return mIsisImage->isValid();
}

-(BOOL)isEmpty
{
	return mIsisImage->isEmpty();
}

-(enum ImageDataType)getImageDataType
{
	switch (mDataTypeID) {
		case isis::data::ValueArray<int8_t>::staticID:
		{
			return IMAGE_DATA_INT8;
			break;
		}
		case isis::data::ValueArray<u_int8_t>::staticID:
		{
			return IMAGE_DATA_UINT8;
			break;
		}
		case isis::data::ValueArray<int16_t>::staticID:
		{
			return IMAGE_DATA_INT16;
			break;
		}
		case isis::data::ValueArray<u_int16_t>::staticID:
		{
			return IMAGE_DATA_UINT16;
			break;
		}
		case isis::data::ValueArray<int32_t>::staticID:
		{
			return IMAGE_DATA_FLOAT;
			break;
		}
		case isis::data::ValueArray<u_int32_t>::staticID:
		{
			return IMAGE_DATA_UINT32;
			break;
		}
		case isis::data::ValueArray<float>::staticID:
		{
			return IMAGE_DATA_FLOAT;
			break;
		}
		case isis::data::ValueArray<double>::staticID:
		{
			return IMAGE_DATA_DOUBLE;
			break;
		}
			
		default:
			return IMAGE_DATA_UNKNOWN;
			break;
	}
	
}

-(void)startRealTimeInput
{

}

-(void)loadNextVolume
{

}

-(void)appendVolume:(EDDataElementIsis*)nextVolume
{
	
}

-(NSArray*)getMinMaxOfDataElement
{
    std::pair<float, float> minMax = mIsisImage->getMinMaxAs<float>();
    NSArray *ret = [NSArray arrayWithObjects:[NSNumber numberWithFloat:minMax.first], [NSNumber numberWithFloat:minMax.second], nil];
    return ret;
}

-(ITKImage::Pointer)asITKImage
{
    if (self->mITKAdapter != NULL)  {
        delete self->mITKAdapter;
    }
        
    self->mITKAdapter = new isis::adapter::itkAdapter;
    ITKImage::Pointer itkImage = self->mITKAdapter->makeItkImageObject<ITKImage>(*mIsisImage);
    return itkImage;
}

-(ITKImage4D::Pointer)asITKImage4D
{
    if (self->mITKAdapter != NULL)  {
        delete self->mITKAdapter;
    }
    
    self->mITKAdapter = new isis::adapter::itkAdapter;
    ITKImage4D::Pointer itkImage = self->mITKAdapter->makeItkImageObject<ITKImage4D>(*mIsisImage);
    return itkImage;
}

-(EDDataElement*)convertFromITKImage:(ITKImage::Pointer)itkImg
{
    if (self->mITKAdapter != NULL) {
        std::list<isis::data::Image> imgList = self->mITKAdapter->makeIsisImageObject<ITKImage>(itkImg);

        if (imgList.size() > 0) {
            return [[[EDDataElementIsis alloc] initFromImage:imgList.front() 
                                                 ofImageType:IMAGE_ANADATA] 
                    autorelease];
        }
    }
    
    return nil;
}

-(EDDataElement*)convertFromITKImage4D:(ITKImage4D::Pointer)itkImg4D
{
    if (self->mITKAdapter != NULL) {
        std::list<isis::data::Image> imgList = self->mITKAdapter->makeIsisImageObject<ITKImage4D>(itkImg4D);
        
        if (imgList.size() > 0) {
            return [[[EDDataElementIsis alloc] initFromImage:imgList.front() 
                                                 ofImageType:IMAGE_FCTDATA] 
                    autorelease];
        }
    }
    
    return nil;
}

-(void)updateFromITKImage:(ITKImage::Pointer)itkImg
{
    // TODO
}

-(void)updateFromITKImage4D:(ITKImage4D::Pointer)itkImg4D
{
    // TODO
}

-(ITKImage::Pointer)asITKImage:(unsigned int)timestep
{
    return nil;
}

@end
