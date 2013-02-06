//
//  EDDataElementVI.m
//  BARTCommandLine
//
//  Created by Lydia Hellrung on 10/29/09.
//  Copyright 2009 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import "EDDataElementVI.h"

// viaio library
#include <viaio/Vlib.h>
#include <viaio/VImage.h>
#include <viaio/mu.h>
#include <viaio/option.h>

// system libraries used for VImage 
// Check which one you really need here 
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <ctype.h>

// gsl libraries for matrices etc
// Check which one you really need here
//#include <gsl/gsl_cblas.h>
//#include <gsl/gsl_matrix.h>
//#include <gsl/gsl_vector.h>
//#include <gsl/gsl_blas.h>
//#include <gsl/gsl_linalg.h>
//#include <gsl/gsl_sort.h>
//#include <gsl/gsl_cdf.h>
//#include "gsl_utils.h"


@interface EDDataElementVI (PrivateMethods)

-(void)LoadImageData:(NSString*)path ofImageDataType:(enum ImageDataType)type;

//-(void)initDatasetProperties;

@end

@implementation EDDataElementVI {


}




-(id)initWithFile:(NSString*)path ofImageDataType:(enum ImageDataType)type
{
    if (self = [super init]) {
         //TESTZWECK - EIGENTLICH HIER NICHT GEBRAUCHT, 
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDataElement) name:@"NewDataArrived" object:nil];
         
        mImageDataType = type;
        [self LoadImageData:[path retain] ofImageDataType:type];
    }
    
   // [self initDatasetProperties];
       
    return self;
    
}

-(id)initWithDataType:(enum ImageDataType)type andRows:(int) rows andCols:(int)cols andSlices:(int)slices andTimesteps:(int) tsteps 
{
    if (self = [super init]) {
        mImageSize.columns = cols;
        mImageSize.rows = rows;
        mImageSize.slices = slices;
        mImageSize.timesteps = tsteps;
        mImageDataType = type;
        
        
        mImageArray = (VImage *)VMalloc(sizeof(VImage)*slices);
        for (int i=0; i < slices; i++) {
            if ( IMAGE_DATA_FLOAT == type){
                mImageArray[i] = VCreateImage(tsteps,rows,cols,VFloatRepn);
                VFillImage(mImageArray[i], VAllBands, 0);
            }
            if (IMAGE_DATA_INT16 == type){
                mImageArray[i] = VCreateImage(tsteps,rows,cols,VShortRepn);
                VFillImage(mImageArray[i], VAllBands, 0);
                
            }
            
        }
    }
    //[self initDatasetProperties];
    return self;
}

-(void)updateDataElement
{
    // update the data element with the new arrived data
    NSLog(@"received Message NewDataArrived");   
    
}
-(short)getShortVoxelValueAtRow: (int)r col:(int)c slice:(int)s timestep:(int)t
{
    return VPixel(mImageArray[s], t, r, c, VShort);
//    NSNumber *ret;
//    if (IMAGE_DATA_SHORT == imageDataType){
//        ret = [NSNumber numberWithShort:VPixel(mImageArray[s], t, r, c, VShort)];}
//    if (IMAGE_DATA_FLOAT == imageDataType){
//        ret = [NSNumber numberWithFloat:VGetPixel(mImageArray[0], 0, r, c)];}
//    //TODO: IMAGE_BETA == type
//    return ret;
}
-(float)getFloatVoxelValueAtRow:(int)r col:(int)c slice:(int)s timestep:(int)t
{
    if (IMAGE_DATA_FLOAT == mImageDataType) {
        return VPixel(mImageArray[s], t, r, c, VFloat);
    } else if (IMAGE_DATA_INT16 == mImageDataType) {
        return (float) VPixel(mImageArray[s], t, r, c, VShort);
    }

    return NAN;
}

-(void)setVoxelValue:(NSNumber*)val atRow: (unsigned int)r col:(unsigned int)c slice:(unsigned int)s timestep:(unsigned int)t
{
    if (IMAGE_DATA_FLOAT == mImageDataType) {
        VPixel(mImageArray[s], t, r, c, VFloat) = [val floatValue];
    }
    if (IMAGE_DATA_INT16 == mImageDataType) {
        VPixel(mImageArray[s], t, r, c, VShort) = [val shortValue];
    }

}

