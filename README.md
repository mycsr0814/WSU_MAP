# 🏫 우송대학교 캠퍼스 네비게이터 (Woosong Campus Navigator)

우송대학교 학생들을 위한 종합적인 캠퍼스 네비게이션 애플리케이션입니다. 실시간 위치 추적, 건물 내부 네비게이션, 시간표 관리, 친구 위치 공유 등 다양한 기능을 제공합니다.

## ✨ 주요 기능

### 🗺️ **실시간 캠퍼스 지도**
- 네이버 지도 기반 실시간 캠퍼스 지도
- 건물별 상세 정보 및 카테고리별 분류
- 실시간 사용자 위치 추적 및 표시
- 건물 검색 및 빠른 접근

### 🏢 **건물 내부 네비게이션**
- 건물별 층별 상세 지도 (SVG 기반)
- 실내 경로 안내 및 최적 경로 계산
- 강의실, 사무실 등 상세 정보 제공
- 카테고리별 필터링 (강의실, 사무실, 편의시설 등)

### 📅 **스마트 시간표 관리**
- Excel 파일을 통한 시간표 업로드
- 학기별 자동 분류 (봄/여름/가을/겨울)
- 강의실별 위치 정보 연동
- 시간표 기반 건물 내비게이션 연동

### 👥 **친구 위치 공유**
- 실시간 친구 위치 추적
- WebSocket을 통한 실시간 업데이트
- 친구 추가/삭제/관리 기능
- 위치 기반 친구 찾기

### 🌍 **다국어 지원**
- 한국어, 영어, 중국어 지원
- 자동 언어 감지 및 설정
- 현지화된 UI 및 메시지

### 🔐 **사용자 인증 시스템**
- 역할 기반 접근 제어 (학생, 교수진, 관리자, 게스트)
- 보안된 사용자 인증
- 게스트 모드 지원

## 🏗️ 프로젝트 구조

```
lib/
├── auth/                 # 사용자 인증 및 권한 관리
├── components/           # 재사용 가능한 UI 컴포넌트
├── config/              # API 설정 및 환경 변수
├── constants/           # 상수 및 설정값
├── controllers/         # 상태 관리 및 비즈니스 로직
├── core/               # 핵심 유틸리티 및 결과 처리
├── data/               # 정적 데이터 및 폴백 데이터
├── friends/            # 친구 관리 기능
├── generated/          # 다국어 지원 생성 파일
├── icon/               # 아이콘 및 이미지 리소스
├── inside/             # 건물 내부 네비게이션
├── l10n/               # 다국어 리소스 파일
├── login/              # 로그인 화면
├── managers/           # 위치 및 상태 관리자
├── map/                # 메인 지도 화면 및 위젯
├── models/             # 데이터 모델 클래스
├── outdoor_map_page.dart # 실외 지도 페이지
├── profile/            # 사용자 프로필 및 설정
├── providers/          # 상태 관리 프로바이더
├── repositories/       # 데이터 접근 계층
├── selection/          # 인증 선택 화면
├── services/           # API 서비스 및 비즈니스 로직
├── signup/             # 회원가입 화면
├── timetable/          # 시간표 관리 기능
├── tutorial/           # 사용자 튜토리얼
├── unified_navigation_stepper_page.dart # 통합 네비게이션
├── utils/              # 유틸리티 함수
├── welcome_view.dart   # 환영 화면
└── widgets/            # 공통 위젯 컴포넌트
```

## 🚀 기술 스택

### **프레임워크 & 언어**
- **Flutter 3.8.1+** - 크로스 플랫폼 모바일 앱 개발
- **Dart** - 프로그래밍 언어
- **Provider** - 상태 관리

### **지도 & 위치 서비스**
- **Naver Maps** - 메인 지도 서비스
- **Location** - GPS 위치 추적
- **Permission Handler** - 위치 권한 관리

### **데이터 & 통신**
- **HTTP** - REST API 통신
- **WebSocket** - 실시간 데이터 통신
- **Shared Preferences** - 로컬 데이터 저장
- **Excel** - 시간표 파일 처리

### **UI & UX**
- **Material Design** - 구글 디자인 시스템
- **Flutter SVG** - SVG 이미지 렌더링
- **Flutter Typeahead** - 자동완성 검색
- **Wakelock Plus** - 화면 켜짐 유지

### **플랫폼 지원**
- **Android** - API 21+ (Android 5.0+)
- **iOS** - iOS 11.0+
- **Web** - 웹 브라우저 지원
- **Windows** - Windows 10+
- **macOS** - macOS 10.14+

## 📱 설치 및 실행

### **사전 요구사항**
- Flutter SDK 3.8.1 이상
- Dart SDK 3.0.0 이상
- Android Studio / VS Code
- 네이버 지도 API 키

### **설치 방법**

1. **저장소 클론**
```bash
git clone [repository-url]
cd wsumap-1
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **네이버 지도 API 키 설정**
   - `lib/main.dart`에서 `clientId` 설정
   - 네이버 클라우드 플랫폼에서 API 키 발급

4. **앱 실행**
```bash
flutter run
```

### **빌드 방법**

**Android APK 빌드**
```bash
flutter build apk --release
```

**iOS IPA 빌드**
```bash
flutter build ios --release
```

**웹 빌드**
```bash
flutter build web --release
```

## 🔧 주요 설정

### **환경 설정**
- `lib/config/api_config.dart` - API 엔드포인트 설정
- `lib/constants/map_constants.dart` - 지도 관련 상수
- `lib/l10n/` - 다국어 설정

### **권한 설정**
- 위치 권한 (GPS)
- 인터넷 접근 권한
- 파일 읽기 권한 (시간표 업로드)

## 📊 주요 화면

### **1. 메인 지도 화면**
- 캠퍼스 전체 지도
- 건물 마커 및 정보
- 실시간 위치 표시
- 검색 및 필터링

### **2. 건물 내부 지도**
- 층별 상세 지도
- 강의실 및 시설 정보
- 실내 경로 안내
- 카테고리별 필터링

### **3. 시간표 화면**
- 학기별 시간표 관리
- Excel 파일 업로드
- 강의실 위치 연동
- 건물 내비게이션 연동

### **4. 친구 관리 화면**
- 친구 목록 및 추가
- 실시간 위치 공유
- 위치 기반 친구 찾기

### **5. 프로필 화면**
- 사용자 정보 관리
- 앱 설정 및 도움말
- 문의사항 및 피드백

## 🔒 보안 및 개인정보

- 사용자 인증 정보 암호화 저장
- 위치 정보 보안 처리
- API 통신 암호화
- 개인정보 수집 최소화

## 🐛 문제 해결

### **일반적인 문제**

1. **위치 권한 오류**
   - 설정에서 위치 권한 확인
   - 앱 재시작

2. **지도 로딩 실패**
   - 인터넷 연결 확인
   - 네이버 지도 API 키 확인

3. **시간표 업로드 실패**
   - Excel 파일 형식 확인
   - 파일 크기 제한 확인

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 지원 및 문의

- **개발팀**: 우송대학교 소프트웨어 개발팀
- **이메일**: [support@woosong.ac.kr]
- **문의사항**: 앱 내 프로필 → 도움말 → 문의사항

## 🔄 업데이트 로그

### **v1.0.0 (2024)**
- 초기 릴리즈
- 기본 지도 및 네비게이션 기능
- 시간표 관리
- 친구 위치 공유
- 다국어 지원

---

**우송대학교 캠퍼스 네비게이터**로 더욱 스마트한 캠퍼스 생활을 경험해보세요! 🎓✨
