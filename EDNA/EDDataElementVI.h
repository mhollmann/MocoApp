//
//  EDDataElementVI.h
//  BARTCommandLine
//
//  Created by Lydia Hellrung on 10/29/09.
//  Copyright 2009 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EDDataElement.h"

#include <viaio/Vlib.h>
#include <viaio/VImage.h>
#include <viaio/mu.h>
#include <viaio/option.h>

//MHFIXME
//#include "BlockIO.h"


@interface EDDataElementVI : EDDataElement{

    //hier wird das olle VImage versteckt!
    VImage *mImageArray;
    VImageInfo *m_pxinfo;
    //VImage m_ResImage;	   /* */
//	VImage m_BetaImages[MBETA];	   /* */
//	VImage m_BCOVImage;			   /* */
//	VImage m_KXImage;		   /* */
    ListInfo *m_linfo;
    VAttrList m_out_list;
    //VImage m_DesignImage;
	
	
	
	
    
    NSDictionary *mImagePropertyToFctMap;
}



-(id)initWithFile:(NSString*)path ofImageDataType:(enum ImageDataType)type;

-(void)dealloc;

@end