-(void)dealloc
{
    for (size_t i=0; i<mImageSize.slices; i++) {
        VFree(mImageArray[i]);
    }
    VFree(m_linfo);
    VFree(mImageArray);
    [super dealloc];
}

-(BOOL)sliceIsZero:(int)slice;
{
    return (m_linfo[0].zero[slice] != 0);
}

-(void)setImageProperty:(enum ImagePropertyID)key withValue:(id)value
{
    //decide what repn kind
    

    switch (key) {
        case PROPID_NAME:
            for (size_t i = 0; i < mImageSize.slices; i++)
                VSetAttr(VImageAttrList(mImageArray[i]), "name", NULL, VStringRepn, [value UTF8String]);
            break;
        case PROPID_MODALITY:
            for (size_t i = 0; i < mImageSize.slices; i++)
                VSetAttr(VImageAttrList(mImageArray[i]), "modality", NULL, VStringRepn, [value UTF8String]);
            
            break;
        case PROPID_DF:
            for (size_t i = 0; i < mImageSize.slices; i++)
                VSetAttr(VImageAttrList(mImageArray[i]), "df", NULL, VFloatRepn, [value floatValue]);
            break;
        case PROPID_PATIENT:
            for (size_t i = 0; i < mImageSize.slices; i++)
                VSetAttr(VImageAttrList(mImageArray[i]), "patient", NULL, VStringRepn, [value UTF8String]);
            break;
        case PROPID_VOXEL:
            for (size_t i = 0; i < mImageSize.slices; i++)
                VSetAttr(VImageAttrList(mImageArray[i]), "voxel", NULL, VStringRepn, [value UTF8String]);
            break;
        case PROPID_REPTIME:
            for (size_t i = 0; i < mImageSize.slices; i++)
                VSetAttr(VImageAttrList(mImageArray[i]), "repetition_time", NULL, VLongRepn, [value longValue]);
            break;
        case PROPID_TALAIRACH:
            for (size_t i = 0; i < mImageSize.slices; i++)
                VSetAttr(VImageAttrList(mImageArray[i]), "talairach", NULL, VStringRepn, [value UTF8String]);
            break;
        case PROPID_FIXPOINT:
            for (size_t i = 0; i < mImageSize.slices; i++){
                 VSetAttr(VImageAttrList(mImageArray[i]), "fixpoint", NULL, VStringRepn, [value UTF8String]);
                }
            
            break;
        case PROPID_CA:
            for (size_t i = 0; i < mImageSize.slices; i++)
                VSetAttr(VImageAttrList(mImageArray[i]), "ca", NULL, VStringRepn, [value UTF8String]);
            break;
        case PROPID_CP:
            for (size_t i = 0; i < mImageSize.slices; i++)
                VSetAttr(VImageAttrList(mImageArray[i]), "cp", NULL, VStringRepn,[value UTF8String]);
            break;
        case PROPID_EXTENT:
            for (size_t i = 0; i < mImageSize.slices; i++)
                VSetAttr(VImageAttrList(mImageArray[i]), "extent", NULL, VStringRepn, [value UTF8String]);
            break;
        case PROPID_BETA:
            for (size_t i = 0; i < mImageSize.slices; i++)
                VSetAttr(VImageAttrList(mImageArray[i]), "beta", NULL, VShortRepn,[value intValue]);
            break;
        default:
            break;
    }
}

-(id)getImageProperty:(enum ImagePropertyID)key
{
    id ret = nil;
    
    switch (key) {
        case PROPID_NAME:
            break;
        case PROPID_MODALITY:
            break;
        case PROPID_DF:
            ret = [[[NSNumber alloc] initWithFloat:m_linfo[0].info->df] autorelease];
            break;
        case PROPID_PATIENT:
            ret = [[[NSString alloc] initWithCString:m_linfo[0].info->patient encoding:NSUTF8StringEncoding] autorelease];
            break;
        case PROPID_VOXEL:
            ret = [[[NSString alloc] initWithCString:m_linfo[0].info->voxel encoding:NSUTF8StringEncoding] autorelease];
            break;
        case PROPID_REPTIME:
            break;
        case PROPID_TALAIRACH:
            ret = [[[NSString alloc] initWithCString:m_linfo[0].info->talairach encoding:NSUTF8StringEncoding] autorelease];
            break;
        case PROPID_FIXPOINT:
            ret = [[[NSString alloc] initWithCString:m_linfo[0].info->fixpoint encoding:NSUTF8StringEncoding] autorelease];
            break;
        case PROPID_CA:
            
            ret = [[[NSString alloc] initWithCString:m_linfo[0].info->ca encoding:NSUTF8StringEncoding] autorelease];
            break;
        case PROPID_CP:
            ret = [[[NSString alloc] initWithCString:m_linfo[0].info->cp encoding:NSUTF8StringEncoding] autorelease];
            break;
        case PROPID_EXTENT:
            ret = [[[NSString alloc] initWithCString:m_linfo[0].info->extent encoding:NSUTF8StringEncoding] autorelease];
            break;
        case PROPID_BETA:
            break;
        default:
            break;
            
          
    }
    return ret; 
}

