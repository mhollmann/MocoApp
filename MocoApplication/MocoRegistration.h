//
//  MocoRegistration.h
//  MotionCorrection
//
//  Created by Maurice Hollmann on 04/24/12.
//  Copyright (c) 2012 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//
//
//


#import <Foundation/Foundation.h>

//moco properties
#import "MocoRegistrationProperty.h"

//isis data
#import "EDDataElementIsis.h"

//itk import
#import "itkImage.h"
#import "itkInterpolateImageFunction.h"
#import "itkDiscreteGaussianImageFilter.h"
#import "itkImageRegistrationMethod.h"
#import "itkMeanSquaresImageToImageMetric.h"
#import "itkMeanSquaresHistogramImageToImageMetric.h"
#import "itkMeanReciprocalSquareDifferenceImageToImageMetric.h"

#include "itkVersorRigid3DTransform.h"
#include "itkCenteredTransformInitializer.h"
#include "itkVersorRigid3DTransformOptimizer.h"

#include "itkResampleImageFilter.h"
#include "itkImageMaskSpatialObject.h"


const unsigned int Dimension3D = 3;
const unsigned int Dimension4D = 4;
typedef float InPixelType;
typedef unsigned char MaskPixelType;

typedef itk::Image< InPixelType,  Dimension3D >   FixedImageType3D;
typedef itk::Image< InPixelType,  Dimension3D >   MovingImageType3D;
typedef itk::Image< InPixelType,  Dimension4D >   ImageType4D;

typedef itk::Image< MaskPixelType,  Dimension3D >   MaskImageType3D;
typedef itk::ImageMaskSpatialObject< 3 > MaskType3D;

typedef itk::DiscreteGaussianImageFilter< FixedImageType3D, MovingImageType3D > DiscreteGaussianImageFilterType;
typedef itk::InterpolateImageFunction< MovingImageType3D, double > InterpolatorType;
typedef itk::ImageRegistrationMethod< FixedImageType3D, MovingImageType3D > MocoRegistrationType;

//metric: set fixed to meanSquares for now
typedef itk::MeanSquaresImageToImageMetric< FixedImageType3D, MovingImageType3D > MocoMetricType;

typedef itk::VersorRigid3DTransform< double > MocoTransformType;
typedef itk::VersorRigid3DTransformOptimizer MocoOptimizerType;

typedef itk::CenteredTransformInitializer< MocoTransformType, FixedImageType3D, MovingImageType3D >  MocoTransformInitializerType;

typedef MocoTransformType::VersorType  MocoVersorType;
typedef MocoVersorType::VectorType     MocoVectorType;

typedef itk::ResampleImageFilter< MovingImageType3D, FixedImageType3D >  MocoResampleFilterType;




/*  
 *  Needed for observation of the registration process.
 */
class CommandIterationUpdate : public itk::Command 
{
public:
    typedef  CommandIterationUpdate   Self;
    typedef  itk::Command             Superclass;
    typedef  itk::SmartPointer<Self>  Pointer;
    itkNewMacro( Self );
    
    typedef itk::VersorRigid3DTransformOptimizer OptimizerType;
    typedef   const OptimizerType *              OptimizerPointer;
    
    double bestValue;
    bool logging;
    OptimizerType::ParametersType bestParameters;
    
    
protected:
    CommandIterationUpdate() {};
    
    
    void Execute(itk::Object *caller, const itk::EventObject & event)
    {
        Execute( (const itk::Object *)caller, event);
    }
    
    void Execute(const itk::Object * object, const itk::EventObject & event)
    {
        OptimizerPointer optimizer = 
        dynamic_cast< OptimizerPointer >( object );
        if( ! itk::IterationEvent().CheckEvent( &event ) )
        {
            return;
        }
        
        double value = optimizer->GetValue();
        
        if (logging) { 
            std::cout << optimizer->GetCurrentIteration() + 1 << "   ";
            std::cout << value << "   ";
        }
        if ( optimizer->GetCurrentIteration() > 0 && value < bestValue ) {
            bestValue = value;
            OptimizerType::ParametersType param(optimizer->GetCurrentPosition());
            bestParameters = param;
        }
        if (logging) {
            std::cout << optimizer->GetCurrentPosition();
            std::cout << std::endl;
        }
	}
};


