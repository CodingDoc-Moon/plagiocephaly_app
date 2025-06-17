import Foundation
import UIKit
import Flutter
import opencv2

@objc class OpenCVHelper: NSObject {
    @objc static func detectContours(_ imageData: FlutterStandardTypedData) -> FlutterStandardTypedData? {
        guard let uiImage = UIImage(data: imageData.data) else { return nil }
        guard let cgImage = uiImage.cgImage else { return nil }
        
        // 1. CGImage → cv::Mat 변환
        let mat = MatFromUIImage(uiImage)
        
        // 2. 그레이스케일 변환
        let gray = Mat()
        cvtColor(src: mat, dst: gray, code: ColorConversionCodes.COLOR_BGR2GRAY)
        
        // 3. 블러 + 이진화
        let blurred = Mat()
        GaussianBlur(src: gray, dst: blurred, ksize: Size(width: 5, height: 5), sigmaX: 0)
        let thresh = Mat()
        threshold(src: blurred, dst: thresh, thresh: 80, maxval: 255, type: .THRESH_BINARY)
        
        // 4. 윤곽선 검출
        var contours: [MatOfPoint] = []
        let hierarchy = Mat()
        findContours(image: thresh, contours: &contours, hierarchy: hierarchy, mode: .RETR_EXTERNAL, method: .CHAIN_APPROX_SIMPLE)
        
        // 5. 윤곽선 그리기
        let contourImg = Mat()
        cvtColor(src: gray, dst: contourImg, code: .COLOR_GRAY2BGR)
        drawContours(image: contourImg, contours: contours, contourIdx: -1, color: Scalar(255, 0, 0), thickness: 3)
        
        // 6. 결과 Mat → UIImage → Data
        guard let resultUIImage = UIImageFromMat(contourImg),
              let resultData = resultUIImage.pngData() else { return nil }
        
        return FlutterStandardTypedData(bytes: resultData)
    }
}
