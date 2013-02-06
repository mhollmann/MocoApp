//
//  EDDataElementIsisRealTime.m
//  BARTApplication
//
//  Created by Lydia Hellrung on 3/30/11.
//  Copyright 2011 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import "EDDataElementIsisRealTime.h"
#import "EDDataElementIsis.h"
#import "DataStorage/io_factory.hpp"
#import <algorithm>
#include <vector>
#include <iostream>


@interface EDDataElementIsisRealTime (PrivateMethods)

-(BOOL)sizeCheckRows:(uint)r Cols:(uint)c Slices:(uint)s Timesteps:(uint)t;

@end

@implementation EDDataElementIsisRealTime



-(id)initWithFile:(NSString*)path andSuffix:(NSString*)suffix andDialect:(NSString*)dialect ofImageType:(enum ImageType)iType
{
	self = [super init];
    //mRepetitionNumber = 0;
	mImagePropertiesMap = nil;
	//set the type of the image
	mImageType = iType;
		
	// the most important thing - load with isis factory
	std::list<isis::data::Image> images = isis::data::IOFactory::load( [path cStringUsingEncoding:NSUTF8StringEncoding], [suffix cStringUsingEncoding:NSUTF8StringEncoding], [dialect cStringUsingEncoding:NSUTF8StringEncoding]);
	
	// that's unusual - take the first one, warn the user
    if (1 < images.size()) {
        NSLog(@"hmmm, several pics in one image");
	}
	// make a real copy including conversion to float
	isis::data::MemImage<float> memImg = images.front();
	
	//get the type of the orig image
	mDataTypeID = memImg.getChunkAt(0).getTypeID();
	
	
	// give this copy to our class element
    isis::data::Image anImage = memImg; 
	//splice the whatever build image to a slice-chunked one (each 2D is a single chunk - easier access later on)
    anImage.spliceDownTo(isis::data::sliceDim);
	// get our class params from the image itself
	mImageSize.rows = anImage.getNrOfRows(); // getDimSize(isis::data::colDim)
    mImageSize.columns = anImage.getNrOfColumns();
    mImageSize.slices = anImage.getNrOfSlices();
    mImageSize.timesteps = anImage.getNrOfTimesteps();
    mRepetitionTimeInMs = anImage.getPropertyAs<u_int16_t>("repetitionTime");
	
	return self;
}

-(id)initEmptyWithSize:(BARTImageSize*) imageSize ofImageType:(enum ImageType)iType
{
    self = [super init];
    //mRepetitionNumber = 0;
	//mAllDataMap.clear();
	mImageType = iType;
	mImageSize = [imageSize copy];
    mIsisImage = nil;
	return self;
	
}

-(void)dealloc
{
    if (nil != mIsisImage){
        delete mIsisImage;}

    [mImageSize release];
	
    [super dealloc];
}

-(short)getShortVoxelValueAtRow: (int)r col:(int)c slice:(int)sl timestep:(int)t
{
   // std::vector<boost::shared_ptr<isis::data::Chunk> > vecSlices = mAllDataMap[t];
//    boost::shared_ptr<isis::data::Chunk> ptrChunk = vecSlices[sl];
//    
	return (short)mIsisImage->voxel<float>(c,r,sl,t);
}

-(float)getFloatVoxelValueAtRow: (int)r col:(int)c slice:(int)sl timestep:(int)t
{
	//std::vector<boost::shared_ptr<isis::data::Chunk> > vecSlices = mAllDataMap[t];
//    boost::shared_ptr<isis::data::Chunk> ptrChunk = vecSlices[sl];
//    
	return (float)mIsisImage->voxel<float>(c,r,sl,t);
    
}

-(void)setVoxelValue:(NSNumber*)val atRow: (unsigned int)r col:(unsigned int)c slice:(unsigned int)sl timestep:(unsigned int)t
{
   // if (mAllDataMap.size() >= t){
//        std::vector<boost::shared_ptr<isis::data::Chunk> > vecSlices = mAllDataMap[t];
//        if (vecSlices.size() >= sl){
//            boost::shared_ptr<isis::data::Chunk> ptrChunk = vecSlices[sl];
//            if (mImageSize.rows >= r && mImageSize.columns >= c) {
                mIsisImage->voxel<float>(c,r,sl,t) = [val floatValue];
//            }
//        }
//    }
    
}


