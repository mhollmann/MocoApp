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

//for mask dilation
#include "itkBinaryDilateImageFilter.h"
#include "itkBinaryBallStructuringElement.h"


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


/**
 *
 * Iitialize the registration with a given RegistrationProperty.
 * \param regProperty  The MocoRegistrationProperty object.
 *
 */
-(void)initRegistrationWithRegistrationProperty:(MocoRegistrationProperty*)regProperty;


/** MH FIXME: check for soundness of regProperties - return nil if ok, NSError otherwise...
 *
 * Check a given RegistrationProperty for param soundness.
 * \param regProperty  The MocoRegistrationProperty object to check.
 *
 */
//-(NSError)checkRegistrationProperty:(MocoRegistrationProperty*)regProperty;


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
    
    //create metric, optimizer, and transform 
    self->m_metric    = MocoMetricType::New();
    self->m_optimizer = MocoOptimizerType::New();
    self->m_transform = MocoTransformType::New();
    
    //set metric params
    self->m_metric->SetNumberOfThreads(regProperty.NumberOfThreads);
    
    //set global threadnum
    self->m_metric->GetThreader()->SetGlobalMaximumNumberOfThreads(regProperty.NumberOfThreads);
    self->m_metric->GetThreader()->SetGlobalDefaultNumberOfThreads(regProperty.NumberOfThreads);
   
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
        case INTERPOLATOR_NN:
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
        case INTERPOLATOR_NN:
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




- (void)setReferenceImageWithFile:(NSString *)filePath
{
    EDDataElement *refImg = [MocoRegistration getEDDataElementFromFile: filePath];
    
    [self setReferenceImageWithEDDataElement: refImg];
    
    
}// end setReferenceEDDataElementWithFile




- (void)setReferenceImageWithEDDataElement:(EDDataElement *)dataElement
{
    //@try{
        [self setReferenceImageWithITKImage: [dataElement asITKImage]];
    //}
    /*@catch(NSException *e){
    
        NSException* except = [NSException exceptionWithName:@"SetReferenceImageException" reason:@"Error setting the reference image for registration" userInfo:nil];
        @throw except;
    }*/
    
}// end setReferenceImageWithEDDataElement 



- (void)setReferenceImageWithITKImage:(FixedImageType3D::Pointer)itkImage
{
    
    //reference is always 3D
    self->m_referenceImgITK3D = itkImage;
    
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
    
    
}// end setReferenceImageWithITKImage



 
-(MocoTransformType::Pointer)alignEDDataElementToReference:(EDDataElement*)movingDataElement
{
    
    return [self alignITKImageToReference: [movingDataElement asITKImage]];
    
}// end alignEDDataElementToReference 



