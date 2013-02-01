//
//  MocoDataLogger.h
//  MocoApplication
//
//  Created by Maurice Hollmann on 10/8/12.
//
//

#ifndef __MocoApplication__MocoDataLogger__
#define __MocoApplication__MocoDataLogger__

#include <iostream>

#endif /* defined(__MocoApplication__MocoDataLogger__) */


#ifndef MOCOLOG_MAX_NUMBER_SCANS
#define MOCOLOG_MAX_NUMBER_SCANS 5000
#endif
#ifndef MOCOLOG_MAX_NUMBER_APPLOGITEMS
#define MOCOLOG_MAX_NUMBER_APPLOGITEMS 50000
#endif

using namespace std;


//This class is a singleton, the instance is provided via getInstance()
class MocoDataLogger
{
    
    struct mocoTransformParametersStruct
    {
        float transX;
        float transY;
        float transZ;
        float rotX;
        float rotY;
        float rotZ;
    };
    
private:
    
    static MocoDataLogger* mLoggerInstance;
    
    string mMocoParamsLogfileName;
    string mMocoAppLogfileName;
    
    static const string STANDARD_MOCOPARAMS_LOGFILENAME;
    static const string STANDARD_APP_LOGFILENAME;
    
    struct mocoTransformParametersStruct *mMocoParamArray;
    int    mMocoParamArrayIndex;
    
    string *mMocoAppLogArray;
    int    mMocoAppLogArrayIndex;
    
    //the constructor is private to avoid access from outside
    MocoDataLogger();
    
    //the destructor
    ~MocoDataLogger();
    
    
public:
    
    /**
     * The class is a singleton and the global instance is returned by this function.
     * If the instance does not exist it is created. 
     *
     * \param mocoParamsLogfile  Complete path to file that stores motion correction params.
     * \param appLogfile         Complete path to file that stores log-information.
     *
     */
    static MocoDataLogger* getInstance();
    
    
    
    /**
     * Sets the log-filename for the results (parameters) of the motion correction.
     *
     * \param mocoParamsLogfile  Complete path to file that stores motion correction params.
     *
     */
    void setParamsLogFileName(string mocoParamsLogfile);
   
    
    /**
     * Sets the log-filename for the application log-messages. Setting is can not be modified
     * after th efirst valid call to avoid several logfile locations.
     *
     * \param appLogfile  Complete path to file that stores log-information.
     *
     */
    void setAppLogFileName(string appLogfile);
    
    
     /**
     * This appends a line to a given file.
     * Caution: this is slow because it is opening the file to write each time it is called.
     * For fast access use "addMocoParams" and "dumpMocoParamsToLogfile".
     *
     * \param fileName     Complete path to file that the given line should be appended to.
     * \param lineToWrite  Line of text that should be appended.
     *
     */
    void appendLineToFile(string fileName, string lineToWrite);

    

    /**
     * Adds moco params to the stored data.
     *
     * \param tX  translation in X direction
     * \param tY  translation in Y direction
     * \param tZ  translation in Z direction
     * \param rX  rotation about X-axis
     * \param rY  rotation about Y-axis
     * \param rZ  rotation about Z-axis
     */
    void addMocoParams(float tX, float tY, float tZ, float rX, float rY, float rZ);
   
    
    /**
     * Adds a string to the stored log messages. These have to be dumped before the app is closed, otherwise they are lost.
     * Stored format is: month/day hour:minute:sec:millisec logEntry
     *
     * \param logEntry  the log message that should be stored 
     */
    void addMocoAppLogentry(string logEntry);
    
    
    /**
     * Dumps the stored data to the logfile set in setParamsLogFileName.
     * If the file already exists it is overwritten.
     *
     * Format of resulting file (3.4f):
     *
     * transX transY transZ rotX rotY rotZ\n
     * transX transY transZ rotX rotY rotZ\n
     * ...
     */
    void dumpMocoParamsToLogfile(void);

    
    /**
     * Dumps the stored application log message (by appending it) to the logfile set in setAppLogFileName.
     * The actually stored log-messages are deleted. 
     *
     */
    void dumpMocoAppLogsToLogfile(void);
    
};