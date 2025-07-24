// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Campus Navigator';

  @override
  String get subtitle => '스마트 캠퍼스 가이드';

  @override
  String get woosong => '우송';

  @override
  String get start => '시작하기';

  @override
  String get login => '로그인';

  @override
  String get logout => '로그아웃';

  @override
  String get guest => '게스트';

  @override
  String get student_professor => '학생/교수';

  @override
  String get admin => '관리자';

  @override
  String get student => '학생';

  @override
  String get professor => '교수';

  @override
  String get external_user => '외부인';

  @override
  String get username => '아이디';

  @override
  String get password => '비밀번호';

  @override
  String get confirm_password => '비밀번호 확인';

  @override
  String get remember_me => '로그인 정보 기억하기';

  @override
  String get remember_me_description => '다음에 자동으로 로그인됩니다';

  @override
  String get login_as_guest => '게스트로 둘러보기';

  @override
  String get login_failed => '로그인 실패';

  @override
  String get login_success => '로그인 성공';

  @override
  String get logout_success => '로그아웃 되었습니다';

  @override
  String get enter_username => '아이디를 입력하세요';

  @override
  String get enter_password => '비밀번호를 입력하세요';

  @override
  String get password_hint => '6자 이상 입력하세요';

  @override
  String get confirm_password_hint => '비밀번호를 다시 입력하세요';

  @override
  String get username_password_required => '아이디와 비밀번호를 모두 입력해주세요';

  @override
  String get login_error => '로그인에 실패했습니다';

  @override
  String get find_password => '비밀번호 찾기';

  @override
  String get find_username => '아이디 찾기';

  @override
  String get back => '뒤로가기';

  @override
  String get confirm => '확인';

  @override
  String get cancel => '취소';

  @override
  String get coming_soon => '준비 중';

  @override
  String feature_coming_soon(String feature) {
    return '$feature 기능은 준비 중입니다.\n빠른 시일 내에 추가될 예정입니다.';
  }

  @override
  String get start_campus_exploration => '캠퍼스 탐색을 시작해보세요';

  @override
  String get woosong_university => '우송대학교';

  @override
  String get campus_navigator => '캠퍼스 네비게이터';

  @override
  String get user_info_not_found => '로그인 응답에서 사용자 정보를 찾을 수 없습니다';

  @override
  String get unexpected_login_error => '로그인 중 예상치 못한 오류가 발생했습니다';

  @override
  String get login_required => '로그인이 필요합니다';

  @override
  String get register => '회원가입';

  @override
  String get register_success => '회원가입이 완료되었습니다';

  @override
  String get register_success_message => '회원가입이 완료되었습니다!\n로그인 화면으로 이동합니다.';

  @override
  String get register_error => '회원가입 중 예상치 못한 오류가 발생했습니다';

  @override
  String get update_user_info => '회원정보 수정';

  @override
  String get update_success => '회원정보가 수정되었습니다';

  @override
  String get update_error => '회원정보 수정 중 예상치 못한 오류가 발생했습니다';

  @override
  String get delete_account => '회원 탈퇴';

  @override
  String get delete_success => '회원 탈퇴가 완료되었습니다';

  @override
  String get delete_error => '회원 탈퇴 중 예상치 못한 오류가 발생했습니다';

  @override
  String get name => '이름';

  @override
  String get phone => '전화번호';

  @override
  String get email => '이메일';

  @override
  String get student_number => '학번';

  @override
  String get user_type => '사용자 유형';

  @override
  String get optional => '선택사항';

  @override
  String get required_fields_empty => '모든 필수 항목을 입력해주세요';

  @override
  String get password_mismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get password_too_short => '비밀번호는 6자 이상이어야 합니다';

  @override
  String get invalid_phone_format => '올바른 전화번호 형식을 입력해주세요 (예: 010-1234-5678)';

  @override
  String get invalid_email_format => '올바른 이메일 형식을 입력해주세요';

  @override
  String get required_fields_notice => '* 표시된 항목은 필수 입력 사항입니다';

  @override
  String get welcome_to_campus_navigator => '우송대 캠퍼스 네비게이터에 오신 것을 환영합니다';

  @override
  String get enter_real_name => '실명을 입력하세요';

  @override
  String get phone_format_hint => '010-1234-5678';

  @override
  String get enter_student_number => '학번 또는 교번을 입력하세요';

  @override
  String get email_hint => 'example@woosong.org';

  @override
  String get create_account => '계정 만들기';

  @override
  String get loading => '로딩 중...';

  @override
  String get error => '오류';

  @override
  String get success => '성공';

  @override
  String get validation_error => '입력값을 확인해주세요';

  @override
  String get network_error => '네트워크 오류가 발생했습니다';

  @override
  String get server_error => '서버 오류가 발생했습니다';

  @override
  String get unknown_error => '알 수 없는 오류가 발생했습니다';

  @override
  String get select_auth_method => '인증 방법 선택';

  @override
  String get woosong_campus_guide_service => '우송대학교 캠퍼스 길안내 서비스';

  @override
  String get register_description => '새로운 계정을 만들어 모든 기능을 이용하세요';

  @override
  String get login_description => '기존 계정으로 로그인하여 서비스를 이용하세요';

  @override
  String get browse_as_guest => '게스트로 둘러보기';

  @override
  String get processing => '처리 중...';

  @override
  String get campus_navigator_version => 'Campus Navigator v1.0';

  @override
  String get guest_mode => '게스트 모드';

  @override
  String get guest_mode_description =>
      '게스트 모드에서는 기본적인 캠퍼스 정보만 확인할 수 있습니다.\n모든 기능을 이용하려면 회원가입 후 로그인해주세요.';

  @override
  String get continue_as_guest => '게스트로 계속';

  @override
  String get moved_to_my_location => '내 위치로 자동 이동했습니다';

  @override
  String get friends_screen_bottom_sheet => '친구 화면은 바텀 시트로 표시됩니다';

  @override
  String get finding_current_location => '현재 위치를 찾는 중...';

  @override
  String get home => '홈';

  @override
  String get timetable => '시간표';

  @override
  String get friends => '친구';

  @override
  String get my_page => 'MY';

  @override
  String get cafe => '카페';

  @override
  String get restaurant => '식당';

  @override
  String get library => '도서관';

  @override
  String get educational_facility => '교육시설';

  @override
  String get estimated_distance => '예상거리';

  @override
  String get estimated_time => '예상시간';

  @override
  String get calculating => '계산중...';

  @override
  String get calculating_route => '경로 계산 중...';

  @override
  String get finding_optimal_route => '서버에서 최적 경로를 찾고 있습니다';

  @override
  String get departure => '출발지';

  @override
  String get destination => '도착지';

  @override
  String get clear_route => '경로 초기화';

  @override
  String get location_permission_denied =>
      '위치 권한이 거부되었습니다.\n설정에서 위치 권한을 허용해주세요.';

  @override
  String finding_route_to_building(String building) {
    return '$building까지 경로를 찾는 중...';
  }

  @override
  String route_displayed_to_building(String building) {
    return '$building까지 경로를 표시했습니다';
  }

  @override
  String set_as_departure(String building) {
    return '$building을(를) 출발지로 설정했습니다.';
  }

  @override
  String set_as_destination(String building) {
    return '$building을(를) 도착지로 설정했습니다.';
  }

  @override
  String get woosong_library_w1 => '우송도서관(W1)';

  @override
  String get woosong_library_info =>
      'B2F\t주차장\nB1F\t소강당, 기관실, 전기실, 주차장\n1F\t취업지원센터(630-9976),대출실, 정보라운지\n2F\t일반열람실, 단체학습실\n3F\t일반열람실\n4F\t문학도서/서양도서';

  @override
  String get woosong_library_desc => '우송대학교 중앙도서관';

  @override
  String get sol_cafe => '솔카페';

  @override
  String get sol_cafe_info => '1F\t식당\n2F\t카페';

  @override
  String get sol_cafe_desc => '캠퍼스 내 카페';

  @override
  String get cheongun_1_dormitory => '청운1숙';

  @override
  String get cheongun_1_dormitory_info =>
      '1F\t실습실\n2F\t학생식당\n2F\t청운1숙(여)(629-6542)\n2F\t생활관\n3~5F\t생활관';

  @override
  String get cheongun_1_dormitory_desc => '여학생 기숙사';

  @override
  String get industry_cooperation_w2 => '산학협력단(W2)';

  @override
  String get industry_cooperation_info =>
      '1F\t산학협력단\n2F\t건축공학전공(630-9720)\n3F\t우송대 융합기술연구소, 산학연총괄기업지원센터\n4F\t기업부설연구소, LG CNS강의실, 철도디젯아카데미 강의실';

  @override
  String get industry_cooperation_desc => '산학협력 및 연구시설';

  @override
  String get rotc_w2_1 => '학군단(W2-1)';

  @override
  String get rotc_info => '\t학군단(630-4601)';

  @override
  String get rotc_desc => '학군단 시설';

  @override
  String get international_dormitory_w3 => '유학생기숙사(W3)';

  @override
  String get international_dormitory_info =>
      '1F\t유학생지원팀(629-6623)\n1F\t학생식당\n2F\t유학생기숙사(629-6655)\n2F\t보건실\n3~12F\t생활관';

  @override
  String get international_dormitory_desc => '유학생 전용 기숙사';

  @override
  String get railway_logistics_w4 => '철도물류관(W4)';

  @override
  String get railway_logistics_info =>
      'B1F\t실습실\n1F\t실습실\n2F\t철도건설시스템학부(629-6710)\n2F\t철도차량시스템학과(629-6780)\n3F\t강의실/실습실\n4F\t철도시스템학부(630-6730,9700)\n5F\t소방방재학과(629-6770)\n5F\t물류시스템학과(630-9330)';

  @override
  String get railway_logistics_desc => '철도 및 물류 관련 학과';

  @override
  String get health_medical_science_w5 => '보건의료과학관(W5)';

  @override
  String get health_medical_science_info =>
      'B1F\t주차장\n1F\t시청각실/주차장\n2F\t강의실\n2F\t스포츠건강재활학과(630-9840)\n3F\t응급구조학과(630-9280)\n3F\t간호학과(630-9290)\n4F\t작업치료학과(630-9820)\n4F\t언어치료청각재활학과(630-9220)\n5F\t물리치료학과(630-4620)\n5F\t보건의료경영학과(630-4610)\n5F\t강의실\n6F\t철도경영학과(630-9770)';

  @override
  String get health_medical_science_desc => '보건의료 관련 학과';

  @override
  String get liberal_arts_w6 => '교양교육관(W6)';

  @override
  String get liberal_arts_info => '2F\t강의실\n3F\t강의실\n4F\t강의실\n5F\t강의실';

  @override
  String get liberal_arts_desc => '교양 강의실';

  @override
  String get woosong_hall_w7 => '우송관(W7)';

  @override
  String get woosong_hall_info =>
      '1F\t입학처(630-9627)\n1F\t교무처(630-9622)\n1F\t시설처(630-9970)\n1F\t관리팀(629-6658)\n1F\t산학협력단(630-4653)\n1F\t대외협력처(630-9636)\n2F\t전략기획처(630-9102)\n2F\t총무처-총무,구매(630-9653)\n2F\t기획처(630-9661)\n3F\t총장실(630-8501)\n3F\t국제교류처(630-9373)\n3F\t유아교육과(630-9360)\n3F\t경영학전공(629-6640)\n3F\t금융/부동산학전공(630-9350)\n4F\t대회의실\n5F\t회의실';

  @override
  String get woosong_hall_desc => '대학 본부 건물';

  @override
  String get woosong_kindergarten_w8 => '우송유치원(W8)';

  @override
  String get woosong_kindergarten_info => '1F, 2F\t우송유치원(629~6750~1)';

  @override
  String get woosong_kindergarten_desc => '대학 부속 유치원';

  @override
  String get west_campus_culinary_w9 => '서캠퍼스정례원(W9)';

  @override
  String get west_campus_culinary_info => 'B1F\t실습실\n1F\t실습실\n2F\t실습실';

  @override
  String get west_campus_culinary_desc => '조리 실습 시설';

  @override
  String get social_welfare_w10 => '사회복지융합관(W10)';

  @override
  String get social_welfare_info =>
      '1F\t시청각실/실습실\n2F\t강의실/실습실\n3F\t사회복지학과(630-9830)\n3F\t글로벌아동교육학과(630-9260)\n4F\t강의실/실습실\n5F\t강의실/실습실';

  @override
  String get social_welfare_desc => '사회복지 관련 학과';

  @override
  String get gymnasium_w11 => '체육관(W11)';

  @override
  String get gymnasium_info => '1F\t체력단련실\n2F~4F\t체육관';

  @override
  String get gymnasium_desc => '체육 시설';

  @override
  String get sica_w12 => 'SICA(W12)';

  @override
  String get sica_info =>
      'B1F\t실습실\n1F\t스타리코카페\n2F~3F\t강의실\n5F\t글로벌조리학부(629-6860)';

  @override
  String get sica_desc => '국제조리학원';

  @override
  String get woosong_tower_w13 => '우송타워(W13)';

  @override
  String get woosong_tower_info =>
      'B1~1F\t주차장\n2F\t주차장, 솔파인 베이커리(629-6429)\n4F\t세미나실\n5F\t강의실\n6F\t외식조리영양학과(630-9380,9740)\n7F\t강의실\n8F\t외식,조리경영전공(630-9250)\n9F\t강의실/실습실\n10F\t외식조리전공(629-6821), 글로벌한식조리전공(629-6560)\n11F, 12F\t실습실\n13F\t솔파인레스토랑(629-6610)';

  @override
  String get woosong_tower_desc => '복합 교육시설';

  @override
  String get culinary_center_w14 => 'Culinary Center(W14)';

  @override
  String get culinary_center_info =>
      '1F\t강의실/실습실\n2F\t강의실/실습실\n3F\t강의실/실습실\n4F\t강의실/실습실\n5F\t강의실/실습실';

  @override
  String get culinary_center_desc => '조리 전문 교육시설';

  @override
  String get food_architecture_w15 => '식품건축관(W15)';

  @override
  String get food_architecture_info =>
      'B1F\t실습실\n1F\t실습실\n2F\t강의실\n3F\t강의실\n4F\t강의실\n5F\t강의실';

  @override
  String get food_architecture_desc => '식품 및 건축 관련 학과';

  @override
  String get student_hall_w16 => '학생회관(W16)';

  @override
  String get student_hall_info =>
      '1F\t학생식당, 구내서점(629-6127)\n2F\t교직원식당\n3F\t동아리방\n3F\t학생복지처-학생팀(630-9641), 장학팀(630-9876)\n3F\t장애학생지원센터(630-9903)\n3F\t사회봉사단(630-9904)\n3F\t학생상담센터(630-9645)\n4F\t복학지원센터(630-9139)\n4F\t교수학습개발센터(630-9285)';

  @override
  String get student_hall_desc => '학생 복지 시설';

  @override
  String get media_convergence_w17 => '미디어융합관(W17)';

  @override
  String get media_convergence_info =>
      'B1F\t강의실/실습실\n1F\t미디어디자인/영상전공(630-9750)\n2F\t강의실/실습실\n3F\t게임멀티미디어전공(630-9270)\n5F\t강의실/실습실';

  @override
  String get media_convergence_desc => '미디어 관련 학과';

  @override
  String get woosong_arts_center_w18 => '우송예술회관(W18)';

  @override
  String get woosong_arts_center_info =>
      'B1F\t공연준비실\n1F\t우송예술회관(629-6363)\n2F\t실습실\n3F\t실습실\n4F\t실습실\n5F\t실습실';

  @override
  String get woosong_arts_center_desc => '예술 공연 시설';

  @override
  String get west_campus_andycut_w19 => '서캠퍼스앤디컷빌딩(W19)';

  @override
  String get west_campus_andycut_info =>
      '2F\t글로벌융합비즈니스학과(630-9249)\n2F\t자유전공학부(630-9390)\n2F\tAI/빅데이터학과(630-9807)\n2F\t글로벌호텔매니지먼트학과(630-9249)\n2F\t글로벌미디어영상학과(630-9346)\n2F\t글로벌의료서비스경영학과(630-9283)\n2F\t글로벌철도/교통물류학부(630-9347)\n2F\t글로벌외식창업학과(629-6860)';

  @override
  String get west_campus_andycut_desc => '글로벌 학과 건물';

  @override
  String get operating => '운영중';

  @override
  String get dormitory => '기숙사';

  @override
  String get military_facility => '군사시설';

  @override
  String get kindergarten => '유치원';

  @override
  String get sports_facility => '체육시설';

  @override
  String get complex_facility => '복합시설';

  @override
  String get search_campus_buildings => '학교 건물을 검색해주세요';

  @override
  String get no_search_results => '검색 결과가 없습니다';

  @override
  String get building_details => '세부 정보';

  @override
  String get parking => '주차';

  @override
  String get accessibility => '접근성';

  @override
  String get facilities => '시설';

  @override
  String get elevator => '엘리베이터';

  @override
  String get restroom => '화장실';

  @override
  String get navigate_from_current_location => '현재 위치에서 길찾기';

  @override
  String get title => '회원정보 수정';

  @override
  String get nameRequired => '이름을 입력하세요';

  @override
  String get emailRequired => '이메일을 입력하세요';

  @override
  String get save => '저장하기';

  @override
  String get saveSuccess => '회원정보가 변경되었습니다';

  @override
  String get my_info => '내 정보';

  @override
  String get guest_user => '예질배 크루';

  @override
  String get guest_role => '정진영의 노예';

  @override
  String get user => '사용자';

  @override
  String get edit_profile => '회원정보 수정';

  @override
  String get edit_profile_subtitle => '개인정보를 수정할 수 있습니다';

  @override
  String get help_subtitle => '앱 사용법을 확인할 수 있습니다';

  @override
  String get app_info_subtitle => '버전 정보 및 개발자 정보';

  @override
  String get delete_account_subtitle => '계정을 영구적으로 삭제합니다';

  @override
  String get login_message => '모든 기능을 이용하려면\n로그인하거나 회원가입해주세요';

  @override
  String get login_signup => '로그인 / 회원가입';

  @override
  String get delete_account_confirm => '회원 탈퇴';

  @override
  String get delete_account_message => '정말로 탈퇴하시겠습니까?';

  @override
  String get logout_confirm => '로그아웃';

  @override
  String get logout_message => '정말 로그아웃하시겠습니까?';

  @override
  String get yes => '예';

  @override
  String get no => '아니오';

  @override
  String get feature_in_progress => '기능은 준비 중입니다';

  @override
  String get delete_feature_in_progress => '회원 탈퇴 기능은 준비 중입니다';

  @override
  String get app_info => '앱 정보';

  @override
  String get app_version => '앱 버전';

  @override
  String get developer => '개발자';

  @override
  String get developer_name => '이름: 홍길동';

  @override
  String get developer_email => '이메일: example@email.com';

  @override
  String get developer_github => 'GitHub: github.com/yourid';

  @override
  String get help => '도움말';

  @override
  String get no_help_images => '도움말 이미지가 없습니다';

  @override
  String get image_load_error => '이미지를 불러올 수 없습니다';

  @override
  String get description_hint => '설명 입력';

  @override
  String get email_required => '이메일을 입력하세요';

  @override
  String get name_required => '이름을 입력하세요';

  @override
  String get profile_updated => '프로필이 업데이트되었습니다';

  @override
  String get schedule => '시간표';

  @override
  String get winter_semester => '겨울학기';

  @override
  String get spring_semester => '1학기';

  @override
  String get summer_semester => '여름학기';

  @override
  String get fall_semester => '2학기';

  @override
  String get monday => '월';

  @override
  String get tuesday => '화';

  @override
  String get wednesday => '수';

  @override
  String get thursday => '목';

  @override
  String get friday => '금';

  @override
  String get time => '시간';

  @override
  String get add_class => '수업 추가';

  @override
  String get edit_class => '수업 수정';

  @override
  String get delete_class => '수업 삭제';

  @override
  String get class_name => '수업명';

  @override
  String get professor_name => '교수명';

  @override
  String get classroom => '강의실';

  @override
  String get day_of_week => '요일';

  @override
  String get start_time => '시작시간';

  @override
  String get end_time => '종료시간';

  @override
  String get color_selection => '색상 선택';

  @override
  String get monday_full => '월요일';

  @override
  String get tuesday_full => '화요일';

  @override
  String get wednesday_full => '수요일';

  @override
  String get thursday_full => '목요일';

  @override
  String get friday_full => '금요일';

  @override
  String get class_added => '수업이 추가되었습니다.';

  @override
  String get class_updated => '수업이 수정되었습니다.';

  @override
  String get class_deleted => '수업이 삭제되었습니다.';

  @override
  String delete_class_confirm(String className) {
    return '$className 수업을 삭제하시겠습니까?';
  }

  @override
  String get view_on_map => '지도보기';

  @override
  String get location => '강의실';

  @override
  String get schedule_time => '시간';

  @override
  String get schedule_day => '요일';

  @override
  String get map_feature_coming_soon => '지도 기능은 추후 추가될 예정입니다.';

  @override
  String current_year(int year) {
    return '$year년';
  }

  @override
  String get my_friends => '내 친구들';

  @override
  String online_friends(int total, int online) {
    return '총 $total명 • 온라인 $online명';
  }

  @override
  String get add_friend => '친구 추가';

  @override
  String get friend_name_or_id => '친구의 이름 또는 학번을 입력하세요';

  @override
  String get friend_request_sent => '친구 요청을 보냈습니다.';

  @override
  String get online => '온라인';

  @override
  String get offline => '오프라인';

  @override
  String get in_class => '수업 중';

  @override
  String last_location(String location) {
    return '마지막 위치: $location';
  }

  @override
  String get central_library => '중앙도서관';

  @override
  String get engineering_building => '공학관 201호';

  @override
  String get student_center => '학생회관';

  @override
  String get cafeteria => '카페테리아';

  @override
  String get message => '메시지';

  @override
  String get view_location => '위치 보기';

  @override
  String get call => '통화';

  @override
  String start_chat_with(String name) {
    return '$name님과의 채팅을 시작합니다.';
  }

  @override
  String view_location_on_map(String name) {
    return '$name님의 위치를 지도에서 확인합니다.';
  }

  @override
  String calling(String name) {
    return '$name님에게 전화를 겁니다.';
  }

  @override
  String get add => '추가';

  @override
  String get close => '닫기';

  @override
  String get edit => '편집';

  @override
  String get delete => '삭제';

  @override
  String get search => '검색';

  @override
  String get searchBuildings => '건물 검색...';

  @override
  String get myLocation => '내 위치';

  @override
  String get navigation => '길찾기';

  @override
  String get route => '경로';

  @override
  String get distance => '거리';

  @override
  String get minutes => '분';

  @override
  String get meters => '미터';

  @override
  String get findRoute => '경로 찾기';

  @override
  String get clearRoute => '경로 지우기';

  @override
  String get setAsStart => '출발지로 설정';

  @override
  String get setAsDestination => '목적지로 설정';

  @override
  String get navigateFromHere => '여기서 길찾기';

  @override
  String get buildingInfo => '건물 정보';

  @override
  String get category => '카테고리';

  @override
  String get locationPermissionRequired => '위치 권한이 필요합니다';

  @override
  String get enableLocationServices => '위치 서비스를 활성화해주세요';

  @override
  String get retry => '다시 시도';

  @override
  String get noResults => '검색 결과가 없습니다';

  @override
  String get settings => '설정';

  @override
  String get language => '언어';

  @override
  String get about => '정보';

  @override
  String friends_count_status(int total, int online) {
    return '총 $total명 • 온라인 $online명';
  }

  @override
  String get enter_friend_info => '친구의 이름 또는 학번을 입력하세요';

  @override
  String show_location_on_map(String name) {
    return '$name님의 위치를 지도에서 확인합니다.';
  }

  @override
  String get open_settings => '설정 열기';

  @override
  String get location_error => '위치를 찾을 수 없습니다.';

  @override
  String get view_floor_plan => '내부도면보기';

  @override
  String get floor_plan => '내부도면';

  @override
  String floor_plan_title(String buildingName) {
    return '$buildingName 내부도면';
  }

  @override
  String get floor_plan_not_available => '도면 이미지를 불러올 수 없습니다';

  @override
  String get floor_plan_default_text => '내부 도면';

  @override
  String get delete_account_success => '회원탈퇴가 완료되었습니다.';

  @override
  String get convenience_store => '편의점';

  @override
  String get vending_machine => '자판기';

  @override
  String get printer => '프린터';

  @override
  String get copier => '복사기';

  @override
  String get atm => 'ATM';

  @override
  String get bank_atm => '은행(atm)';

  @override
  String get medical => '의료';

  @override
  String get health_center => '보건소';

  @override
  String get gym => '체육관';

  @override
  String get fitness_center => '헬스장';

  @override
  String get lounge => '라운지';

  @override
  String get extinguisher => '소화기';

  @override
  String get water_purifier => '정수기';

  @override
  String get bookstore => '서점';

  @override
  String get post_office => '우체국';

  @override
  String get instructionExitToOutdoor => '건물 출구까지 이동하세요';

  @override
  String instructionMoveToDestination(Object place) {
    return '$place까지 이동하세요';
  }

  @override
  String instructionMoveToDestinationBuilding(Object building) {
    return '$building 건물까지 이동하세요';
  }

  @override
  String get instructionMoveToRoom => '목적지 호실까지 이동하세요';

  @override
  String get instructionArrived => '목적지에 도착했습니다!';

  @override
  String get search_hint => '학교 건물을 검색해주세요';

  @override
  String get searchHint => '건물명 또는 호실을 검색해주세요';

  @override
  String get searchInitialGuide => '건물명 또는 호실을 검색해보세요';

  @override
  String get searchHintExample => '예: W19, 공학관, 401호';

  @override
  String get searchLoading => '검색 중...';

  @override
  String get searchNoResult => '검색 결과가 없습니다';

  @override
  String get searchTryAgain => '다른 검색어로 시도해보세요';

  @override
  String get lectureRoom => '강의실';

  @override
  String get status_open => '운영중';

  @override
  String get status_closed => '운영종료';

  @override
  String get status_next_open => '오전 9시에 운영 시작';

  @override
  String get status_next_close => '오후 6시에 운영 종료';

  @override
  String get status_next_open_tomorrow => '내일 오전 9시에 운영 시작';

  @override
  String get office_hours => '09:00 - 18:00';

  @override
  String get status_24hours => '24시간';

  @override
  String get status_temp_closed => '임시휴무';

  @override
  String get status_closed_permanently => '휴무';

  @override
  String get label_basic_info => '기본 정보';

  @override
  String get label_category_type => '분류';

  @override
  String get label_status => '상태';

  @override
  String get label_hours => '운영시간';

  @override
  String get label_phone => '전화번호';

  @override
  String get label_coordinates => '좌표';

  @override
  String get unified_navigation => '통합 길찾기';

  @override
  String get unified_navigation_in_progress => '통합 길찾기 진행중';

  @override
  String get search_start_location => '출발지를 검색해주세요 (건물명 또는 호실)';

  @override
  String get search_end_location => '도착지를 검색해주세요 (건물명 또는 호실)';

  @override
  String get enter_start_location => '출발지를 입력해주세요';

  @override
  String get enter_end_location => '도착지를 입력해주세요';

  @override
  String get recent_searches => '최근 검색';

  @override
  String get clear_all => '전체 삭제';

  @override
  String get searching => '검색 중...';

  @override
  String get try_different_keyword => '다른 검색어로 시도해보세요';

  @override
  String get my_location => '내 위치';

  @override
  String get start_from_current_location => '현재 위치에서 출발';

  @override
  String get getting_current_location => '현재 위치를 가져오는 중...';

  @override
  String get current_location_set_as_start => '현재 위치가 출발지로 설정되었습니다';

  @override
  String get using_default_location => '기본 위치를 사용합니다';

  @override
  String get start_unified_navigation => '통합 길찾기 시작';

  @override
  String get set_both_locations => '출발지와 도착지를 모두 설정해주세요';

  @override
  String get navigation_ended => '길찾기가 종료되었습니다';

  @override
  String get route_preview => '경로 미리보기';

  @override
  String get calculating_optimal_route => '최적 경로를 계산하고 있습니다...';

  @override
  String get set_departure_and_destination =>
      '출발지와 도착지를 설정해주세요\\n건물명 또는 호실을 입력할 수 있습니다';

  @override
  String get total_distance => '총 거리';

  @override
  String get route_type => '경로 타입';

  @override
  String get departure_indoor => '출발지 실내';

  @override
  String get to_building_exit => '건물 출구까지';

  @override
  String get outdoor_movement => '실외 이동';

  @override
  String get to_destination_building => '목적지 건물까지';

  @override
  String get arrival_indoor => '도착지 실내';

  @override
  String get to_final_destination => '최종 목적지까지';

  @override
  String get building_to_building => '건물간';

  @override
  String get room_to_building => '호실→건물';

  @override
  String get building_to_room => '건물→호실';

  @override
  String get room_to_room => '호실간';

  @override
  String get location_to_building => '현위치→건물';

  @override
  String get unified_route => '통합경로';

  @override
  String preset_room_start(Object building, Object room) {
    return '$building $room호가 출발지로 설정되었습니다';
  }

  @override
  String preset_room_end(Object building, Object room) {
    return '$building $room호가 도착지로 설정되었습니다';
  }

  @override
  String preset_building_start(Object building) {
    return '$building이 출발지로 설정되었습니다';
  }

  @override
  String preset_building_end(Object building) {
    return '$building이 도착지로 설정되었습니다';
  }

  @override
  String floor_room(Object floor, Object room) {
    return '$floor층 $room호';
  }

  @override
  String get available => '사용가능';

  @override
  String get current_location => '현재위치';

  @override
  String get start_navigation_from_here => '현재 위치에서 길찾기를 시작합니다';

  @override
  String get directions => '길찾기';

  @override
  String get navigateHere => '여기까지';

  @override
  String get startLocation => '출발지';

  @override
  String get endLocation => '도착지';

  @override
  String get floor_plans => '층별 도면 보기';

  @override
  String get select_floor_to_view => '각 층을 선택하여 상세 도면을 확인하세요';

  @override
  String get floor_info => '층 정보';

  @override
  String get view_floor_plan_button => '층 도면 보기';

  @override
  String get no_detailed_info => '상세 정보가 없습니다.';

  @override
  String get pinch_to_zoom => '핀치하여 확대/축소, 드래그하여 이동';

  @override
  String get floor_plan_loading_failed => '도면 로딩 실패';

  @override
  String loading_floor_plan(Object floor) {
    return '$floor 도면을 불러오는 중…';
  }

  @override
  String server_info(Object building, Object floor) {
    return '서버: $building/$floor';
  }

  @override
  String get building_name => '건물';

  @override
  String get floor_number => '층';

  @override
  String get room_name => '강의실';

  @override
  String get overlap_message => '이미 같은 시간에 등록된 수업이 있습니다.';

  @override
  String get memo => '메모';

  @override
  String get friendManagement => '친구 관리 및 요청';

  @override
  String get friendManagementAndRequests => '친구 관리 및 요청';

  @override
  String get showLocation => '위치 보기';

  @override
  String get removeLocation => '위치 제거';

  @override
  String get accept => '수락';

  @override
  String get reject => '거절';

  @override
  String get id => 'ID';

  @override
  String get contact => '연락처';

  @override
  String get lastLocation => '마지막 위치';

  @override
  String get noLocationInfo => '위치 정보 없음';

  @override
  String get noContactInfo => '정보 없음';

  @override
  String friendRequestSent(String name) {
    return '$name님에게 친구 요청을 전송했습니다!';
  }

  @override
  String friendRequestAccepted(String name) {
    return '$name님의 친구 요청을 수락했습니다.';
  }

  @override
  String friendRequestRejected(String name) {
    return '$name님의 친구 요청을 거절했습니다.';
  }

  @override
  String friendRequestCanceled(String name) {
    return '$name님에게 보낸 친구 요청을 취소했습니다.';
  }

  @override
  String friendDeleted(String name) {
    return '$name님을 친구 목록에서 삭제했습니다.';
  }

  @override
  String friendLocationShown(String name) {
    return '$name님의 위치를 지도에 표시했습니다.';
  }

  @override
  String friendLocationRemoved(String name) {
    return '$name님의 위치를 지도에서 제거했습니다.';
  }

  @override
  String friendCount(int count) {
    return '내 친구 ($count)';
  }

  @override
  String sentRequestsCount(int count) {
    return '보낸 ($count)';
  }

  @override
  String receivedRequestsCount(int count) {
    return '받은 ($count)';
  }

  @override
  String newFriendRequests(int count) {
    return '새로운 친구 요청 $count개';
  }

  @override
  String get addFriend => '추가';

  @override
  String get sent => '보낸';

  @override
  String get received => '받은';

  @override
  String get sendFriendRequest => '친구 요청 보내기';

  @override
  String get friendId => '친구 ID';

  @override
  String get enterFriendId => '상대방 ID를 입력하세요';

  @override
  String get enterFriendIdPrompt => '추가할 친구의 ID를 입력해주세요';

  @override
  String get errorEnterFriendId => '친구 ID를 입력해주세요.';

  @override
  String get errorCannotAddSelf => '자기 자신은 친구로 추가할 수 없습니다.';

  @override
  String get errorAddFriend => '친구 추가 중 오류가 발생했습니다.';

  @override
  String get errorNetworkError => '네트워크 오류가 발생했습니다. 다시 시도해주세요.';

  @override
  String get errorCannotShowLocation => '친구 위치를 표시할 수 없습니다.';

  @override
  String get errorCannotRemoveLocation => '친구 위치를 제거할 수 없습니다.';

  @override
  String get realTimeSyncActive => '실시간 동기화 중 • 자동으로 업데이트됩니다';

  @override
  String realTimeSyncStatus(String time) {
    return '실시간 동기화 활성 • $time';
  }

  @override
  String get noSentRequests => '보낸 친구 요청이 없습니다.';

  @override
  String get noReceivedRequests => '받은 친구 요청이 없습니다.';

  @override
  String get noFriends => '아직 친구가 없습니다.\n상단의 + 버튼으로 친구를 추가해보세요!';

  @override
  String get cancelFriendRequest => '친구 요청 취소';

  @override
  String cancelFriendRequestConfirm(String name) {
    return '$name님에게 보낸 친구 요청을 취소하시겠습니까?';
  }

  @override
  String get deleteFriend => '친구 삭제';

  @override
  String deleteFriendConfirm(String name) {
    return '$name님을 친구 목록에서 삭제하시겠습니까?';
  }

  @override
  String get cancelRequest => '취소하기';

  @override
  String requestDate(String date) {
    return '요청일: $date';
  }

  @override
  String get newBadge => 'NEW';

  @override
  String get friend_delete_title => '친구 삭제';

  @override
  String get friend_delete_warning => '신중하게 결정해주세요';

  @override
  String friendDeleteQuestion(Object userName) {
    return '$userName님을 친구 목록에서 삭제하시겠습니까?\n삭제된 친구는 다시 추가할 수 있습니다.';
  }

  @override
  String get empty_friend_list_message => '친구가 없습니다.';

  @override
  String get friendDeleteTitle => '친구 삭제';

  @override
  String get friendDeleteWarning => '신중하게 결정해주세요';

  @override
  String get friendDeleteHeader => '삭제할 친구';

  @override
  String friendDeleteToConfirm(Object userName) {
    return '$userName님을 친구 목록에서 삭제하시겠습니까?\n삭제된 친구는 다시 추가할 수 있습니다.';
  }

  @override
  String get friendDeleteCancel => '취소';

  @override
  String get friendDeleteButton => '삭제';

  @override
  String friendDeleteSuccessMessage(Object userName) {
    return '$userName님을 친구 목록에서 삭제했습니다.';
  }
}
