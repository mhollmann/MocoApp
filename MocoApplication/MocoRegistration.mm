//
//  MocoRegistration.mm
//  MotionCorrection
//
//  Created by Maurice Hollmann on 4/20/12.
//  Copyright (c) 2012 MPI Cognitive and Human Brain Sciences Leipzig. All rights reserved.
//

#import "MocoRegistration.h"

#include "itkImageRegistrationMethod.h"

//metric include
#include "itkMeanSquaresImageToImageMetric.h"

//interpolator includes
#include "itkLinearInterpolateImageFunction.h"
#include "itkNearestNeighborInterpolateImageFunction.h"
#include "itkBSplineInterpolateImageFunction.h"
#include "itkWindowedSincInterpolateImageFunction.h"

#include "itkCastImageFilter.h"


//MHFIXME just for testing
#include "itkImageFileReader.h"
#include "itkImageFileWriter.h"
#include "itkCastImageFilter.h"


@implementation MocoRegistration


- (id)init
{
    self = [super init];
    if (self) {
        
        MocoRegistrationProperty *rProperty = [[MocoRegistrationProperty alloc] init];
        
        //will set properties and initialize member vars
        [self setRegistrationProperty: rProperty];
        
    }
    
    return self;
}



- (id)initWithRegistrationProperty:(MocoRegistrationProperty *)regProperty
{
    self = [super init];
    if (self) {
        
        //will set properties and initialize member vars
        [self setRegistrationProperty: regProperty];
    
    }
    
    return self;
}



- (void) setRegistrationProperty:(MocoRegistrationProperty *)regProperty
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

    //interpolator->SetNumberOfThreads(2);
    //interpolator->SetSplineOrder(5);
    //interpolator-SetNumberOfThreads(2);
    //metric->SetNumberOfThreads(1);
    
    //MHFIXME This call produces nan out of reg params ->  ITK 3.21 problem?
    //short thresh = 100;
    //m_metric->SetFixedImageSamplesIntensityThreshold(thresh);
       
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
    self->m_registration->SetInterpolator( self->m_registrationInterpolator );
        
     
    
    //*** Initialize optimizer ***
    typedef MocoOptimizerType::ScalesType MocoOptimizerScalesType;
    MocoOptimizerScalesType optimizerScales( m_transform->GetNumberOfParameters() );
    optimizerScales[0] = 1.0;
    optimizerScales[1] = 1.0;
    optimizerScales[2] = 1.0;
    optimizerScales[3] = regProperty.RegistrationParameters[0]; //translationScale
    optimizerScales[4] = regProperty.RegistrationParameters[0]; //translationScale
    optimizerScales[5] = regProperty.RegistrationParameters[0]; //translationScale
    self->m_optimizer->SetScales( optimizerScales );
    self->m_optimizer->SetMaximumStepLength( regProperty.RegistrationParameters[1] );  //maxStepLength Default AFNI: 0.7 * voxel size
    self->m_optimizer->SetMinimumStepLength( regProperty.RegistrationParameters[2] );  //minStepLength
    self->m_optimizer->SetNumberOfIterations( regProperty.RegistrationParameters[3] ); //numIterations Default AFNI: 19
    
    
    //*** Create the Command observer and register it with the optimizer ***
    self->m_observer = CommandIterationUpdate::New();
    self->m_observer->bestValue = std::numeric_limits<double>::max();
    self->m_observer->logging = regProperty.logging;
    self->m_optimizer->AddObserver( itk::IterationEvent(), m_observer );
    
    
    
    
    // *** Resampling parameters ***
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
    EDDataElement *refImg = [self getEDDataElementFromFile: filePath];
    
    [self setReferenceEDDataElement: refImg];
    
    
}// end setReferenceEDDataElementWithFile




