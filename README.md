# ConnectBeat Frontend 개발 명세서 (Flutter)

---

## 1. 기술 스택 (Tech Stack)

- **언어**: Dart
- **프레임워크**: Flutter
- **상태 관리**: Riverpod (flutter_riverpod)
- **API 통신**: http
- **실시간 통신**: STOMP (stomp_dart_client)
- **소셜 로그인**: Kakao(kakao_flutter_sdk), Google(google_sign_in)
- **데이터 저장**: flutter_secure_storage(JWT), shared_preferences
- **데이터 직렬화**: freezed, json_serializable
- **이미지 처리**: image_picker, image_cropper
- **차트/시각화**: fl_chart

---

## 2. 프로젝트 구조

```
front_capstone/
├── assets/
│   ├── fonts/                     # GowunBatang 폰트 파일
│   └── images/                    # 로고, 배너 등 정적 리소스
├── lib/
│   ├── core/                      # 공통 상수, 설정 (constants.dart)
│   ├── models/                    # 데이터 모델 (freezed)
│   ├── providers/                 # Riverpod Provider/state 관리
│   ├── routes/                    # 라우터(app_router.dart)
│   ├── screens/                   # 주요 UI 화면
│   ├── services/                  # API 통신 및 비즈니스 로직
│   └── widgets/                   # 공용 UI 위젯/다이얼로그
├── pubspec.yaml                   # 의존성 관리
└── .env                           # 환경 변수 파일

---

## 3. 주요 설정 (Key Configuration)

### 🔸 환경 변수 관리
- `.env` 파일에서 API Base URL, 클라이언트 ID, STOMP WebSocket URL 등의 민감 정보를 관리
- `flutter_dotenv`로 앱 실행 시 로드

### 🔸 소셜 로그인
- **카카오:** `kakao_flutter_sdk`
- **구글:** `google_sign_in`
- 소셜 로그인 후 받은 토큰을 서버 `/api/users/login` 으로 전달하여 **JWT 발급 및 로그인 완료**

---

## 4. 주요 클래스 / 파일 설명

### Models
- **ChatMessage, ChatRoom** — 실시간 메시지·채팅방 구조
- **StoreItem, CoupleInventory, CoupleDecoration** — 상점 및 아이템 관리
- **ReportData, EmotionTimeline** — AI 감정 분석 결과 DTO

### Screens
- **LoginScreen** — 소셜 로그인 화면
- **ChatRoomScreen** — 실시간 STOMP 채팅
- **ChatReportDetailScreen** — fl_chart 기반 감정 그래프
- **HomeScreen** — 커플 상태 / 출석 / 꾸미기 UI
- **InventoryScreen** — 아이템 보관함 및 적용 관리

### Services
- **AuthService / AuthRepository** — JWT 저장/관리, 로그인 처리
- **ChatSocketService** — STOMP 연결, 구독, 송신
- **CoupleService** — 커플 연결/해제
- **S3Service** — AWS S3 이미지 업로드

### Providers (Riverpod)
- **CurrentUserProvider** — 사용자 상태 관리
- **ChatMessagesController** — 메시지 목록 및 페이징
- **CoinProvider** — 커플 코인 상태 관리

---

## 5. 보안 구현

- **JWT 저장:** `flutter_secure_storage`
- **HTTP 인증:** 모든 요청에 `Authorization: Bearer <JWT>` 헤더 자동 주입
- **STOMP 인증:** STOMP 연결 시 헤더에 JWT 포함하여 WebSocket 보안 강화

---

## 6. AI 모듈 연동 (Client View)

- **리포트 생성 요청:** `/api/chat-report/*` 호출
- **비동기 처리:** 리포트 생성 시 로딩 다이얼로그 표시
- **결과 시각화:** EmotionTimeline → fl_chart 그래프 변환

---

## 7. 파일 처리

- **이미지 선택/편집:** image_picker + image_cropper
- **S3 업로드:** 서버를 통해 AWS S3 업로드 후 URL 반환
- **프로필/아이템 이미지에 반영**

---

## 8. 예외 처리

- API 에러를 GlobalExceptionHandler 표준 포맷(JSON)으로 파싱
- SnackBar 또는 AlertDialog로 사용자에게 안내
- 네트워크 오류, 토큰 만료 등 모든 예외에 대한 처리 로직 포함

---

## 9. 빌드 및 배포

- **빌드:** Flutter CLI → Android (APK), iOS (IPA) 생성
- **배포:** Google Play Store / Apple App Store 등록

---

<br>

---

## Developer

**이민규 | Frontend Developer / Flutter**
상업적 이용 또는 무단 배포를 금합니다.

---

```
