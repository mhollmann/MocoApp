//
//  MocoTextIO.h
//  MocoApplication
//
//  Created by Maurice Hollmann on 04/24/12.
//  Copyright (c) 2012 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//
#ifndef MocoApplication_MocoTextIO_h
#define MocoApplication_MocoTextIO_h
#endif

#include <iostream>



using namespace std;

class MocoTextIO
{

    
public:
    
    //This appends a line to a file 
    //Caution: this is slow because it is opening the file to write each time
    //for fast acess use "appendLineToStream"
    void appendLineToFile(string fileName, string lineToWrite);
    
    //This adds a line to a stream
    void appendLineToStream(ofstream *fileStream, string lineToWrite);    
    
    
};