- (void)setReferenceEDDataElement:(EDDataElement *)dataElement
{
    
    
    //reference is always 3D
    
    self->m_referenceImgITK3D = [dataElement asITKImage];
    
    
    if( self->m_registrationProperty.logging ){
        
        ITKImage::SizeType iSize = self->m_referenceImgITK3D->GetLargestPossibleRegion().GetSize();
        std::cout << " Loaded image with size:    = " << iSize << std::endl;
        
    }
    
    //*** Smoothing *** 
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
    
    
}// end setReferenceEDDataElement 





-(MocoTransformType::Pointer)alignEDDataElementToReference:(EDDataElement*)movingDataElement
{

    //The observer values have to be set back fo each new call of align
    self->m_observer->bestValue = std::numeric_limits<double>::max();
    
    
    
    //moving image is 3D
    ITKImage::Pointer movingImgITK3D = [movingDataElement asITKImage];
    
    //*** Smoothing *** 
   if( self->m_registrationProperty.Smoothing ){        
        
        DiscreteGaussianImageFilterType::Pointer dgImageFilter = DiscreteGaussianImageFilterType::New();
        
        dgImageFilter->SetInput( movingImgITK3D );
        dgImageFilter->SetVariance( self->m_registrationProperty.SmoothingSigma );
        dgImageFilter->SetMaximumKernelWidth( self->m_registrationProperty.SmoothingKernelWidth );
        dgImageFilter->SetUseImageSpacing(true);
        dgImageFilter->SetMaximumError(0.05);
        
        dgImageFilter->Update();
        movingImgITK3D = dgImageFilter->GetOutput();
                
    }
     
    
    //MHFIXME these 2 calls may be done in 
    //*** Initialize transform ***
    self->m_transformInitializer = MocoTransformInitializerType::New();
    self->m_transformInitializer->SetTransform( self->m_transform );

    
    
    /* MHFIXME: will get faster by masking images */
    
    
    if( self->m_registrationProperty.Smoothing ){ 
        
        self->m_referenceImgITK3DSmoothed->DataObject::Update();
        self->m_registration->SetFixedImage( self->m_referenceImgITK3DSmoothed );
        self->m_registration->SetFixedImageRegion( self->m_referenceImgITK3DSmoothed->GetBufferedRegion() );
        self->m_transformInitializer->SetFixedImage(  self->m_referenceImgITK3DSmoothed );
        
    }
    else{
        
        self->m_referenceImgITK3D->DataObject::Update();
        self->m_registration->SetFixedImage( self->m_referenceImgITK3D );
        self->m_registration->SetFixedImageRegion( self->m_referenceImgITK3D->GetBufferedRegion() );
        self->m_transformInitializer->SetFixedImage(  self->m_referenceImgITK3D );
        
    }
    
    self->m_registration->SetMovingImage( movingImgITK3D );
    
    
/*
    FixedImageType3D::IndexType start;
    start[0] = 5;
    start[1] = 5;
    start[2] = 2;
    
    FixedImageType3D::SizeType size;
    size[0] = 55;
    size[1] = 55;
    size[2] = 25;

    
    FixedImageType3D::Pointer image = self->m_referenceImgITK3D;
    FixedImageType3D::IndexType pIndex;
    pIndex[0] = 20;
    pIndex[1] = 20;
    pIndex[2] = 20;
    //update needs to be called to get access to data
    image->DataObject::Update();   
    FixedImageType3D::SizeType iSize = image->GetLargestPossibleRegion().GetSize();
    std::cout << " Image Size:    = " << iSize << std::endl;
    FixedImageType3D::PixelType pixelValue = image->GetPixel( pIndex );
    std::cout << " PIXEL VALUE:    = " << pixelValue << std::endl;
    
     
    
    //update needs to be called to get access to data
    movingImgITK3D->DataObject::Update();   
    iSize = movingImgITK3D->GetLargestPossibleRegion().GetSize();
    std::cout << " Image Size:    = " << iSize << std::endl;
    pixelValue = movingImgITK3D->GetPixel( pIndex );
    std::cout << " PIXEL VALUE:    = " << pixelValue << std::endl;
    */
    
    
    
    
    self->m_transformInitializer->SetMovingImage( movingImgITK3D );  
    self->m_transformInitializer->MomentsOn(); //center of mass is used as center of transform
    //  initializer->GeometryOn();
    self->m_transformInitializer->InitializeTransform();//this just sets the initial transform parameters
    
    
    
    //MHFIXME:
    //Doesnt it make sense to use the previous parameters as initial setting
    //and not to find new ones by transform initializer?????
    self->m_registration->SetInitialTransformParameters( self->m_transform->GetParameters() );
    
    if( self->m_registrationProperty.logging ) {
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
        
        //*** Start registration ***
        self->m_registration->StartRegistration(); 
        
        if (self->m_registrationProperty.logging) {
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
    
    
    if( self->m_registrationProperty.logging ) {
 
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
    
    
    /*
    
    MetricType::TransformParametersType displacement( 6 );
    
    displacement[0] = 0;
    displacement[1] = 0;
    displacement[2] = 0;
    displacement[3] = 0;
    displacement[4] = 0;
    displacement[5] = 0;
    
    
    //  std::cout << " Metric pixels : " << metric->GetNumberOfPixelsCounted() << std::endl << std::endl;
    
    
    
    
    
    transform->SetParameters( finalParameters );
    
    TransformType::MatrixType matrix = transform->GetRotationMatrix();
    TransformType::OffsetType offset = transform->GetOffset();
    
    //  std::cout << "Matrix = " << std::endl << matrix << std::endl;
    //  std::cout << "Offset = " << std::endl << offset << std::endl << std::endl;
    
    
    VectorType versor_axis = transform->GetVersor().GetAxis();
    double versor_angle = transform->GetVersor().GetAngle();
    //    
    //    std::cout << "Axis = " << transform->GetVersor().GetAxis() << std::endl;
    //    std::cout << "Angle = " << transform->GetVersor().GetAngle() << std::endl << std::endl;
    //    
    //    std::cout << "AngleX_rad = " << versor_axis[0] * versor_angle << std::endl;
    //    std::cout << "AngleY_rad = " << versor_axis[1] * versor_angle << std::endl;
    //    std::cout << "AngleZ_rad = " << versor_axis[2] * versor_angle << std::endl << std::endl;    
    //
    
    //    std::cout << "AngleX = " << 180/M_PI * versor_axis[0] * versor_angle << std::endl;
    //    std::cout << "AngleX = " << 180/M_PI * versor_axis[1] * versor_angle << std::endl;
    //    std::cout << "AngleX = " << 180/M_PI * versor_axis[2] * versor_angle << std::endl;    
    
    //---------------------------------------------
    
    finalMovementParameters[0] = -1.0 * ( 180/M_PI * versor_axis[0] * versor_angle );
    finalMovementParameters[1] = -1.0 * ( 180/M_PI * versor_axis[1] * versor_angle );
    finalMovementParameters[2] = -1.0 * ( 180/M_PI * versor_axis[2] * versor_angle );
    finalMovementParameters[3] = -1.0 * ( offset[0] );
    finalMovementParameters[4] = -1.0 * ( offset[1] );
    finalMovementParameters[5] = -1.0 * ( offset[2] );
    //    
    //    std::cout << "Parameters = " << finalMovementParameters[0] << " , " 
    //                                 << finalMovementParameters[1] << " , " 
    //                                 << finalMovementParameters[2] << " , " 
    //                                 << finalMovementParameters[3] << " , " 
    //                                 << finalMovementParameters[4] << " , " 
    //                                 << finalMovementParameters[5] << std::endl;*/
    
    
    
}// end alignEDDataElementToReference 




-(EDDataElement*)resampleMovingEDDataElement:(EDDataElement*)movingDataElement withTransform:(MocoTransformType::Pointer)transform
{
    
    //moving image is 3D
    ITKImage::Pointer movingImgITK3D = [movingDataElement asITKImage];

    
    //********************
    //**** Resampling ****
    //********************
    MocoTransformType::Pointer finalTransform = MocoTransformType::New();
    
    
    finalTransform->SetCenter( transform->GetCenter() );
    
    //original: finalTransform->SetParameters( finalParameters );
    finalTransform->SetParameters( transform->GetParameters() );
    finalTransform->SetFixedParameters( transform->GetFixedParameters() );
    
    self->m_resampler->SetTransform( finalTransform );
    self->m_resampler->SetInput( movingImgITK3D );
    

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
    
    
    //MHFixme : Check debug error and return correct DataElement
    //ITKImage::Pointer resImg = self->m_resampler->GetOutput();
    //Dunno
    
    
    //EDDataElement *retElement = [movingDataElement convertFromITKImage: caster->GetOutput()];
    //[retElement WriteDataElementToFile:@"/tmp/test_moco_output_lh.nii"];
    //return nil;//[movingDataElement autorelease];
    
    //return retElement;
    //return nil;
    
    
    //return movingDataElement;
    
    //this gives the result ITKImage
    //self->m_resampler->GetOutput();
    
    
    ITKImage::Pointer resImage = self->m_resampler->GetOutput();
    
    const unsigned int Dimension = 3;
    typedef  float  InputPixelType;
  	typedef  short  OutputPixelType;
  	typedef itk::Image< InputPixelType, Dimension > InputImageType;
    typedef itk::Image< OutputPixelType, Dimension > OutputImageType;
  	typedef itk::CastImageFilter< InputImageType, OutputImageType > CastFilterType;
    
    CastFilterType::Pointer  caster =  CastFilterType::New();
        
    
    
    caster->SetInput( self->m_resampler->GetOutput() );
	
    caster->Update();
    
    OutputImageType::Pointer resImagePtr = caster->GetOutput();
    
    
    
    std::cout << "Info EDDataElement moving: " << std::endl;
    
    BARTImageSize *imgSize  = [movingDataElement getImageSize]; 
    
    std::cout << "Size: " << imgSize.rows << " " << imgSize.columns << " " << imgSize.slices <<std::endl;    
    std::cout << "Datatype: " << [movingDataElement getImageDataType ]  << std::endl;
    
    
    
    EDDataElement *retElement = [movingDataElement convertFromITKImage: self->m_resampler->GetOutput()];
    
    
    
    
    //ITKImage::Pointer *resImage = caster->GetOutput();
    
    
    
    
    
    //**********************
    //**** Write result ****
    //**********************
   /* 
    const unsigned int Dimension = 3;
  	typedef  short  OutputPixelType;
    typedef itk::Image< OutputPixelType, Dimension > OutputImageType;
  	typedef itk::CastImageFilter< FixedImageType3D, OutputImageType > CastFilterType;
  	typedef itk::ImageFileWriter< OutputImageType >  WriterType;
    
	WriterType::Pointer      writer =  WriterType::New();
    CastFilterType::Pointer  caster =  CastFilterType::New();
    
    NSLog(@"Writing result image!");
    writer->SetFileName( [@"/Users/mhollmann/Programming/MOCO_REGISTRATION_BART/data/outImageReg.nii" UTF8String] );
    
    caster->SetInput( self->m_resampler->GetOutput() );
	
    caster->Update();
    
    
    
    writer->SetInput( caster->GetOutput()   );
    writer->Update();
    */
    
    return retElement;


}




-(EDDataElement*)getEDDataElementFromFile:(NSString*)filePath
{
    
    //check whether file exist
    if(self->m_registrationProperty.logging){        
        NSLog(@"Loading Image: %@",filePath);
    }
    
    if( ![[NSFileManager defaultManager] fileExistsAtPath:filePath] ){
        
        NSLog(@"Did not find image file: %@", filePath);
        return nil;
        
    }
    
    EDDataElement *retEDDataEl =
    [[EDDataElement alloc] initWithDataFile:filePath andSuffix:@"" andDialect:@"" ofImageType:IMAGE_FCTDATA];

    return retEDDataEl;
}





- (void)dealloc
{
    [super dealloc];
}















@end
