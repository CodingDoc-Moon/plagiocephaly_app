# plagiocephaly_app

스마트폰 카메라로 아이의 두상을 촬영하여 사두(Plagiocephaly) 정도를 평가하는 Flutter 기반 크로스플랫폼 앱입니다.

## 프로젝트 개요
- 0~12개월 영유아의 두상 촬영 및 사두 평가
- 집에서 손쉽게 두상 진행을 추적 및 관리
- AI 기반 이미지 분석 및 수치 산출(CEP, CVAI 등)
- 이력 관리, 알림, 튜토리얼 등 다양한 부가 기능 제공

## 주요 기술 스택
- Flutter (iOS 14+, Android 8+ 지원)
- camera, firebase_core 등 주요 패키지 사용

## 개발 환경 세팅
### 1. Flutter 설치
Flutter 공식 문서(https://docs.flutter.dev/get-started/install) 참고

### 2. 의존성 설치
```bash
flutter pub get
```

### 3. Android 빌드
```bash
flutter build apk --debug
```

### 4. iOS 빌드
(iOS 13.0 이상 필요, codesign 없이 빌드)
```bash
cd ios
pod install
cd ..
flutter build ios --no-codesign
```

## 주요 의존성 패키지
- camera
- firebase_core

## Git 사용법
```bash
git clone <repo_url>
cd plagiocephaly_app
```

## 참고 자료
- [Flutter 공식 문서](https://docs.flutter.dev/)
- [camera 패키지](https://pub.dev/packages/camera)
- [firebase_core 패키지](https://pub.dev/packages/firebase_core)

---

> 본 프로젝트는 영유아 두상 건강 관리를 위한 비상업적 연구/개발용입니다.
