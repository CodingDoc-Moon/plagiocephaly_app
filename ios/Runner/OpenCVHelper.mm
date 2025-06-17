#import "GeneratedPluginRegistrant.h"
#import "OpenCVHelper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>


using namespace cv;

@implementation OpenCVHelper

+ (FlutterStandardTypedData *)detectContours:(FlutterStandardTypedData *)imageData {
    NSData *data = [imageData data];
    UIImage *uiImage = [UIImage imageWithData:data];
    if (!uiImage) return nil;

    // UIImage to cv::Mat
    cv::Mat mat;
    UIImageToMat(uiImage, mat);

    // 그레이스케일 변환
    cv::Mat gray;
    cvtColor(mat, gray, cv::COLOR_BGR2GRAY);

    // 블러 + 이진화
    cv::Mat blurred, thresh;
    GaussianBlur(gray, blurred, cv::Size(5, 5), 0);
    threshold(blurred, thresh, 80, 255, cv::THRESH_BINARY);

    // 윤곽선 검출
    std::vector<std::vector<cv::Point>> contours;
    findContours(thresh, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

    // 윤곽선 그리기
    cv::Mat contourImg;
    cvtColor(gray, contourImg, cv::COLOR_GRAY2BGR);
    drawContours(contourImg, contours, -1, cv::Scalar(255, 0, 0), 3);

    // cv::Mat to UIImage
    UIImage *resultUIImage = MatToUIImage(contourImg);
    NSData *resultData = UIImagePNGRepresentation(resultUIImage);
    return [FlutterStandardTypedData typedDataWithBytes:resultData];
}

@end
