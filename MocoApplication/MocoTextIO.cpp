//
//  MocoTextIO.cpp
//  MocoApplication
//
//  Created by willi on 8/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include "MocoTextIO.h"
#include <fstream>

void MocoTextIO::appendLineToFile(string fileName, string lineToWrite)
{    
    
    ofstream txtFile;
    txtFile.open(fileName.c_str(), ios::out | ios::app);
    if(txtFile.is_open())
    {
        txtFile << lineToWrite << "\n";
        txtFile.close();
    }
    else cout << "Unable to open file: " << fileName << std::endl;
    
}

void MocoTextIO::appendLineToStream(ofstream *fileStream, string lineToWrite)
{    
    
    if (fileStream->is_open())
    {
        //fileStream->write(lineToWrite.c_str(), 30);
        //fileStream << lineToWrite << "\n";
    }
    else cout << "Unable to open file: " << fileStream << std::endl;
    
}