-(BOOL)WriteDataElementToFile:(NSString*)path
{
    char* outputFilename = (char*) VMalloc(sizeof(char)*UINT16_MAX);
    [path getCString:outputFilename maxLength:UINT16_MAX  encoding:NSUTF8StringEncoding];
    
    m_out_list = VCreateAttrList();
    for (size_t i = 0; i < mImageSize.slices; i++){
        VAppendAttr(m_out_list, "image", NULL, VImageRepn, mImageArray[i]);
    }
    
    FILE* f = VOpenOutputFile(outputFilename, TRUE);
	if (!f) {
		return FALSE;
	}
	if (!VWriteFile(f, m_out_list)) {
		return FALSE;
	}
    return TRUE;
	//printf("GLM with %s: done.\n", outputFilename);
	    
}

@end

#pragma mark -

@implementation EDDataElementVI (PrivateMethods)

-(void)LoadImageData:(NSString*)path ofImageDataType:(enum ImageDataType)type
{
    //NEW STUFF
   
    char* inputFilename = (char*) VMalloc(sizeof(char) *UINT16_MAX);// = "/Users/user/Development/BR5T-functional.v";
    [path getCString:inputFilename maxLength:UINT16_MAX  encoding:NSUTF8StringEncoding]; //path lastPathComponent];
   
    if ( IMAGE_DATA_INT16 == type){
    
        //AS BEFORE
        VAttrList list;		//attribute list from vista image header
        VAttrListPosn posn;	//iterator over header attributes
        FILE * in_file;
        m_linfo = (ListInfo *) VMalloc(sizeof(ListInfo) * 1);
        GetListInfo(inputFilename, &m_linfo[0]);
        m_pxinfo = m_linfo[0].info;
        mImageArray = (VImage *)VMalloc(sizeof(VImage)*m_linfo[0].nslices);//20);
        
        in_file = fopen(inputFilename, "r");
        //load file
        if (! (list = VReadFile (in_file, NULL))) {
            printf("Kann nich lesen\n");
            return;
        }

        //run through attributes and search image data
        int index = 0;
        for (VFirstAttr(list, &posn); VAttrExists(&posn); VNextAttr(&posn)) {
            if (VGetAttrRepn(&posn) == VImageRepn) {
                mImageArray[index] = VCreateImage(m_linfo[0].ntimesteps,m_linfo[0].nrows,m_linfo[0].ncols,VShortRepn);
            //get image data
                VGetAttrValue(&posn, NULL, VImageRepn, &mImageArray[index]);
                index++;
            }
           
        }
        
        m_linfo = (ListInfo *) VMalloc(sizeof(ListInfo) * 1);//1 == nimages - ggf zu aendern
        GetListInfo(inputFilename, &m_linfo[0]);
        fclose(in_file);
        
		mImageSize = [[BARTImageSize alloc] init];
        mImageSize.rows = m_linfo[0].nrows;
        mImageSize.columns = m_linfo[0].ncols;
        mImageSize.slices = m_linfo[0].nslices;
        mImageSize.timesteps  = m_linfo[0].ntimesteps;
        
        
    }
    VFree(inputFilename);
    [path release];
    return;
}

-(short*)getShortDataFromSlice:(int)sliceNr
{
    return (short*)VImageData(mImageArray[sliceNr]);
}

-(float*)getFloatDataFromSlice:(int)sliceNr
{
    return (float*)VImageData(mImageArray[sliceNr]);
}

-(enum ImageDataType)getImageDataType
{
	return mImageDataType;
}

@end