-(BOOL)WriteDataElementToFile:(NSString*)path
{
	
    return [self WriteDataElementToFile:path withOverwritingSuffix:@"" andDialect:@""];
}

-(BOOL)WriteDataElementToFile:(NSString*)path withOverwritingSuffix:(NSString*)suffix andDialect:(NSString*)dialect
{
    //std::map<size_t, std::vector<boost::shared_ptr<isis::data::Chunk> > >::iterator itMap;
//    std::vector<boost::shared_ptr<isis::data::Chunk> >::iterator itVector;
//    std::list<isis::data::Chunk> chunkList;
//    for (itMap = mAllDataMap.begin(); itMap != mAllDataMap.end() ; itMap++) {
//        for (itVector=(*itMap).second.begin(); itVector != (*itMap).second.end(); itVector++) {
//            
//			//TODO: INCLUDE THIS WHEN PROBLEM WITH ACQ NR IS CLEAR
//			//(*itVector)->join(mPropMapImage);
//			//std::cout << mPropMapImage.print(std::cout) << std::endl;
//			//isis::util::PropertyMap propsOfChunk = isis::util::PropertyMap(**itVector);
//			//std::cout << propsOfChunk.print(std::cout) << std::endl;
//			chunkList.push_back(*(*itVector));
//        }
//        
//    }
	
	mIsisImage->prepareToWrite();
	std::list<isis::data::Chunk> chList;
	std::vector<isis::data::Chunk> chVector = mIsisImage->copyChunksToVector();
	std::vector<isis::data::Chunk> ::iterator itVector;
	for (itVector = chVector.begin(); itVector != chVector.end(); itVector++) {
		//(**itVector).join(*mIsisImage);
		chList.push_back(*itVector);
	}
	//std::copy(chVector.begin(), chVector.end(), chList.end())
    NSLog(@"ChunkList size: %lu", chList.size());
    isis::data::Image img(chList);
    NSLog(@"ChunkList size: %lu", chList.size());
   	
	return isis::data::IOFactory::write(img, [path cStringUsingEncoding:NSUTF8StringEncoding], 
                                 [suffix cStringUsingEncoding:NSUTF8StringEncoding], 
                                 [dialect cStringUsingEncoding:NSUTF8StringEncoding]);
	
}

-(BOOL)sliceIsZero:(int)slice
{
	return TRUE;
}

-(void)setImageProperty:(enum ImagePropertyID)key withValue:(id) value;
{
	
}

