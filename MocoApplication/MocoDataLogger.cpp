//
//  MocoDataLogger.cpp
//  MocoApplication
//
//  Created by Maurice Hollmann on 10/8/12.
//
//

#include "MocoDataLogger.h"
#include <fstream>
#include <stdio.h>


MocoDataLogger::MocoDataLogger(string mocoParamsLogfile, string appLogfile)
{
    
    this->mMocoParamsLogfile = mocoParamsLogfile;
    this->mMocoAppLogfile    = appLogfile;
    
    this->mMocoParamArray      = new MocoDataLogger::mocoTransformParametersStruct[MOCOLOG_MAX_NUMBER_SCANS];
    this->mMocoParamArrayIndex = 0;
}


MocoDataLogger::~MocoDataLogger()
{
    delete[] this->mMocoParamArray;
}



void MocoDataLogger::addMocoParams(float tX, float tY, float tZ, float rX, float rY, float rZ)
{
    this->mMocoParamArray[this->mMocoParamArrayIndex].transX = tX;
    this->mMocoParamArray[this->mMocoParamArrayIndex].transY = tY;
    this->mMocoParamArray[this->mMocoParamArrayIndex].transZ = tZ;
    this->mMocoParamArray[this->mMocoParamArrayIndex].rotX = rX;
    this->mMocoParamArray[this->mMocoParamArrayIndex].rotY = rY;
    this->mMocoParamArray[this->mMocoParamArrayIndex].rotZ = rZ;
    this->mMocoParamArrayIndex++;
}


void MocoDataLogger::dumpMocoParamsToLogfile(void)
{
    FILE * pFile;
    pFile = std::fopen(this->mMocoParamsLogfile.c_str(),"w+");
    if (pFile==NULL)
    {
        cout << "Unable to open file: " << this->mMocoParamsLogfile << std::endl;
    }
    else
    {
        for(int i=0; i<=this->mMocoParamArrayIndex-1; i++)
        {
            std::fprintf(pFile, "%3.4f %3.4f %3.4f %3.4f %3.4f %3.4f\n",
                         this->mMocoParamArray[i].transX, this->mMocoParamArray[i].transY, this->mMocoParamArray[i].transZ,
                         this->mMocoParamArray[i].rotX, this->mMocoParamArray[i].rotY, this->mMocoParamArray[i].rotZ);
        }
        std::fclose(pFile);
    }
}



void MocoDataLogger::appendLineToFile(string fileName, string lineToWrite)
{
    
    std::cout << "p logfile: " << mMocoParamsLogfile << std::endl;
    std::cout << "value: " <<  mMocoParamArray[this->mMocoParamArrayIndex-1].rotZ << std::endl;
    
    ofstream txtFile;
    txtFile.open(fileName.c_str(), ios::out | ios::app);
    if(txtFile.is_open())
    {
        txtFile << lineToWrite << "\n";
        txtFile.close();
    }
    else std::cout << "Unable to open file: " << fileName << std::endl;
    
}