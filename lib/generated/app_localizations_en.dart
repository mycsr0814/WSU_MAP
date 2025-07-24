// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Campus Navigator';

  @override
  String get subtitle => 'Your smart campus guide';

  @override
  String get woosong => 'Woosong';

  @override
  String get start => 'Start';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get guest => 'Guest';

  @override
  String get student_professor => 'Student/Professor';

  @override
  String get admin => 'Administrator';

  @override
  String get student => 'Student';

  @override
  String get professor => 'Professor';

  @override
  String get external_user => 'External';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get confirm_password => 'Confirm Password';

  @override
  String get remember_me => 'Remember login info';

  @override
  String get remember_me_description =>
      'You will be logged in automatically next time';

  @override
  String get login_as_guest => 'Browse as Guest';

  @override
  String get login_failed => 'Login Failed';

  @override
  String get login_success => 'Login Successful';

  @override
  String get logout_success => 'Logged out successfully';

  @override
  String get enter_username => 'Enter your username';

  @override
  String get enter_password => 'Enter your password';

  @override
  String get password_hint => 'Enter 6+ characters';

  @override
  String get confirm_password_hint => 'Re-enter your password';

  @override
  String get username_password_required =>
      'Please enter both username and password';

  @override
  String get login_error => 'Login failed';

  @override
  String get find_password => 'Find Password';

  @override
  String get find_username => 'Find Username';

  @override
  String get back => 'Back';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get coming_soon => 'Coming Soon';

  @override
  String feature_coming_soon(String feature) {
    return '$feature feature is under development.\nIt will be added soon.';
  }

  @override
  String get start_campus_exploration => 'Start exploring the campus';

  @override
  String get woosong_university => 'Woosong University';

  @override
  String get campus_navigator => 'Campus Navigator';

  @override
  String get user_info_not_found =>
      'User information not found in login response';

  @override
  String get unexpected_login_error =>
      'An unexpected error occurred during login';

  @override
  String get login_required => 'Login required';

  @override
  String get register => 'Register';

  @override
  String get register_success => 'Registration completed successfully';

  @override
  String get register_success_message =>
      'Registration completed!\nRedirecting to login screen.';

  @override
  String get register_error =>
      'An unexpected error occurred during registration';

  @override
  String get update_user_info => 'Update User Information';

  @override
  String get update_success => 'User information updated successfully';

  @override
  String get update_error =>
      'An unexpected error occurred while updating user information';

  @override
  String get delete_account => 'Delete Account';

  @override
  String get delete_success => 'Account deleted successfully';

  @override
  String get delete_error =>
      'An unexpected error occurred while deleting account';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone Number';

  @override
  String get email => 'Email';

  @override
  String get student_number => 'Student Number';

  @override
  String get user_type => 'User Type';

  @override
  String get optional => 'Optional';

  @override
  String get required_fields_empty => 'Please fill in all required fields';

  @override
  String get password_mismatch => 'Passwords do not match';

  @override
  String get password_too_short => 'Password must be at least 6 characters';

  @override
  String get invalid_phone_format =>
      'Please enter a valid phone number format (e.g., 010-1234-5678)';

  @override
  String get invalid_email_format => 'Please enter a valid email format';

  @override
  String get required_fields_notice => '* marked fields are required';

  @override
  String get welcome_to_campus_navigator =>
      'Welcome to Woosong Campus Navigator';

  @override
  String get enter_real_name => 'Enter your real name';

  @override
  String get phone_format_hint => '010-1234-5678';

  @override
  String get enter_student_number => 'Enter your student or employee number';

  @override
  String get email_hint => 'example@woosong.org';

  @override
  String get create_account => 'Create Account';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get validation_error => 'Please check your input';

  @override
  String get network_error => 'Network error occurred';

  @override
  String get server_error => 'Server error occurred';

  @override
  String get unknown_error => 'Unknown error occurred';

  @override
  String get select_auth_method => 'Select Authentication Method';

  @override
  String get woosong_campus_guide_service =>
      'Woosong University Campus Navigation Service';

  @override
  String get register_description => 'Create a new account to use all features';

  @override
  String get login_description =>
      'Log in with your existing account to use the service';

  @override
  String get browse_as_guest => 'Browse as Guest';

  @override
  String get processing => 'Processing...';

  @override
  String get campus_navigator_version => 'Campus Navigator v1.0';

  @override
  String get guest_mode => 'Guest Mode';

  @override
  String get guest_mode_description =>
      'In guest mode, you can only view basic campus information.\nPlease register and log in to use all features.';

  @override
  String get continue_as_guest => 'Continue as Guest';

  @override
  String get moved_to_my_location => 'Automatically moved to my location';

  @override
  String get friends_screen_bottom_sheet =>
      'Friends screen is displayed as bottom sheet';

  @override
  String get finding_current_location => 'Finding current location...';

  @override
  String get home => 'Home';

  @override
  String get timetable => 'Timetable';

  @override
  String get friends => 'Friends';

  @override
  String get my_page => 'MY';

  @override
  String get cafe => 'Cafe';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get library => 'Library';

  @override
  String get educational_facility => 'Educational Facility';

  @override
  String get estimated_distance => 'Est. Distance';

  @override
  String get estimated_time => 'Est. Time';

  @override
  String get calculating => 'Calculating...';

  @override
  String get calculating_route => 'Calculating route...';

  @override
  String get finding_optimal_route => 'Finding optimal route from server';

  @override
  String get departure => 'Departure';

  @override
  String get destination => 'Destination';

  @override
  String get clear_route => 'Clear Route';

  @override
  String get location_permission_denied =>
      'Location permission denied.\nPlease allow location permission in settings.';

  @override
  String finding_route_to_building(String building) {
    return 'Finding route to $building...';
  }

  @override
  String route_displayed_to_building(String building) {
    return 'Route to $building displayed';
  }

  @override
  String set_as_departure(String building) {
    return 'Set $building as departure.';
  }

  @override
  String set_as_destination(String building) {
    return 'Set $building as destination.';
  }

  @override
  String get woosong_library_w1 => 'Woosong Library (W1)';

  @override
  String get woosong_library_info =>
      'B2F\tParking\nB1F\tSmall auditorium, Equipment room, Electrical room, Parking\n1F\tCareer Support Center (630-9976), Loan desk, Information lounge\n2F\tGeneral reading room, Group study room\n3F\tGeneral reading room\n4F\tLiterature books/Western books';

  @override
  String get woosong_library_desc => 'Woosong University Central Library';

  @override
  String get sol_cafe => 'Sol Cafe';

  @override
  String get sol_cafe_info => '1F\tRestaurant\n2F\tCafe';

  @override
  String get sol_cafe_desc => 'Campus cafe';

  @override
  String get cheongun_1_dormitory => 'Cheongun 1 Dormitory';

  @override
  String get cheongun_1_dormitory_info =>
      '1F\tPractice room\n2F\tStudent restaurant\n2F\tCheongun 1 Dormitory (Female) (629-6542)\n2F\tDormitory\n3~5F\tDormitory';

  @override
  String get cheongun_1_dormitory_desc => 'Female dormitory';

  @override
  String get industry_cooperation_w2 => 'Industry-University Cooperation (W2)';

  @override
  String get industry_cooperation_info =>
      '1F\tIndustry-University Cooperation\n2F\tArchitectural Engineering (630-9720)\n3F\tWoosong University Convergence Technology Research Institute, Industry-Academia-Research General Enterprise Support Center\n4F\tCorporate Research Institute, LG CNS Classroom, Railway Digital Academy Classroom';

  @override
  String get industry_cooperation_desc =>
      'Industry-academia cooperation and research facilities';

  @override
  String get rotc_w2_1 => 'ROTC (W2-1)';

  @override
  String get rotc_info => '\tROTC (630-4601)';

  @override
  String get rotc_desc => 'ROTC facilities';

  @override
  String get international_dormitory_w3 =>
      'International Student Dormitory (W3)';

  @override
  String get international_dormitory_info =>
      '1F\tInternational Student Support Team (629-6623)\n1F\tStudent restaurant\n2F\tInternational Student Dormitory (629-6655)\n2F\tHealth center\n3~12F\tDormitory';

  @override
  String get international_dormitory_desc => 'International student dormitory';

  @override
  String get railway_logistics_w4 => 'Railway Logistics Building (W4)';

  @override
  String get railway_logistics_info =>
      'B1F\tPractice room\n1F\tPractice room\n2F\tRailway Construction System Department (629-6710)\n2F\tRailway Vehicle System Department (629-6780)\n3F\tClassroom/Practice room\n4F\tRailway System Department (630-6730,9700)\n5F\tFire and Disaster Prevention Department (629-6770)\n5F\tLogistics System Department (630-9330)';

  @override
  String get railway_logistics_desc =>
      'Railway and logistics related departments';

  @override
  String get health_medical_science_w5 =>
      'Health and Medical Science Building (W5)';

  @override
  String get health_medical_science_info =>
      'B1F\tParking\n1F\tAudiovisual room/Parking\n2F\tClassroom\n2F\tSports Health Rehabilitation Department (630-9840)\n3F\tEmergency Medical Services Department (630-9280)\n3F\tNursing Department (630-9290)\n4F\tOccupational Therapy Department (630-9820)\n4F\tSpeech Therapy and Audiology Department (630-9220)\n5F\tPhysical Therapy Department (630-4620)\n5F\tHealth and Medical Management Department (630-4610)\n5F\tClassroom\n6F\tRailway Management Department (630-9770)';

  @override
  String get health_medical_science_desc =>
      'Health and medical related departments';

  @override
  String get liberal_arts_w6 => 'Liberal Arts Building (W6)';

  @override
  String get liberal_arts_info =>
      '2F\tClassroom\n3F\tClassroom\n4F\tClassroom\n5F\tClassroom';

  @override
  String get liberal_arts_desc => 'Liberal arts classrooms';

  @override
  String get woosong_hall_w7 => 'Woosong Hall (W7)';

  @override
  String get woosong_hall_info =>
      '1F\tAdmissions Office (630-9627)\n1F\tAcademic Affairs Office (630-9622)\n1F\tFacilities Office (630-9970)\n1F\tManagement Team (629-6658)\n1F\tIndustry-University Cooperation (630-4653)\n1F\tExternal Cooperation Office (630-9636)\n2F\tStrategic Planning Office (630-9102)\n2F\tGeneral Affairs Office-General Affairs, Purchasing (630-9653)\n2F\tPlanning Office (630-9661)\n3F\tPresident\'s Office (630-8501)\n3F\tInternational Exchange Office (630-9373)\n3F\tEarly Childhood Education Department (630-9360)\n3F\tBusiness Administration Major (629-6640)\n3F\tFinance/Real Estate Major (630-9350)\n4F\tLarge conference room\n5F\tConference room';

  @override
  String get woosong_hall_desc => 'University main building';

  @override
  String get woosong_kindergarten_w8 => 'Woosong Kindergarten (W8)';

  @override
  String get woosong_kindergarten_info =>
      '1F, 2F\tWoosong Kindergarten (629~6750~1)';

  @override
  String get woosong_kindergarten_desc => 'University affiliated kindergarten';

  @override
  String get west_campus_culinary_w9 => 'West Campus Culinary Institute (W9)';

  @override
  String get west_campus_culinary_info =>
      'B1F\tPractice room\n1F\tPractice room\n2F\tPractice room';

  @override
  String get west_campus_culinary_desc => 'Culinary practice facilities';

  @override
  String get social_welfare_w10 => 'Social Welfare Convergence Building (W10)';

  @override
  String get social_welfare_info =>
      '1F\tAudiovisual room/Practice room\n2F\tClassroom/Practice room\n3F\tSocial Welfare Department (630-9830)\n3F\tGlobal Child Education Department (630-9260)\n4F\tClassroom/Practice room\n5F\tClassroom/Practice room';

  @override
  String get social_welfare_desc => 'Social welfare related departments';

  @override
  String get gymnasium_w11 => 'Gymnasium (W11)';

  @override
  String get gymnasium_info => '1F\tFitness center\n2F~4F\tGymnasium';

  @override
  String get gymnasium_desc => 'Sports facilities';

  @override
  String get sica_w12 => 'SICA (W12)';

  @override
  String get sica_info =>
      'B1F\tPractice room\n1F\tStarrico Cafe\n2F~3F\tClassroom\n5F\tGlobal Culinary Department (629-6860)';

  @override
  String get sica_desc => 'International Culinary Institute';

  @override
  String get woosong_tower_w13 => 'Woosong Tower (W13)';

  @override
  String get woosong_tower_info =>
      'B1~1F\tParking\n2F\tParking, Solpine Bakery (629-6429)\n4F\tSeminar room\n5F\tClassroom\n6F\tFood Service Culinary Nutrition Department (630-9380,9740)\n7F\tClassroom\n8F\tFood Service, Culinary Management Major (630-9250)\n9F\tClassroom/Practice room\n10F\tFood Service Culinary Major (629-6821), Global Korean Culinary Major (629-6560)\n11F, 12F\tPractice room\n13F\tSolpine Restaurant (629-6610)';

  @override
  String get woosong_tower_desc => 'Complex educational facility';

  @override
  String get culinary_center_w14 => 'Culinary Center (W14)';

  @override
  String get culinary_center_info =>
      '1F\tClassroom/Practice room\n2F\tClassroom/Practice room\n3F\tClassroom/Practice room\n4F\tClassroom/Practice room\n5F\tClassroom/Practice room';

  @override
  String get culinary_center_desc =>
      'Culinary specialized educational facility';

  @override
  String get food_architecture_w15 => 'Food Architecture Building (W15)';

  @override
  String get food_architecture_info =>
      'B1F\tPractice room\n1F\tPractice room\n2F\tClassroom\n3F\tClassroom\n4F\tClassroom\n5F\tClassroom';

  @override
  String get food_architecture_desc =>
      'Food and architecture related departments';

  @override
  String get student_hall_w16 => 'Student Hall (W16)';

  @override
  String get student_hall_info =>
      '1F\tStudent restaurant, Campus bookstore (629-6127)\n2F\tFaculty restaurant\n3F\tClub rooms\n3F\tStudent Welfare Office-Student Team (630-9641), Scholarship Team (630-9876)\n3F\tDisabled Student Support Center (630-9903)\n3F\tSocial Service Corps (630-9904)\n3F\tStudent Counseling Center (630-9645)\n4F\tReturn to School Support Center (630-9139)\n4F\tCenter for Teaching and Learning Development (630-9285)';

  @override
  String get student_hall_desc => 'Student welfare facilities';

  @override
  String get media_convergence_w17 => 'Media Convergence Building (W17)';

  @override
  String get media_convergence_info =>
      'B1F\tClassroom/Practice room\n1F\tMedia Design/Video Major (630-9750)\n2F\tClassroom/Practice room\n3F\tGame Multimedia Major (630-9270)\n5F\tClassroom/Practice room';

  @override
  String get media_convergence_desc => 'Media related departments';

  @override
  String get woosong_arts_center_w18 => 'Woosong Arts Center (W18)';

  @override
  String get woosong_arts_center_info =>
      'B1F\tPerformance preparation room\n1F\tWoosong Arts Center (629-6363)\n2F\tPractice room\n3F\tPractice room\n4F\tPractice room\n5F\tPractice room';

  @override
  String get woosong_arts_center_desc => 'Arts performance facility';

  @override
  String get west_campus_andycut_w19 => 'West Campus AndyCut Building (W19)';

  @override
  String get west_campus_andycut_info =>
      '2F\tGlobal Convergence Business Department (630-9249)\n2F\tLiberal Arts Department (630-9390)\n2F\tAI/Big Data Department (630-9807)\n2F\tGlobal Hotel Management Department (630-9249)\n2F\tGlobal Media Video Department (630-9346)\n2F\tGlobal Medical Service Management Department (630-9283)\n2F\tGlobal Railway/Transportation Logistics Department (630-9347)\n2F\tGlobal Food Service Entrepreneurship Department (629-6860)';

  @override
  String get west_campus_andycut_desc => 'Global departments building';

  @override
  String get operating => 'Operating';

  @override
  String get dormitory => 'Dormitory';

  @override
  String get military_facility => 'Military Facility';

  @override
  String get kindergarten => 'Kindergarten';

  @override
  String get sports_facility => 'Sports Facility';

  @override
  String get complex_facility => 'Complex Facility';

  @override
  String get search_campus_buildings => 'Search campus buildings';

  @override
  String get no_search_results => 'No search results';

  @override
  String get building_details => 'Details';

  @override
  String get parking => 'Parking';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get facilities => 'Facilities';

  @override
  String get elevator => 'Elevator';

  @override
  String get restroom => 'Restroom';

  @override
  String get navigate_from_current_location => 'Navigate from current location';

  @override
  String get title => 'Edit Profile';

  @override
  String get nameRequired => 'Please enter your name';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get save => 'Save';

  @override
  String get saveSuccess => 'Profile has been updated.';

  @override
  String get my_info => 'My Info';

  @override
  String get guest_user => 'Yejilebae Crew';

  @override
  String get guest_role => 'Slave of JinYoung Jung';

  @override
  String get user => 'User';

  @override
  String get edit_profile => 'Edit Profile';

  @override
  String get edit_profile_subtitle =>
      'You can modify your personal information';

  @override
  String get help_subtitle => 'Check how to use the app';

  @override
  String get app_info_subtitle => 'Version info and developer info';

  @override
  String get delete_account_subtitle => 'Permanently delete your account';

  @override
  String get login_message => 'Please login or sign up\nto use all features';

  @override
  String get login_signup => 'Login / Sign Up';

  @override
  String get delete_account_confirm => 'Delete Account';

  @override
  String get delete_account_message =>
      'Are you sure you want to delete your account?';

  @override
  String get logout_confirm => 'Logout';

  @override
  String get logout_message => 'Are you sure you want to logout?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get feature_in_progress => 'feature is under development.';

  @override
  String get delete_feature_in_progress =>
      'Account deletion feature is under development.';

  @override
  String get app_info => 'App Info';

  @override
  String get app_version => 'App Version';

  @override
  String get developer => 'Developer';

  @override
  String get developer_name => 'Name: Hong Gil-dong';

  @override
  String get developer_email => 'Email: example@email.com';

  @override
  String get developer_github => 'GitHub: github.com/yourid';

  @override
  String get help => 'Help';

  @override
  String get no_help_images => 'No help images available';

  @override
  String get image_load_error => 'Unable to load image';

  @override
  String get description_hint => 'Enter description';

  @override
  String get email_required => 'Please enter your email';

  @override
  String get name_required => 'Please enter your name';

  @override
  String get profile_updated => 'Profile has been updated';

  @override
  String get schedule => 'Schedule';

  @override
  String get winter_semester => 'Winter';

  @override
  String get spring_semester => 'Spring';

  @override
  String get summer_semester => 'Summer';

  @override
  String get fall_semester => 'Fall';

  @override
  String get monday => 'Mon';

  @override
  String get tuesday => 'Tue';

  @override
  String get wednesday => 'Wed';

  @override
  String get thursday => 'Thu';

  @override
  String get friday => 'Fri';

  @override
  String get time => 'Time';

  @override
  String get add_class => 'Add Class';

  @override
  String get edit_class => 'Edit Class';

  @override
  String get delete_class => 'Delete Class';

  @override
  String get class_name => 'Class Name';

  @override
  String get professor_name => 'Professor';

  @override
  String get classroom => 'Classroom';

  @override
  String get day_of_week => 'Day';

  @override
  String get start_time => 'Start Time';

  @override
  String get end_time => 'End Time';

  @override
  String get color_selection => 'Select Color';

  @override
  String get monday_full => 'Monday';

  @override
  String get tuesday_full => 'Tuesday';

  @override
  String get wednesday_full => 'Wednesday';

  @override
  String get thursday_full => 'Thursday';

  @override
  String get friday_full => 'Friday';

  @override
  String get class_added => 'Class has been added.';

  @override
  String get class_updated => 'Class has been updated.';

  @override
  String get class_deleted => 'Class has been deleted.';

  @override
  String delete_class_confirm(String className) {
    return 'Do you want to delete $className?';
  }

  @override
  String get view_on_map => 'View on Map';

  @override
  String get location => 'Location';

  @override
  String get schedule_time => 'Time';

  @override
  String get schedule_day => 'Day';

  @override
  String get map_feature_coming_soon => 'Map feature will be added later.';

  @override
  String current_year(int year) {
    return '$year';
  }

  @override
  String get my_friends => 'My Friends';

  @override
  String online_friends(int total, int online) {
    return 'Total $total • Online $online';
  }

  @override
  String get add_friend => 'Add Friend';

  @override
  String get friend_name_or_id => 'Enter friend\'s name or student ID';

  @override
  String get friend_request_sent => 'Friend request sent.';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get in_class => 'In Class';

  @override
  String last_location(String location) {
    return 'Last location: $location';
  }

  @override
  String get central_library => 'Central Library';

  @override
  String get engineering_building => 'Engineering Building 201';

  @override
  String get student_center => 'Student Center';

  @override
  String get cafeteria => 'Cafeteria';

  @override
  String get message => 'Message';

  @override
  String get view_location => 'View Location';

  @override
  String get call => 'Call';

  @override
  String start_chat_with(String name) {
    return 'Starting chat with $name.';
  }

  @override
  String view_location_on_map(String name) {
    return 'View $name\'s location on map.';
  }

  @override
  String calling(String name) {
    return 'Calling $name.';
  }

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get search => 'Search';

  @override
  String get searchBuildings => 'Search buildings...';

  @override
  String get myLocation => 'My Location';

  @override
  String get navigation => 'Navigation';

  @override
  String get route => 'Route';

  @override
  String get distance => 'Distance';

  @override
  String get minutes => 'minutes';

  @override
  String get meters => 'meters';

  @override
  String get findRoute => 'Find Route';

  @override
  String get clearRoute => 'Clear Route';

  @override
  String get setAsStart => 'Set as Start';

  @override
  String get setAsDestination => 'Set as Destination';

  @override
  String get navigateFromHere => 'Navigate from Here';

  @override
  String get buildingInfo => 'Building Information';

  @override
  String get category => 'Category';

  @override
  String get locationPermissionRequired => 'Location permission is required';

  @override
  String get enableLocationServices => 'Please enable location services';

  @override
  String get retry => 'Retry';

  @override
  String get noResults => 'No results found';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get about => 'About';

  @override
  String friends_count_status(int total, int online) {
    return 'Total $total • Online $online';
  }

  @override
  String get enter_friend_info => 'Enter friend\'s name or student ID';

  @override
  String show_location_on_map(String name) {
    return 'Showing $name\'s location on map.';
  }

  @override
  String get open_settings => 'Open Settings';

  @override
  String get location_error => 'Unable to find your location.';

  @override
  String get view_floor_plan => 'View Floor Plan';

  @override
  String get floor_plan => 'Floor Plan';

  @override
  String floor_plan_title(String buildingName) {
    return '$buildingName Floor Plan';
  }

  @override
  String get floor_plan_not_available => 'Unable to load floor plan image';

  @override
  String get floor_plan_default_text => 'Floor Plan';

  @override
  String get delete_account_success => 'Your account has been deleted.';

  @override
  String get convenience_store => 'Convenience Store';

  @override
  String get vending_machine => 'Vending Machine';

  @override
  String get printer => 'Printer';

  @override
  String get copier => 'Copier';

  @override
  String get atm => 'ATM';

  @override
  String get bank_atm => 'Bank(ATM)';

  @override
  String get medical => 'Medical';

  @override
  String get health_center => 'Health Center';

  @override
  String get gym => 'Gym';

  @override
  String get fitness_center => 'Fitness Center';

  @override
  String get lounge => 'Lounge';

  @override
  String get extinguisher => 'Extinguisher';

  @override
  String get water_purifier => 'Water Purifier';

  @override
  String get bookstore => 'Bookstore';

  @override
  String get post_office => 'Post Office';

  @override
  String get instructionExitToOutdoor => 'Go to the building exit';

  @override
  String instructionMoveToDestination(Object place) {
    return 'Go to $place';
  }

  @override
  String instructionMoveToDestinationBuilding(Object building) {
    return 'Go to $building building';
  }

  @override
  String get instructionMoveToRoom => 'Proceed to the destination room';

  @override
  String get instructionArrived => 'You have arrived at your destination!';

  @override
  String get search_hint => 'Search campus buildings';

  @override
  String get searchHint => 'Search by building or room';

  @override
  String get searchInitialGuide => 'Search for a building or room';

  @override
  String get searchHintExample => 'e.g. W19, Engineering Hall, Room 401';

  @override
  String get searchLoading => 'Searching...';

  @override
  String get searchNoResult => 'No results found';

  @override
  String get searchTryAgain => 'Try a different search term';

  @override
  String get lectureRoom => 'Lecture Room';

  @override
  String get status_open => 'Open';

  @override
  String get status_closed => 'Closed';

  @override
  String get status_next_open => 'Opens at 9:00 AM';

  @override
  String get status_next_close => 'Closes at 6:00 PM';

  @override
  String get status_next_open_tomorrow => 'Opens tomorrow at 9:00 AM';

  @override
  String get office_hours => '09:00 - 18:00';

  @override
  String get status_24hours => '24 Hours';

  @override
  String get status_temp_closed => 'Temporarily Closed';

  @override
  String get status_closed_permanently => 'Permanently Closed';

  @override
  String get label_basic_info => 'Basic Info';

  @override
  String get label_category_type => 'Category';

  @override
  String get label_status => 'Status';

  @override
  String get label_hours => 'Operating Hours';

  @override
  String get label_phone => 'Phone Number';

  @override
  String get label_coordinates => 'Coordinates';

  @override
  String get unified_navigation => 'Unified Navigation';

  @override
  String get unified_navigation_in_progress => 'Unified Navigation in Progress';

  @override
  String get search_start_location =>
      'Search for departure location (building or room)';

  @override
  String get search_end_location => 'Search for destination (building or room)';

  @override
  String get enter_start_location => 'Enter departure location';

  @override
  String get enter_end_location => 'Enter destination';

  @override
  String get recent_searches => 'Recent Searches';

  @override
  String get clear_all => 'Clear All';

  @override
  String get searching => 'Searching...';

  @override
  String get try_different_keyword => 'Try a different keyword';

  @override
  String get my_location => 'My Location';

  @override
  String get start_from_current_location => 'Start from current location';

  @override
  String get getting_current_location => 'Getting current location...';

  @override
  String get current_location_set_as_start =>
      'Current location set as departure';

  @override
  String get using_default_location => 'Using default location';

  @override
  String get start_unified_navigation => 'Start Unified Navigation';

  @override
  String get set_both_locations => 'Please set both departure and destination';

  @override
  String get navigation_ended => 'Navigation ended';

  @override
  String get route_preview => 'Route Preview';

  @override
  String get calculating_optimal_route => 'Calculating optimal route...';

  @override
  String get set_departure_and_destination =>
      'Please set departure and destination\nYou can enter building name or room number';

  @override
  String get total_distance => 'Total Distance';

  @override
  String get route_type => 'Route Type';

  @override
  String get departure_indoor => 'Departure Indoor';

  @override
  String get to_building_exit => 'To building exit';

  @override
  String get outdoor_movement => 'Outdoor Movement';

  @override
  String get to_destination_building => 'To destination building';

  @override
  String get arrival_indoor => 'Arrival Indoor';

  @override
  String get to_final_destination => 'To final destination';

  @override
  String get building_to_building => 'Building to Building';

  @override
  String get room_to_building => 'Room→Building';

  @override
  String get building_to_room => 'Building→Room';

  @override
  String get room_to_room => 'Room to Room';

  @override
  String get location_to_building => 'Location→Building';

  @override
  String get unified_route => 'Unified Route';

  @override
  String preset_room_start(Object building, Object room) {
    return '$building Room $room set as departure';
  }

  @override
  String preset_room_end(Object building, Object room) {
    return '$building Room $room set as destination';
  }

  @override
  String preset_building_start(Object building) {
    return '$building set as departure';
  }

  @override
  String preset_building_end(Object building) {
    return '$building set as destination';
  }

  @override
  String floor_room(Object floor, Object room) {
    return 'Floor $floor Room $room';
  }

  @override
  String get available => 'Available';

  @override
  String get current_location => 'Current Location';

  @override
  String get start_navigation_from_here =>
      'Start navigation from current location';

  @override
  String get directions => 'Directions';

  @override
  String get navigateHere => 'Navigate Here';

  @override
  String get startLocation => 'Start';

  @override
  String get endLocation => 'Destination';

  @override
  String get floor_plans => 'Floor Plans';

  @override
  String get select_floor_to_view => 'Select each floor to view detailed plans';

  @override
  String get floor_info => 'Floor Information';

  @override
  String get view_floor_plan_button => 'View Floor Plan';

  @override
  String get no_detailed_info => 'No detailed information available.';

  @override
  String get pinch_to_zoom => 'Pinch to zoom, drag to move';

  @override
  String get floor_plan_loading_failed => 'Floor Plan Loading Failed';

  @override
  String loading_floor_plan(Object floor) {
    return 'Loading $floor floor plan…';
  }

  @override
  String server_info(Object building, Object floor) {
    return 'Server: $building/$floor';
  }

  @override
  String get building_name => 'Building';

  @override
  String get floor_number => 'Floor';

  @override
  String get room_name => 'Room';

  @override
  String get overlap_message => 'A class is already registered at this time.';

  @override
  String get memo => 'Memo';

  @override
  String get friendManagement => 'Friend Management';

  @override
  String get friendManagementAndRequests => 'Friend Management and Requests';

  @override
  String get showLocation => 'Show Location';

  @override
  String get removeLocation => 'Remove Location';

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get id => 'ID';

  @override
  String get contact => 'Contact';

  @override
  String get lastLocation => 'Last Location';

  @override
  String get noLocationInfo => 'No location info';

  @override
  String get noContactInfo => 'No info';

  @override
  String friendRequestSent(String name) {
    return 'Friend request sent to $name!';
  }

  @override
  String friendRequestAccepted(String name) {
    return 'Accepted friend request from $name.';
  }

  @override
  String friendRequestRejected(String name) {
    return 'Rejected friend request from $name.';
  }

  @override
  String friendRequestCanceled(String name) {
    return 'Canceled friend request to $name.';
  }

  @override
  String friendDeleted(String name) {
    return 'Removed $name from friends list.';
  }

  @override
  String friendLocationShown(String name) {
    return '$name\'s location is now shown on the map.';
  }

  @override
  String friendLocationRemoved(String name) {
    return '$name\'s location has been removed from the map.';
  }

  @override
  String friendCount(int count) {
    return 'My Friends ($count)';
  }

  @override
  String sentRequestsCount(int count) {
    return 'Sent ($count)';
  }

  @override
  String receivedRequestsCount(int count) {
    return 'Received ($count)';
  }

  @override
  String newFriendRequests(int count) {
    return '$count new friend requests';
  }

  @override
  String get addFriend => 'Add';

  @override
  String get sent => 'Sent';

  @override
  String get received => 'Received';

  @override
  String get sendFriendRequest => 'Send Friend Request';

  @override
  String get friendId => 'Friend ID';

  @override
  String get enterFriendId => 'Enter friend\'s ID';

  @override
  String get enterFriendIdPrompt =>
      'Please enter the ID of the friend you want to add';

  @override
  String get errorEnterFriendId => 'Please enter a friend ID.';

  @override
  String get errorCannotAddSelf => 'You cannot add yourself as a friend.';

  @override
  String get errorAddFriend => 'An error occurred while adding friend.';

  @override
  String get errorNetworkError => 'A network error occurred. Please try again.';

  @override
  String get errorCannotShowLocation => 'Cannot show friend\'s location.';

  @override
  String get errorCannotRemoveLocation => 'Cannot remove friend\'s location.';

  @override
  String get realTimeSyncActive =>
      'Real-time sync active • Updates automatically';

  @override
  String realTimeSyncStatus(String time) {
    return 'Real-time sync active • $time';
  }

  @override
  String get noSentRequests => 'No sent friend requests.';

  @override
  String get noReceivedRequests => 'No received friend requests.';

  @override
  String get noFriends =>
      'You don\'t have any friends yet.\nTap the + button above to add friends!';

  @override
  String get cancelFriendRequest => 'Cancel Friend Request';

  @override
  String cancelFriendRequestConfirm(String name) {
    return 'Are you sure you want to cancel the friend request to $name?';
  }

  @override
  String get deleteFriend => 'Delete Friend';

  @override
  String deleteFriendConfirm(String name) {
    return 'Are you sure you want to remove $name from your friends list?';
  }

  @override
  String get cancelRequest => 'Cancel';

  @override
  String requestDate(String date) {
    return 'Request date: $date';
  }

  @override
  String get newBadge => 'NEW';

  @override
  String get friend_delete_title => 'Delete Friend';

  @override
  String get friend_delete_warning => 'Please decide carefully';

  @override
  String friendDeleteQuestion(Object userName) {
    return 'Are you sure you want to remove $userName from your friends?\nRemoved friends can be added again.';
  }

  @override
  String get empty_friend_list_message => 'No friends found.';

  @override
  String get friendDeleteTitle => 'Delete Friend';

  @override
  String get friendDeleteWarning => 'Please decide carefully';

  @override
  String get friendDeleteHeader => 'Friend to Delete';

  @override
  String friendDeleteToConfirm(Object userName) {
    return 'Are you sure you want to remove $userName from your friend list?\nRemoved friends can be added again.';
  }

  @override
  String get friendDeleteCancel => 'Cancel';

  @override
  String get friendDeleteButton => 'Delete';

  @override
  String friendDeleteSuccessMessage(Object userName) {
    return '$userName has been removed from your friends list.';
  }
}
