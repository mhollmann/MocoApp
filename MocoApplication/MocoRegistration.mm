//
//  MocoRegistration.mm
//  MotionCorrection
//
//  Created by Maurice Hollmann on 4/20/12.
//  Copyright (c) 2012 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import "MocoRegistration.h"

//itk registration
#include "itkImageRegistrationMethod.h"

//metric include
#include "itkMeanSquaresImageToImageMetric.h"

//threshold filter include for masking
#include "itkOtsuThresholdImageFilter.h"

//interpolator includes
#include "itkLinearInterpolateImageFunction.h"
#include "itkNearestNeighborInterpolateImageFunction.h"
#include "itkBSplineInterpolateImageFunction.h"
#include "itkWindowedSincInterpolateImageFunction.h"

#include "itkCastImageFilter.h"
#include "itkImageRegionConstIterator.h"
#include "itkImageRegionIterator.h"

//for 3D to 4D conversion of itk images
#include "itkTileImageFilter.h"

//io
#include "itkImageFileReader.h"
#include "itkImageFileWriter.h"



@interface MocoRegistration (PrivateMethods)

/**
 * Mask the given itk image file according to a segmentation of background and image contentent, i.e. brain.
 * Here the itk::OtsuThresholdImageFilter is used, which does a histogram based search for the threshold.
 *
 * \param itkImage  FixedImageType3D::Pointer that should be masked.
 *
 * \return          MaskImageType3D::Pointer that holds the mask image.
 *                  This is an itk::image with zeros for outside mask voxels
 *                  and ones for inside mask voxels.
 *
 */
-(MaskImageType3D::Pointer)getMaskImageWithITKImage:(FixedImageType3D::Pointer)itkImage;

@end


@implementation MocoRegistration


- (id)init
{
    self = [super init];
    if (self) {
        
        MocoRegistrationProperty *rProperty = [[MocoRegistrationProperty alloc] init];
        
        //will set properties and initialize member vars
        [self initRegistrationWithRegistrationProperty: rProperty];
        
    }
    
    return self;
}



- (id)initWithRegistrationProperty:(MocoRegistrationProperty *)regProperty
{
    self = [super init];
    if (self) {
        
        //will set properties and initialize member vars
        [self initRegistrationWithRegistrationProperty: regProperty];
    
    }
    
    return self;
}


