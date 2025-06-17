#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AdaptiveThresholdFactory.h"
#import "ApplyColorMapFactory.h"
#import "BilateralFilterFactory.h"
#import "BlurFactory.h"
#import "BoxFilterFactory.h"
#import "CvtColorFactory.h"
#import "DilateFactory.h"
#import "DistanceTransformFactory.h"
#import "ErodeFactory.h"
#import "Filter2DFactory.h"
#import "GaussianBlurFactory.h"
#import "LaplacianFactory.h"
#import "MedianBlurFactory.h"
#import "MorphologyExFactory.h"
#import "Opencv4Plugin.h"
#import "PyrMeanShiftFilteringFactory.h"
#import "ScharrFactory.h"
#import "SobelFactory.h"
#import "SqrBoxFilterFactory.h"
#import "ThresholdFactory.h"

FOUNDATION_EXPORT double opencv_4VersionNumber;
FOUNDATION_EXPORT const unsigned char opencv_4VersionString[];

