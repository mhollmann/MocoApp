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
#include <sys/time.h>


MocoDataLogger* MocoDataLogger::mLoggerInstance = NULL;



//can only be reached from inside this class
MocoDataLogger::MocoDataLogger()
{
    this->mMocoParamArray        = new MocoDataLogger::mocoTransformParametersStruct[MOCOLOG_MAX_NUMBER_SCANS];
    this->mMocoParamArrayIndex   = 0;
    
    this->mMocoAppLogArray       = new string[MOCOLOG_MAX_NUMBER_APPLOGITEMS];
    this->mMocoAppLogArrayIndex  = 0;
    
    this->mMocoParamsLogfileName = "-";
    this->mMocoAppLogfileName    = "-";
}


MocoDataLogger::~MocoDataLogger()
{
    delete[] this->mMocoParamArray;
}



MocoDataLogger* MocoDataLogger::getInstance()
{
    if(!mLoggerInstance)
    {
        mLoggerInstance = new MocoDataLogger;
    }
    
    return mLoggerInstance;
}


void MocoDataLogger::setParamsLogFileName(string mocoParamsLogfile)
{
    if (mMocoParamsLogfileName.compare(string("-")) != 0)
    {
        //MH FIXME todo
    }else
    {
        this->mMocoParamsLogfileName = mocoParamsLogfile;
    }
}


void MocoDataLogger::setAppLogFileName(string mocoAppLogfile)
{
    if (mMocoAppLogfileName.compare(string("-")) != 0)
    {
        //MH FIXME todo
        cout << "Warning: AppLogFileName is already set to:" << this->mMocoAppLogfileName << std::endl;
    }else
    {
        this->mMocoAppLogfileName = mocoAppLogfile;
    }
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


void MocoDataLogger::addMocoAppLogentry(string logEntry)
{
    
    struct timeval actTime;
    gettimeofday(&actTime, NULL);
    
    time_t currtime  = actTime.tv_sec;
    tm *t = localtime(&currtime);
    
    char msg[10+logEntry.length()];
    
    sprintf(msg, "%02d:%02d:%02d:%04d %s", t->tm_hour, t->tm_min, t->tm_sec, actTime.tv_usec/1000, logEntry.c_str());
    
    this->mMocoAppLogArray[this->mMocoAppLogArrayIndex] = string(msg);
    this->mMocoAppLogArrayIndex++;
}

void MocoDataLogger::dumpMocoParamsToLogfile(void)
{
    FILE * pFile;
    pFile = std::fopen(this->mMocoParamsLogfileName.c_str(),"w+");
    if (pFile==NULL)
    {
        cout << "Unable to open file: " << this->mMocoParamsLogfileName << std::endl;
    }
    else
    {
        cout << "Writing data to file: " << this->mMocoParamsLogfileName << std::endl;
        
        for(int i=0; i<=this->mMocoParamArrayIndex-1; i++)
        {
            std::fprintf(pFile, "%3.4f %3.4f %3.4f %3.4f %3.4f %3.4f\n",
                         this->mMocoParamArray[i].transX, this->mMocoParamArray[i].transY, this->mMocoParamArray[i].transZ,
                         this->mMocoParamArray[i].rotX, this->mMocoParamArray[i].rotY, this->mMocoParamArray[i].rotZ);
        }
        std::fclose(pFile);
    }
}


void MocoDataLogger::dumpMocoAppLogsToLogfile(void)
{
    FILE * pFile;
    pFile = std::fopen(this->mMocoAppLogfileName.c_str(),"w+");
    if (pFile==NULL)
    {
        cout << "Unable to open file: " << this->mMocoAppLogfileName << std::endl;
    }
    else
    {
        cout << "Writing data to file: " << this->mMocoAppLogfileName << std::endl;
        
        for(int i=0; i<=this->mMocoAppLogArrayIndex-1; i++)
        {
            std::fprintf( pFile, "%s\n", this->mMocoAppLogArray[i].c_str());
        }
        std::fclose(pFile);
    }
}


void MocoDataLogger::appendLineToFile(string fileName, string lineToWrite)
{
    
    ofstream txtFile;
    txtFile.open(fileName.c_str(), ios::out | ios::app);
    if(txtFile.is_open())
    {
        txtFile << lineToWrite << "\n";
        txtFile.close();
    }
    else std::cout << "Unable to open file: " << fileName << std::endl;
    
}