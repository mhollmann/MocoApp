/*
 *  EDIsisImage.cpp
 *  BARTApplication
 *
 *  Created by Lydia Hellrung on 4/20/11.
 *  Copyright 2011 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
 *
 */


#import "EDIsisImage.h"




EDIsisImage::EDIsisImage(const isis::data::Image &src) : isis::data::Image(src)
{
	//clear the set table to make clear it's not an usual image
    set.clear();
    
    std::vector<boost::shared_ptr<isis::data::Chunk> >::iterator itVector;
    for (itVector = lookup.begin(); itVector != lookup.end(); itVector++) {
        (**itVector).join(src);
    }
    
}

void EDIsisImage::appendVolume(isis::data::Image &img){
    
//    std::vector<isis::data::Chunk > chVector = img.copyChunksToVector();
//    std::vector<isis::data::Chunk >::iterator itVector;
//    for (itVector = chVector.begin(); itVector != chVector.end(); itVector++) {
//        (*itVector).join(img);
//    }
    
	BOOST_FOREACH( isis::data::Chunk ch, img.copyChunksToVector()){
        boost::shared_ptr<isis::data::Chunk> p(new isis::data::Chunk(ch));
 		lookup.push_back(p);
	}
	isis::util::FixedVector<size_t,4> sizeVector=getSizeAsVector();
	sizeVector[isis::data::timeDim] += 1;
	const size_t sizeForInit[4] = {sizeVector[0], sizeVector[1], sizeVector[2], sizeVector[3]};
	init(sizeForInit);
 	//set clean to avoid reIndex() when accessing the image
    printf("the clean variable says: %d\n", clean);
	clean = true;
}

void EDIsisImage::prepareToWrite()
{
    printf("the clean variable says: %d\n", clean);
    clean = false;
}


EDIsisImage::~EDIsisImage()
{
    
}

//template<typename T> std::pair<T, T> EDIsisImage::getMinMaxAs()const {
  //  return getMinMaxAs<T>();
//}
