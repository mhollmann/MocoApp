//
//  EDDataElementIsisRealTime.h
//  BARTApplication
//
//  Created by Lydia Hellrung on 3/30/11.
//  Copyright 2011 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EDDataElement.h"
#import "DataStorage/image.hpp"
#include <map.h>
#include "EDIsisImage.h"


//MH FIXME
#include "Adapter/itkAdapter.hpp"


@interface EDDataElementIsisRealTime : EDDataElement {
	//isis::data::Image mIsisImage;
	map<size_t, std::vector<boost::shared_ptr<isis::data::Chunk> > > mAllDataMap;
	EDIsisImage *mIsisImage;
    //size_t mRepetitionNumber;
	isis::util::PropertyMap mPropMapImage;
    
    //MH FIXME
    isis::adapter::itkAdapter* mITKAdapter;
}

-(void)appendVolume:(isis::data::Image)img;

@end