-(id)getImageProperty:(enum ImagePropertyID)key
{
	id ret = nil;
	//std::string strtest;
//	std::vector<boost::shared_ptr<isis::data::Chunk> > vecSlices = mAllDataMap[0];
//	boost::shared_ptr<isis::data::Chunk> ptrChunk = vecSlices[0];
//	
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

-(enum ImageDataType)getImageDataType
{
	return IMAGE_DATA_FLOAT;
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

-(float*)getRowDataAt:(uint)row atSlice:(uint)sl atTimestep:(uint)tstep
{
	return nil;
}

-(void)setRowAt:(uint)row atSlice:(uint)sl	atTimestep:(uint)tstep withData:(float*)data
{
	
}

-(float*)getColDataAt:(uint)row atSlice:(uint)sl atTimestep:(uint)tstep
{
	return nil;
}

-(void)setColAt:(uint)col atSlice:(uint)sl atTimestep:(uint)tstep withData:(float*)data
{
	
}

-(float*)getTimeseriesDataAtRow:(uint)row atCol:(uint)col atSlice:(uint)sl fromTimestep:(uint)tstart toTimestep:(uint)tend
{
	return nil;
}

-(void)print
{
	
}

-(void)copyProps:(NSArray*)propList fromDataElement:(EDDataElement*)srcElement
{
	[self setProps: [srcElement getProps:propList]];
}


-(NSDictionary*)getProps:(NSArray*)propList
{
	
	//TODO: arbeite mit DIctionary
	//std::vector<boost::shared_ptr<isis::data::Chunk> > vecSlices = mAllDataMap[0];
	//boost::shared_ptr<isis::data::Chunk> ptrChunk = vecSlices[0];
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
			NSArray* ret = [[[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:prop[0]], [NSNumber numberWithFloat:prop[1]], [NSNumber numberWithFloat:prop[2]], nil ] autorelease];
			[propValues addObject:ret];
		}
		else if( [[str lowercaseString] isEqualToString:@"acquisitionnumber"]) //type is u_int32_t
		{
			u_int32_t prop = mIsisImage->getPropertyAs<u_int32_t>([str  cStringUsingEncoding:NSISOLatin1StringEncoding]);
			NSNumber* ret = [[NSNumber numberWithUnsignedLong:prop] autorelease];
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
			NSNumber* ret = [[NSNumber numberWithUnsignedInt:prop] autorelease];
			[propValues addObject:ret];
		}
		else if ( [[str lowercaseString] isEqualToString:@"echotime"]	 // type is float
				 or   [[str lowercaseString] isEqualToString:@"acquisitiontime"] )
		{
			float prop = mIsisImage->getPropertyAs<float>([str  cStringUsingEncoding:NSISOLatin1StringEncoding]);
			NSNumber* ret = [[NSNumber numberWithFloat:prop] autorelease];
			[propValues addObject:ret];
		}
		else									// everything else is interpreted as string (conversion by isis)
		{
			std::string prop = "";
			if (mIsisImage->hasProperty([str cStringUsingEncoding:NSISOLatin1StringEncoding])){
				prop = mIsisImage->getPropertyAs<std::string>([str  cStringUsingEncoding:NSISOLatin1StringEncoding]);}
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
	//TODO: arbeite mit DIctionary
	//std::vector<boost::shared_ptr<isis::data::Chunk> > vecSlices = mAllDataMap[0];
	//boost::shared_ptr<isis::data::Chunk> ptrChunk = vecSlices[0];
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
				for (unsigned int i = 0; i < [[propDict valueForKey:str] count]; i++){
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
				mIsisImage->setPropertyAs<std::string>([str  cStringUsingEncoding:NSISOLatin1StringEncoding], prop.c_str());}
		}
	} 
	
}


-(void)appendVolume:(isis::data::Image)img
{
    if (nil == mIsisImage)
    {
        mImageSize.rows = img.getNrOfRows();
        mImageSize.columns = img.getNrOfColumns();
        mImageSize.slices = img.getNrOfSlices();
        mImageSize.timesteps = 1;
		mDataTypeID = img.getMajorTypeID();
		mIsisImage = new EDIsisImage(img);
    }
    else {
        if ((mImageSize.rows == img.getNrOfRows())
            && (mImageSize.columns == img.getNrOfColumns())
            && (mImageSize.slices == img.getNrOfSlices()))
        {
            mImageSize.timesteps += 1;
            mIsisImage->appendVolume(img);
            
        }
        else {
            NSLog(@"Size of appended Volume does not match all other volumes");
            return;
        }
    }

}

-(BOOL)isEmpty
{
	return mIsisImage->isEmpty();
}

-(BOOL)sizeCheckRows:(uint)r Cols:(uint)c Slices:(uint)s Timesteps:(uint)t
{
	if (r < mImageSize.rows     and
		c < mImageSize.columns  and
		s < mImageSize.slices   and
		t < mImageSize.timesteps){
		return YES;}
	return NO;
    
}

//MH FIXME: added
-(ITKImage::Pointer)asITKImage
{
    if (self->mITKAdapter != NULL)  {
        delete self->mITKAdapter;
    }
    
    self->mITKAdapter = new isis::adapter::itkAdapter;
    
    ITKImage::Pointer itkImage = self->mITKAdapter->makeItkImageObject<ITKImage>(*mIsisImage);
    return itkImage;
}


//MH FIXME: added, Important: this returns a EDDataElementIsis!!!!
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




-(NSArray*)getMinMaxOfDataElement
{

    std::pair<float, float> minMax = mIsisImage->getMinMaxAs<float>();
    NSArray *ret = [NSArray arrayWithObjects:[NSNumber numberWithFloat:minMax.first], [NSNumber numberWithFloat:minMax.second], nil];
    return ret;
}

@end