- (void) initRegistrationWithRegistrationProperty:(MocoRegistrationProperty *)regProperty
{
    
    //set the registration method
    self->m_registration = MocoRegistrationType::New();
    
    //create metric, optimizer, and transform 
    self->m_metric    = MocoMetricType::New();
    self->m_optimizer = MocoOptimizerType::New();
    self->m_transform = MocoTransformType::New();
    
    //set metric params
    self->m_metric->SetNumberOfThreads(regProperty.NumberOfThreads);
    
    //set global threadnum
    self->m_metric->GetThreader()->SetGlobalMaximumNumberOfThreads(regProperty.NumberOfThreads);
    self->m_metric->GetThreader()->SetGlobalDefaultNumberOfThreads(regProperty.NumberOfThreads);
   
    
    self->m_registration->SetMetric( self->m_metric );
    self->m_registration->SetOptimizer( self->m_optimizer );
    self->m_registration->SetTransform( self->m_transform );
   
    
    //Define available interpolators
    typedef itk::LinearInterpolateImageFunction< MovingImageType3D, double > InterpolatorType_Linear;
    typedef itk::BSplineInterpolateImageFunction< MovingImageType3D, double > InterpolatorType_BSpline;
    typedef itk::WindowedSincInterpolateImageFunction< MovingImageType3D, 2 > InterpolatorType_Sinc2;
    typedef itk::WindowedSincInterpolateImageFunction< MovingImageType3D, 3 > InterpolatorType_Sinc3;
    typedef itk::WindowedSincInterpolateImageFunction< MovingImageType3D, 4 > InterpolatorType_Sinc4;
    typedef itk::WindowedSincInterpolateImageFunction< MovingImageType3D, 5 > InterpolatorType_Sinc5;
    typedef itk::WindowedSincInterpolateImageFunction< MovingImageType3D, 6 > InterpolatorType_Sinc6;
    typedef itk::NearestNeighborInterpolateImageFunction< MovingImageType3D, double > InterpolatorType_NN;    
    
    
    //set the interpolation pointer for registrationInterpolation
    switch ( regProperty.RegistrationInterpolationMode )
    {
        case LINEAR:
        {
            InterpolatorType_Linear::Pointer pInterpolator   = InterpolatorType_Linear::New();
            self->m_registrationInterpolator = pInterpolator;
            break;
        }
        case BSPLINE2:
        {
            InterpolatorType_BSpline::Pointer pInterpolator = InterpolatorType_BSpline::New();
            pInterpolator->SetSplineOrder(2);
            self->m_registrationInterpolator = pInterpolator;
            break;
        }
        case BSPLINE3:
        {
            InterpolatorType_BSpline::Pointer pInterpolator = InterpolatorType_BSpline::New();
            pInterpolator->SetSplineOrder(3);
            self->m_registrationInterpolator = pInterpolator;
            break;
        }
        case BSPLINE4:
        {
            InterpolatorType_BSpline::Pointer pInterpolator = InterpolatorType_BSpline::New();
            pInterpolator->SetSplineOrder(4);
            self->m_registrationInterpolator = pInterpolator;
            break;
        }       
        case BSPLINE5:
        {
            InterpolatorType_BSpline::Pointer pInterpolator = InterpolatorType_BSpline::New();
            pInterpolator->SetSplineOrder(5);
            self->m_registrationInterpolator = pInterpolator;
            break;
        }
        case SINC2:
        {
            InterpolatorType_Sinc2::Pointer pInterpolator = InterpolatorType_Sinc2::New();
            self->m_registrationInterpolator = pInterpolator;
            break;
        }
        case SINC3:
        {
            InterpolatorType_Sinc3::Pointer pInterpolator = InterpolatorType_Sinc3::New();
            self->m_registrationInterpolator = pInterpolator;
            break;
        }
        case SINC4:
        {
            InterpolatorType_Sinc4::Pointer pInterpolator = InterpolatorType_Sinc4::New();
            self->m_registrationInterpolator = pInterpolator;
            break;
        }
        case SINC5:
        {
            InterpolatorType_Sinc5::Pointer pInterpolator = InterpolatorType_Sinc5::New();
            self->m_registrationInterpolator = pInterpolator;
            break;
        }
        case SINC6:
        {
            InterpolatorType_Sinc6::Pointer pInterpolator = InterpolatorType_Sinc6::New();
            self->m_registrationInterpolator = pInterpolator;
            break;
        }        
        case NN:
        {
            InterpolatorType_NN::Pointer pInterpolator  = InterpolatorType_NN::New();
            self->m_registrationInterpolator = pInterpolator;
            break;
        }
        default:
        {
            std::cout << "The given Interpolator-Type is not known!" << std::endl;
            exit(1);
            break;
        }
    }// end switch
    
    //MHFIXME: multithreading for interpolator?
    //interpolator->SetNumberOfThreads(2);

    self->m_registration->SetInterpolator( self->m_registrationInterpolator );
        
     
    
    //*** Initialize optimizer ***
    typedef MocoOptimizerType::ScalesType MocoOptimizerScalesType;
    MocoOptimizerScalesType optimizerScales( m_transform->GetNumberOfParameters() );
    
    optimizerScales[0] = 1.0;//rotationScale
    optimizerScales[1] = 1.0;//rotationScale
    optimizerScales[2] = 1.0;//rotationScale
    optimizerScales[3] = regProperty.RegistrationParameters[0]; //translationScale
    optimizerScales[4] = regProperty.RegistrationParameters[0]; //translationScale
    optimizerScales[5] = regProperty.RegistrationParameters[0]; //translationScale
    self->m_optimizer->SetScales( optimizerScales );
    self->m_optimizer->SetMaximumStepLength( regProperty.RegistrationParameters[1] );  //maxStepLength Default AFNI: 0.7 * voxel size
    self->m_optimizer->SetMinimumStepLength( regProperty.RegistrationParameters[2] );  //minStepLength
    self->m_optimizer->SetNumberOfIterations( regProperty.NumberOfIterations ); //numIterations Default AFNI: 19

    
    NSLog(@"Number of Iterations %d", regProperty.NumberOfIterations);
    
    //*** Create the Command observer and register it with the optimizer ***
    self->m_observer = CommandIterationUpdate::New();
    self->m_observer->bestValue = std::numeric_limits<double>::max();
    
    if( regProperty.LoggingLevel > 2 )
    {
      self->m_observer->logging = true;
    }
    else
    {
      self->m_observer->logging = false;
    }
    
    self->m_optimizer->AddObserver( itk::IterationEvent(), m_observer );
    
    
    //+++ Resampling parameters +++
    self->m_resampler = MocoResampleFilterType::New();
    
    
    //set the interpolation pointer for registrationInterpolation
    switch ( regProperty.ResamplingInterpolationMode )
    {
        case LINEAR:
        {
            InterpolatorType_Linear::Pointer rpInterpolator   = InterpolatorType_Linear::New();
            self->m_resampleInterpolator = rpInterpolator;
            break;
        }
        case BSPLINE2:
        {
            InterpolatorType_BSpline::Pointer rpInterpolator = InterpolatorType_BSpline::New();
            rpInterpolator->SetSplineOrder(2);
            self->m_resampleInterpolator = rpInterpolator;
            break;
        }
        case BSPLINE3:
        {
            InterpolatorType_BSpline::Pointer rpInterpolator = InterpolatorType_BSpline::New();
            rpInterpolator->SetSplineOrder(3);
            self->m_resampleInterpolator = rpInterpolator;
            break;
        }
        case BSPLINE4:
        {
            InterpolatorType_BSpline::Pointer rpInterpolator = InterpolatorType_BSpline::New();
            rpInterpolator->SetSplineOrder(4);
            self->m_resampleInterpolator = rpInterpolator;
            break;
        }       
        case BSPLINE5:
        {
            InterpolatorType_BSpline::Pointer rpInterpolator = InterpolatorType_BSpline::New();
            rpInterpolator->SetSplineOrder(5);
            self->m_resampleInterpolator = rpInterpolator;
            break;
        }
        case SINC2:
        {
            InterpolatorType_Sinc2::Pointer rpInterpolator = InterpolatorType_Sinc2::New();
            self->m_resampleInterpolator = rpInterpolator;
            break;
        }
        case SINC3:
        {
            InterpolatorType_Sinc3::Pointer rpInterpolator = InterpolatorType_Sinc3::New();
            self->m_resampleInterpolator = rpInterpolator;
            break;
        }
        case SINC4:
        {
            InterpolatorType_Sinc4::Pointer rpInterpolator = InterpolatorType_Sinc4::New();
            self->m_resampleInterpolator = rpInterpolator;
            break;
        }
        case SINC5:
        {
            InterpolatorType_Sinc5::Pointer rpInterpolator = InterpolatorType_Sinc5::New();
            self->m_resampleInterpolator = rpInterpolator;
            break;
        }
        case SINC6:
        {
            InterpolatorType_Sinc6::Pointer rpInterpolator = InterpolatorType_Sinc6::New();
            self->m_resampleInterpolator = rpInterpolator;
            break;
        }        
        case NN:
        {
            InterpolatorType_NN::Pointer rpInterpolator  = InterpolatorType_NN::New();
            self->m_resampleInterpolator = rpInterpolator;
            break;
        }
        default:
        {
            std::cout << "The given Resampling Interpolator-Type is not known!" << std::endl;
            exit(1);
            break;
        }
    }// end switch
        
    
    //if everything worked out set the property
    self->m_registrationProperty = regProperty;
    
    
}// end setRegistrationProperty




