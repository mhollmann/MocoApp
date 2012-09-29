/*
 *  EDIsisImage.h
 *  BARTApplication
 *
 *  Created by Lydia Hellrung on 4/20/11.
 *  Copyright 2011 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
 *
 */


#include <isis/DataStorage/image.hpp>


class EDIsisImage : public isis::data::Image{
	
public:
	EDIsisImage(const isis::data::Image &src);
	virtual ~EDIsisImage();
	void appendVolume(isis::data::Image &src);
    void prepareToWrite();
    
};