/**
 * MocoRegistration provides functionality for the Motion-Correction of 3D and 4D fMRI images. 
 *
 * The interface works with image data encapsulated by EDDataElement or with 3D float itkImages .
 * Initialization sets default registration properties.
 *
 */
@interface MocoRegistration : NSObject {

@protected
    MocoRegistrationProperty*     m_registrationProperty;
    
    InterpolatorType::Pointer     m_registrationInterpolator;    
    MocoMetricType::Pointer       m_metric ;
    MocoOptimizerType::Pointer    m_optimizer;
    MocoTransformType::Pointer    m_transform;
       
    CommandIterationUpdate::Pointer m_observer;
    
    MocoResampleFilterType::Pointer m_resampler;
    InterpolatorType::Pointer       m_resampleInterpolator;
    
    FixedImageType3D::Pointer m_referenceImgITK3D;
    FixedImageType3D::Pointer m_referenceImgITK3DSmoothed;
    
    
    MaskImageType3D::Pointer m_referenceImgMask;
    MaskType3D::Pointer      m_referenceMask;
    MaskType3D::Pointer      m_movingMask;
    
}



/**
 * Initialize MocoRegistration with a given MocoRegistrationProperty object.
 *
 * \param regProperty  The MocoRegistrationProperty object.
 *
 */
-(id)initWithRegistrationProperty:(MocoRegistrationProperty*)regProperty;



/**
 * Set the image for the reference (stationary image) by given EDDataElement.
 *
 * \param dataElement The referene image as EDDataElement.
 *
 */
-(void)setReferenceImageWithEDDataElement:(EDDataElement*)dataElement;


/**
 * Set the image for the reference (stationary image) by given ITKImage.
 *
 * \param itkImage The referene image as ITKImage.
 *
 */
-(void)setReferenceImageWithITKImage:(FixedImageType3D::Pointer)itkImage;


/**
 * Set the image for the reference (stationary image) by image filename.
 * Just working with .nii images at the moment. 
 *
 * \param filePath  Complete path to image file
 *
 */
-(void)setReferenceImageWithFile:(NSString*)filePath;




/**
 * Align an EDDataElement to the reference image that was set for registration.
 * Be sure your registrationProperty and reference image are set before calling this function.
 * The returned transformation can be used to resample an EDDataelement using resampleMovingEDDataElement.
 *
 * \param movingDataElement  EDDataElement that is registered to reference
 *
 * \return                   A MocoTransformType describing the transformation of input 
 *                           to reference image. transformation: [rotX rotY rotZ transX transY transZ]
 *
 */
-(MocoTransformType::Pointer)alignEDDataElementToReference:(EDDataElement*)movingDataElement;



/**
 * Align an itk-image to the reference image that was set for registration.
 * Be sure your registrationProperty and reference image are set before calling this function.
 * The returned transformation can be used to resample an itk-image or an EDDataelement using resampleMovingEDDataElement.
 *
 * \param movingITKImage     ITKImage that is registered to reference
 *
 * \return                   A MocoTransformType describing the transformation of input
 *                           to reference image. Transformation: [rotX rotY rotZ transX transY transZ]
 *
 */
-(MocoTransformType::Pointer)alignITKImageToReference:(MovingImageType3D::Pointer)movingITKImage;



/**
 * Resamples the given EDDataElement according to the settings of the global registrationProperty.
 * The transformation given here is expected to be the result of "alignEDDataElementToReference".
 * Important: Input is 3D output is 4D!
 *
 * \param movingDataElement  EDDataElement (3D) that is resampled using transform
 * \param transform          Transformation that is used for resampling
 *
 * \return                   EDDataElement (4D) holding the transformed data (size: [sizeInput[0], [sizeInput[1], [sizeInput[2], 1])
 */
-(EDDataElement*)resampleMovingEDDataElement:(EDDataElement*)movingDataElement 
                               withTransform:(MocoTransformType::Pointer)transform;




/**
 * Class method that retrieves an EDDataElement from a given image data file (file types supported depend on EDDataElement).
 *
 * \param filePath  Complete path to an image file.
 *
 * \return          EDDataElement (4D) holding the image data
 */
+(EDDataElement*)getEDDataElementFromFile:(NSString*)filePath;


-(void)dealloc;


@end