-(MocoTransformType::Pointer)alignITKImageToReference:(MovingImageType3D::Pointer)movingITKImage
{

    @try{
        MocoRegistrationType::Pointer   registration  = MocoRegistrationType::New();

        registration->SetMetric(    self->m_metric );
        registration->SetOptimizer( self->m_optimizer );
        
        registration->SetInterpolator(  self->m_registrationInterpolator  );
        
        MocoTransformType::Pointer  transform = MocoTransformType::New();
        registration->SetTransform( transform );
        
        
        MocoTransformInitializerType::Pointer initializer = MocoTransformInitializerType::New();
        initializer->SetTransform(   transform );
        
        if (self->m_registrationProperty.Smoothing) {
            
            if( self->m_referenceImgITK3DSmoothed.IsNull() )
            {
                NSException* except = [NSException exceptionWithName:@"MocoRegistrationConfigurationException"
                                                              reason:@"Error aligning image. Reference image was not set!"
                                                            userInfo:nil];
                @throw except;
            }
            
            
            typedef itk::DiscreteGaussianImageFilter< FixedImageType3D, MovingImageType3D > FilterType;
            FilterType::Pointer movingFilter = FilterType::New();
            
            movingFilter->SetInput( movingITKImage );
            
            movingFilter->SetVariance( self->m_registrationProperty.SmoothingSigma );
            movingFilter->SetMaximumKernelWidth( self->m_registrationProperty.SmoothingKernelWidth );
            movingFilter->SetMaximumError(0.01);
            
            
            //set the smoothed fixed image for registration and transform initializer
            movingFilter->Update();
            self->m_referenceImgITK3DSmoothed->DataObject::Update();
            registration->SetFixedImage( self->m_referenceImgITK3DSmoothed );
            registration->SetMovingImage(   movingFilter->GetOutput()   );
            initializer->SetFixedImage(  self->m_referenceImgITK3DSmoothed );
            initializer->SetMovingImage( movingFilter->GetOutput() );
            
            
        } else {
            
            if( self->m_referenceImgITK3D.IsNull() )
            {
                NSException* except = [NSException exceptionWithName:@"MocoRegistrationConfigurationException"
                                                              reason:@"Error aligning image. Reference image was not set!"
                                                            userInfo:nil];
                @throw except;
            }
            
            registration->SetFixedImage(    self->m_referenceImgITK3D    );
            registration->SetMovingImage(   movingITKImage  );
            initializer->SetFixedImage(  self->m_referenceImgITK3D );
            initializer->SetMovingImage( movingITKImage );
        }
        
        registration->SetFixedImageRegion( self->m_referenceImgITK3D->GetBufferedRegion() );
        
        //initialize the transformation
        initializer->MomentsOn();
        initializer->InitializeTransform();
        registration->SetInitialTransformParameters( transform->GetParameters() );
        
        //set back the best value to max
        self->m_observer->bestValue = std::numeric_limits<double>::max();
        
        try {
            registration->Update();
            if (self->m_registrationProperty.LoggingLevel > 2) {
                std::cout << "Optimizer stop condition: "
                << registration->GetOptimizer()->GetStopConditionDescription()
                << std::endl;
            }
        }
        catch( itk::ExceptionObject & err ) {
            std::cerr << "ExceptionObject caught !" << std::endl;
            std::cerr << err << std::endl;
            //return EXIT_FAILURE;
            
            NSException* except = [NSException exceptionWithName:@"ITKRegistrationException" reason:@"Error during ITK registration" userInfo:nil];
            @throw except;
            
        }
     
        //Take best parameters saved from observer?
        MocoOptimizerType::ParametersType finalParameters;
        
        //MH FIXME  "< 1" ?
        if ( self->m_optimizer->GetCurrentIteration() < 2 || !self->m_registrationProperty.UseBestFoundParameters ) {
            finalParameters = registration->GetLastTransformParameters();
        } else {
            finalParameters = self->m_observer->bestParameters;
        }
       
        
        
        if( self->m_registrationProperty.LoggingLevel > 2 ) {
            
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
        
      
        //finally set the transform parameters
        transform->SetParameters( finalParameters );
        return transform;
    }
    @catch(NSException *e){
        
        NSException* except = [NSException exceptionWithName:@"AlignImageException"
                                                      reason:[@"Error aligning image to reference:" stringByAppendingString:[e reason]] userInfo:nil];
        @throw except;
    }
    
}// end alignITKImageToReference




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
        
        if( self->m_referenceImgITK3DSmoothed.IsNull() )
        {
            NSException* except = [NSException exceptionWithName:@"MocoRegistrationConfigurationException"
                                                          reason:@"Error resampling image. Reference image was not set!"
                                                          userInfo:nil];
            @throw except;
        }
        
        self->m_resampler->SetSize( self->m_referenceImgITK3DSmoothed->GetLargestPossibleRegion().GetSize() );
        self->m_resampler->SetOutputOrigin( self->m_referenceImgITK3DSmoothed->GetOrigin() );
        self->m_resampler->SetOutputSpacing( self->m_referenceImgITK3DSmoothed->GetSpacing() );
        self->m_resampler->SetOutputDirection( self->m_referenceImgITK3DSmoothed->GetDirection() );
        
    }
    else{
        
        if( self->m_referenceImgITK3D.IsNull())
        {
            NSException* except = [NSException exceptionWithName:@"MocoRegistrationConfigurationException"
                                                          reason:@"Error resampling image. Reference image was not set!"
                                                        userInfo:nil];
            @throw except;
        }
        
        self->m_resampler->SetSize( self->m_referenceImgITK3D->GetLargestPossibleRegion().GetSize() );
        self->m_resampler->SetOutputOrigin( self->m_referenceImgITK3D->GetOrigin() );
        self->m_resampler->SetOutputSpacing( self->m_referenceImgITK3D->GetSpacing() );
        self->m_resampler->SetOutputDirection( self->m_referenceImgITK3D->GetDirection() );
        
    }
    
    self->m_resampler->SetDefaultPixelValue( 0 );
    
    
    //MH FIXME: This may be avoided
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
    typedef itk::BinaryBallStructuringElement< MaskImageType3D::PixelType, 3 > StructuringElementType;
    StructuringElementType structuringElement;
    structuringElement.SetRadius(40);
    structuringElement.CreateStructuringElement();
    
    typedef itk::BinaryDilateImageFilter <MaskImageType3D, MaskImageType3D, StructuringElementType>
    BinaryDilateImageFilterType;
    
    BinaryDilateImageFilterType::Pointer dilateFilter = BinaryDilateImageFilterType::New();
    dilateFilter->SetInput(otsuFilter->GetOutput());
    dilateFilter->SetKernel(structuringElement);

    
    mask = dilateFilter->GetOutput();
	*/
    
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
    }*/
    
    
    
    //MH FIXME: Remove...
    //Write mask image
    /*if (self->m_registrationProperty.LoggingLevel>2){
        typedef itk::ImageFileWriter< MaskImageType3D >  WriterType;
        WriterType::Pointer  writer =  WriterType::New();
        writer->SetFileName( [@"/Users/mhollmann/Projekte/Project_MOCOApplication/data/test3D_mask_dilate.nii" UTF8String] );
        writer->SetInput( mask );
        writer->Update();
        NSLog(@"Mask image written to: %@", @"/Users/mhollmann/Projekte/Project_MOCOApplication/data/test3D_mask_dilate.nii");
    }*/
    
    return mask;
    
}



- (void)dealloc
{
    
    
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

    [super dealloc];
}















@end