- (void)setReferenceEDDataElementWithFile:(NSString *)filePath
{
    EDDataElement *refImg = [MocoRegistration getEDDataElementFromFile: filePath];
    
    [self setReferenceEDDataElement: refImg];
    
    
}// end setReferenceEDDataElementWithFile




- (void)setReferenceEDDataElement:(EDDataElement *)dataElement
{
    
    
    //reference is always 3D
    
    self->m_referenceImgITK3D = [dataElement asITKImage];
    
    if( self->m_registrationProperty.LoggingLevel > 1 ){
        
        ITKImage::SizeType iSize = self->m_referenceImgITK3D->GetLargestPossibleRegion().GetSize();
        std::cout << " Loaded image with size:    = " << iSize << std::endl;
        
    }
    
    //++++ Smoothing ++++ 
    if( self->m_registrationProperty.Smoothing ){        
        
        DiscreteGaussianImageFilterType::Pointer dgImageFilter = DiscreteGaussianImageFilterType::New();
        
        dgImageFilter->SetInput( self->m_referenceImgITK3D );
        dgImageFilter->SetVariance( self->m_registrationProperty.SmoothingSigma );
        dgImageFilter->SetMaximumKernelWidth( self->m_registrationProperty.SmoothingKernelWidth );
        dgImageFilter->SetUseImageSpacing(true);
        dgImageFilter->SetMaximumError(0.05);
        
        dgImageFilter->Update();
        
        self->m_referenceImgITK3DSmoothed = dgImageFilter->GetOutput();
        
     }
    
    //MH FIXME: Check if metric exists in this call before mask is set
    //++++ Masking if needed ++++
    if( self->m_registrationProperty.MaskImagesForRegistration ){   
        self->m_referenceImgMask = [self getMaskImageWithITKImage:self->m_referenceImgITK3D];
    
        self->m_referenceMask = MaskType3D::New();
        self->m_movingMask    = MaskType3D::New();
    
        self->m_referenceMask->SetImage(self->m_referenceImgMask);
        self->m_movingMask->SetImage(self->m_referenceImgMask);
    
        self->m_metric->SetFixedImageMask(self->m_referenceMask);
        self->m_metric->SetMovingImageMask(self->m_movingMask);
    }
    
    
    /*
    
    MaskImageType3D::IndexType pIndex2;
    pIndex2[0] = 1;
    pIndex2[1] = 1;
    pIndex2[2] = 1;
    //update needs to be called to get access to data
    self->m_referenceImgMask->DataObject::Update();
    MaskImageType3D::PixelType pixelValue2 = self->m_referenceImgMask->GetPixel( pIndex2 );
    NSLog(@"Pixel value at 1,1,1 is: %d", pixelValue2);

    
    MaskImageType3D::IndexType pIndex;
    pIndex[0] = 20;
    pIndex[1] = 20;
    pIndex[2] = 20;
    //update needs to be called to get access to data
    self->m_referenceImgMask->DataObject::Update();
    MaskImageType3D::PixelType pixelValue = self->m_referenceImgMask->GetPixel( pIndex );
    NSLog(@"Pixel value  at 20,20,20 is: %d", pixelValue);
    
    
    
    
    MaskType3D::Pointer fixedMask; 
    fixedMask = [self getMaskWithITKImage:self->m_referenceImgITK3D];
    
    MaskType3D::Pointer movingMask = MaskType3D::New();
    
    self->m_referenceImgMask->DataObject::Update();
    fixedMask->SetImage(self->m_referenceImgMask);
    
    
    MaskType3D::PointType p1;
    p1.Fill(0);
    std::cout << "Point " << p1 << " is inside mask: "
    << fixedMask->IsInside(p1) << std::endl;
    MaskType3D::PointType p2;
    p2.Fill(20);
    std::cout << "Point " << p2 << " is inside mask: "
    << fixedMask->IsInside(p2) << std::endl;
*/
    
    
    
}// end setReferenceEDDataElement 





