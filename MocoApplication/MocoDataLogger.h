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



using namespace std;

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

    string mMocoParamsLogfile;
    string mMocoAppLogfile;
    struct mocoTransformParametersStruct *mMocoParamArray;
    int    mMocoParamArrayIndex;
    
public:
    
    /**
     * Constructor.
     * If the file already exists it is overwritten.
     *
     * \param mocoParamsLogfile  Complete path to file that stores motion correction params.
     * \param appLogfile         Complete path to file that stores log-information [unused now].
     *
     */
    MocoDataLogger(string mocoParamsLogfile, string appLogfile);
    
    
    /**
     * Destructor.
    */
    ~MocoDataLogger();
    
    
     /**
     * This appends a line to a given file.
     * Caution: this is slow because it is opening the file to write each time it is called.
     * For fast acess use "addMocoParams" and "dumpMocoParamsToLogfile".
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
     * Dumps the stored data to the logfile given in constructor.
     * If the file already exists it is overwritten.
     *
     * Format of resulting file (3.4f):
     *
     * transX transY transZ rotX rotY rotZ\n
     * transX transY transZ rotX rotY rotZ\n
     * ...
     */
    void dumpMocoParamsToLogfile(void);

};