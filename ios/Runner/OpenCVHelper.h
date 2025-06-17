#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface OpenCVHelper : NSObject
+ (FlutterStandardTypedData *)detectContours:(FlutterStandardTypedData *)imageData;
@end