-(MocoTransformType::Pointer)alignEDDataElementToReference:(EDDataElement*)movingDataElement
{

    //The observer values have to be set back fo each new call of align
    self->m_observer->bestValue = std::numeric_limits<double>::max();
    
    //MH FIXME: this can possibly be done in initialization?
    self->m_transform = MocoTransformType::New();
    self->m_transformInitializer = MocoTransformInitializerType::New();
    self->m_transformInitializer->SetTransform( self->m_transform );
    
    //moving image is 3D
    ITKImage::Pointer movingImgITK3D = [movingDataElement asITKImage];
    
    //+++ Smoothing +++ 
   if( self->m_registrationProperty.Smoothing ){        
        
       //Smooth the moving image and set it for registration and transform initializer
       DiscreteGaussianImageFilterType::Pointer dgImageFilter = DiscreteGaussianImageFilterType::New();
       dgImageFilter->SetInput( movingImgITK3D );
       dgImageFilter->SetVariance( self->m_registrationProperty.SmoothingSigma );
       dgImageFilter->SetMaximumKernelWidth( self->m_registrationProperty.SmoothingKernelWidth );
       dgImageFilter->SetUseImageSpacing(true);
       dgImageFilter->SetMaximumError(0.05);
       dgImageFilter->Update();
       movingImgITK3D = dgImageFilter->GetOutput();
       self->m_registration->SetMovingImage( movingImgITK3D );
       self->m_transformInitializer->SetMovingImage( movingImgITK3D );
       
       //set the smoothed fixed image for registration and transform initializer
       self->m_referenceImgITK3DSmoothed->DataObject::Update();
       self->m_registration->SetFixedImage( self->m_referenceImgITK3DSmoothed );
       self->m_registration->SetFixedImageRegion( self->m_referenceImgITK3DSmoothed->GetBufferedRegion() );
       self->m_transformInitializer->SetFixedImage(  self->m_referenceImgITK3DSmoothed );
                
    }
    else{
        
        //set the smoothed fixed image for registration and transform initializer
        self->m_referenceImgITK3D->DataObject::Update();
        self->m_registration->SetFixedImage( self->m_referenceImgITK3D );
        self->m_registration->SetFixedImageRegion( self->m_referenceImgITK3D->GetBufferedRegion() );
        self->m_registration->SetMovingImage( movingImgITK3D );

        self->m_transformInitializer->SetFixedImage(  self->m_referenceImgITK3D );
        movingImgITK3D->DataObject::Update();
        self->m_transformInitializer->SetMovingImage( movingImgITK3D );
      
    }
    
  
    
    //+++ Initialize transform +++
    self->m_transformInitializer->MomentsOn(); //center of mass is used as center of transform
    //self->m_transformInitializer->GeometryOn();
    self->m_transformInitializer->InitializeTransform();//this just sets the initial transform parameters
    
    
    
    //MHFIXME:
    //Doesnt it make sense to use the previous parameters as initial setting
    //and not to find new ones by transform initializer?????
    self->m_registration->SetInitialTransformParameters( self->m_transform->GetParameters() );
    
    if( self->m_registrationProperty.LoggingLevel > 1 ) {
        MocoOptimizerType::ParametersType initialParameters;
        initialParameters = self->m_registration->GetInitialTransformParameters();
        
        std::cout << "*** Initial Parameters *** "  << std::endl;
        std::cout << " Initial versor X      = " << initialParameters[0]  << std::endl;
        std::cout << " Initial versor Y      = " << initialParameters[1]  << std::endl;
        std::cout << " Initial versor Z      = " << initialParameters[2]  << std::endl;
        std::cout << " Initial Translation X = " << initialParameters[3]  << std::endl;
        std::cout << " Initial Translation Y = " << initialParameters[4]  << std::endl;
        std::cout << " Initial Translation Z = " << initialParameters[5]  << std::endl;
    
    }
    
    
  	try { 
        
        //+++ Start registration +++
        self->m_registration->StartRegistration(); 
        
        if (self->m_registrationProperty.LoggingLevel > 1) {
            std::cout << "Optimizer stop condition: "
            << self->m_registration->GetOptimizer()->GetStopConditionDescription()
            << std::endl;
        }
    } 
  	catch( itk::ExceptionObject & err ) {
        std::cerr << "ExceptionObject caught !" << std::endl; 
        std::cerr << err << std::endl; 
        // return EXIT_FAILURE;
	} 
    
    

    //Use best parameters?
	MocoOptimizerType::ParametersType finalParameters;
    
    //TODO statt "< 2" sollte "< 1"
	if ( m_optimizer->GetCurrentIteration() < 2  || !self->m_registrationProperty.UseBestFoundParameters ) {
		finalParameters = self->m_registration->GetLastTransformParameters();        
    } else {
        finalParameters = self->m_observer->bestParameters;
    }
    
    
    if( self->m_registrationProperty.LoggingLevel > 1 ) {
 
        double versorX              = finalParameters[0];
        double versorY              = finalParameters[1];
        double versorZ              = finalParameters[2];
        double finalTranslationX    = finalParameters[3];
        double finalTranslationY    = finalParameters[4];
        double finalTranslationZ    = finalParameters[5];
        
        unsigned int numberOfIterations = m_optimizer->GetCurrentIteration();
        
        double bestValue = m_optimizer->GetValue();
    
    
        // Print out results
        std::cout << std::endl << std::endl;
        std::cout << "Result = " << std::endl;
        std::cout << " versor X      = " << versorX  << std::endl;
        std::cout << " versor Y      = " << versorY  << std::endl;
        std::cout << " versor Z      = " << versorZ  << std::endl;
        std::cout << " Translation X = " << finalTranslationX  << std::endl;
        std::cout << " Translation Y = " << finalTranslationY  << std::endl;
        std::cout << " Translation Z = " << finalTranslationZ  << std::endl;
        std::cout << " Iterations    = " << numberOfIterations << std::endl;
        
        std::cout << " Metric value  = " << bestValue          << std::endl;
        std::cout << " Observer value  = " << m_observer->bestValue << " " << std::endl;
        
        
    }
    
        
    //MHFIXME optional: return just parameters 
    //finally set the transform parameters
    self->m_transform->SetParameters( finalParameters );
    return self->m_transform;
    
    //return nil;
    
    
}// end alignEDDataElementToReference 




-(EDDataElement*)resampleMovingEDDataElement:(EDDataElement*)movingDataElement withTransform:(MocoTransformType::Pointer)transform
{
    
    //moving image is 3D
    ITKImage::Pointer movingImgITK3D = [movingDataElement asITKImage];

    
    //++++ Resampling ++++
    MocoTransformType::Pointer finalTransform = MocoTransformType::New();
    finalTransform->SetCenter( transform->GetCenter() );
    
    //original: finalTransform->SetParameters( finalParameters );
    finalTransform->SetParameters( transform->GetParameters() );
    finalTransform->SetFixedParameters( transform->GetFixedParameters() );
    
    self->m_resampler->SetTransform( finalTransform );
    self->m_resampler->SetInput( [movingDataElement asITKImage] );

    if( self->m_registrationProperty.Smoothing ){ 
        
        self->m_resampler->SetSize( self->m_referenceImgITK3DSmoothed->GetLargestPossibleRegion().GetSize() );
        self->m_resampler->SetOutputOrigin( self->m_referenceImgITK3DSmoothed->GetOrigin() );
        self->m_resampler->SetOutputSpacing( self->m_referenceImgITK3DSmoothed->GetSpacing() );
        self->m_resampler->SetOutputDirection( self->m_referenceImgITK3DSmoothed->GetDirection() );
        
    }
    else{
        
        self->m_resampler->SetSize( self->m_referenceImgITK3D->GetLargestPossibleRegion().GetSize() );
        self->m_resampler->SetOutputOrigin( self->m_referenceImgITK3D->GetOrigin() );
        self->m_resampler->SetOutputSpacing( self->m_referenceImgITK3D->GetSpacing() );
        self->m_resampler->SetOutputDirection( self->m_referenceImgITK3D->GetDirection() );
        
    }
    
    self->m_resampler->SetDefaultPixelValue( 0 );
    

    
    //MH FIXME: the orientation parameters are not set correctly!!
    ImageType4D::Pointer retImage4D= ImageType4D::New();
    
    typedef itk::TileImageFilter< MovingImageType3D, ImageType4D > TilerType;
    TilerType::Pointer tiler = TilerType::New();
    itk::FixedArray< unsigned int, Dimension4D > layout;
    layout[0] = 1;
    layout[1] = 1;
    layout[2] = 1;
    layout[3] = 0;
    tiler->SetLayout( layout );
    tiler->SetInput( self->m_resampler->GetOutput() );
    tiler->Update();
    retImage4D = tiler->GetOutput();
    
    return [movingDataElement convertFromITKImage4D:retImage4D ];
 
}




+(EDDataElement*)getEDDataElementFromFile:(NSString*)filePath
{
    
    //check whether file exist
    if( ![[NSFileManager defaultManager] fileExistsAtPath:filePath] ){
        
        NSLog(@"Did not find image file: %@", filePath);
        return nil;
    }
    
    EDDataElement *retEDDataEl =
    [[EDDataElement alloc] initWithDataFile:filePath andSuffix:@"" andDialect:@"" ofImageType:IMAGE_FCTDATA];

    return retEDDataEl;
}





- (MaskImageType3D::Pointer)getMaskImageWithITKImage:(FixedImageType3D::Pointer)itkImage
{
    
 
    //define the threshold using otsu
    typedef itk::OtsuThresholdImageFilter<FixedImageType3D, MaskImageType3D > OtsuThresholdFilterType;
    OtsuThresholdFilterType::Pointer otsuFilter = OtsuThresholdFilterType::New();
    
    otsuFilter->SetInput( itkImage );
    otsuFilter->SetOutsideValue( 1 );
    otsuFilter->SetInsideValue( 0 );
    otsuFilter->SetNumberOfHistogramBins( 200 );
    
    MaskImageType3D::Pointer mask = MaskImageType3D::New();
    
    mask = otsuFilter->GetOutput();
    
    
    
   
	
    
  /*  
    
    // ImageType::Pointer image, MaskImageType::Pointer mask, short threshold
    MaskImageType3D::RegionType region = itkImage->GetLargestPossibleRegion();
    MaskImageType3D::Pointer mask = MaskImageType3D::New();
    
    mask = 
    
    
    mask->SetRegions(region);
    mask->SetSpacing(itkImage->GetSpacing());
    mask->SetOrigin(itkImage->GetOrigin());
    mask->SetDirection(itkImage->GetDirection());
    mask->Allocate();
    
    
    MaskImageType3D::SizeType regionSize = region.GetSize();
  
    typedef itk::ImageRegionIterator<MaskImageType3D> IteratorType;
    
    
    itk::ImageRegionIterator<FixedImageType3D> imageIterator(itkImage, region);
    itk::ImageRegionIterator<MaskImageType3D> maskIterator(mask, region);

        
    while(!imageIterator.IsAtEnd())
    {
        if(imageIterator.Get() < 500)
        {
            maskIterator.Set(0);
        }
        else
        {
            maskIterator.Set(1);
        }
        ++imageIterator;
        ++maskIterator;
    }
    */
    
    
    //MH FIXME: Remove...
    //Write mask image
    if (self->m_registrationProperty.LoggingLevel>2){
        typedef itk::ImageFileWriter< MaskImageType3D >  WriterType;
        WriterType::Pointer  writer =  WriterType::New();
        writer->SetFileName( [@"/Users/mhollmann/Projekte/Project_MOCOApplication/data/test3D_mask.nii" UTF8String] );
        writer->SetInput( mask );
        writer->Update();
        NSLog(@"Mask image written to: %@", @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/test3D_mask.nii");
    }
    
    return mask;
    
}



- (void)dealloc
{
    
    NSLog(@"MocoRegistration Dealloc called!");
    
    //    free(m_registrationProperty);
//    free(m_registration);
//    free(m_metric);
//    free(m_optimizer);
//    free(m_transform);
//    free(m_transformInitializer);
//    free(m_observer);
//    free(m_resampleInterpolator);
//    free(m_referenceImgITK3D);
//    free(m_referenceImgITK3DSmoothed);

    //[super dealloc];
}















@end
