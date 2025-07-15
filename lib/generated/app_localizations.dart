import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Campus Navigator'**
  String get appTitle;

  /// No description provided for @subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your smart campus guide'**
  String get subtitle;

  /// No description provided for @woosong.
  ///
  /// In en, this message translates to:
  /// **'Woosong'**
  String get woosong;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @student_professor.
  ///
  /// In en, this message translates to:
  /// **'Student/Professor'**
  String get student_professor;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get admin;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @professor.
  ///
  /// In en, this message translates to:
  /// **'Professor'**
  String get professor;

  /// No description provided for @external_user.
  ///
  /// In en, this message translates to:
  /// **'External'**
  String get external_user;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_password;

  /// No description provided for @remember_me.
  ///
  /// In en, this message translates to:
  /// **'Remember login info'**
  String get remember_me;

  /// No description provided for @remember_me_description.
  ///
  /// In en, this message translates to:
  /// **'You will be logged in automatically next time'**
  String get remember_me_description;

  /// No description provided for @login_as_guest.
  ///
  /// In en, this message translates to:
  /// **'Browse as Guest'**
  String get login_as_guest;

  /// No description provided for @login_failed.
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get login_failed;

  /// No description provided for @login_success.
  ///
  /// In en, this message translates to:
  /// **'Login Successful'**
  String get login_success;

  /// No description provided for @logout_success.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get logout_success;

  /// No description provided for @enter_username.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enter_username;

  /// No description provided for @enter_password.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enter_password;

  /// No description provided for @password_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6+ characters'**
  String get password_hint;

  /// No description provided for @confirm_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirm_password_hint;

  /// No description provided for @username_password_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter both username and password'**
  String get username_password_required;

  /// No description provided for @login_error.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get login_error;

  /// No description provided for @find_password.
  ///
  /// In en, this message translates to:
  /// **'Find Password'**
  String get find_password;

  /// No description provided for @find_username.
  ///
  /// In en, this message translates to:
  /// **'Find Username'**
  String get find_username;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get coming_soon;

  /// No description provided for @feature_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'{feature} feature is under development.\nIt will be added soon.'**
  String feature_coming_soon(String feature);

  /// No description provided for @start_campus_exploration.
  ///
  /// In en, this message translates to:
  /// **'Start exploring the campus'**
  String get start_campus_exploration;

  /// No description provided for @woosong_university.
  ///
  /// In en, this message translates to:
  /// **'Woosong University'**
  String get woosong_university;

  /// No description provided for @campus_navigator.
  ///
  /// In en, this message translates to:
  /// **'Campus Navigator'**
  String get campus_navigator;

  /// No description provided for @user_info_not_found.
  ///
  /// In en, this message translates to:
  /// **'User information not found in login response'**
  String get user_info_not_found;

  /// No description provided for @unexpected_login_error.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred during login'**
  String get unexpected_login_error;

  /// No description provided for @login_required.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get login_required;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @register_success.
  ///
  /// In en, this message translates to:
  /// **'Registration completed successfully'**
  String get register_success;

  /// No description provided for @register_success_message.
  ///
  /// In en, this message translates to:
  /// **'Registration completed!\nRedirecting to login screen.'**
  String get register_success_message;

  /// No description provided for @register_error.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred during registration'**
  String get register_error;

  /// No description provided for @update_user_info.
  ///
  /// In en, this message translates to:
  /// **'Update User Information'**
  String get update_user_info;

  /// No description provided for @update_success.
  ///
  /// In en, this message translates to:
  /// **'User information updated successfully'**
  String get update_success;

  /// No description provided for @update_error.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while updating user information'**
  String get update_error;

  /// No description provided for @delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get delete_account;

  /// No description provided for @delete_success.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get delete_success;

  /// No description provided for @delete_error.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while deleting account'**
  String get delete_error;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @student_number.
  ///
  /// In en, this message translates to:
  /// **'Student Number'**
  String get student_number;

  /// No description provided for @user_type.
  ///
  /// In en, this message translates to:
  /// **'User Type'**
  String get user_type;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @required_fields_empty.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get required_fields_empty;

  /// No description provided for @password_mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get password_mismatch;

  /// No description provided for @password_too_short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get password_too_short;

  /// No description provided for @invalid_phone_format.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number format (e.g., 010-1234-5678)'**
  String get invalid_phone_format;

  /// No description provided for @invalid_email_format.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email format'**
  String get invalid_email_format;

  /// No description provided for @required_fields_notice.
  ///
  /// In en, this message translates to:
  /// **'* marked fields are required'**
  String get required_fields_notice;

  /// No description provided for @welcome_to_campus_navigator.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Woosong Campus Navigator'**
  String get welcome_to_campus_navigator;

  /// No description provided for @enter_real_name.
  ///
  /// In en, this message translates to:
  /// **'Enter your real name'**
  String get enter_real_name;

  /// No description provided for @phone_format_hint.
  ///
  /// In en, this message translates to:
  /// **'010-1234-5678'**
  String get phone_format_hint;

  /// No description provided for @enter_student_number.
  ///
  /// In en, this message translates to:
  /// **'Enter your student or employee number'**
  String get enter_student_number;

  /// No description provided for @email_hint.
  ///
  /// In en, this message translates to:
  /// **'example@woosong.org'**
  String get email_hint;

  /// No description provided for @create_account.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @validation_error.
  ///
  /// In en, this message translates to:
  /// **'Please check your input'**
  String get validation_error;

  /// No description provided for @network_error.
  ///
  /// In en, this message translates to:
  /// **'Network error occurred'**
  String get network_error;

  /// No description provided for @server_error.
  ///
  /// In en, this message translates to:
  /// **'Server error occurred'**
  String get server_error;

  /// No description provided for @unknown_error.
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknown_error;

  /// No description provided for @select_auth_method.
  ///
  /// In en, this message translates to:
  /// **'Select Authentication Method'**
  String get select_auth_method;

  /// No description provided for @woosong_campus_guide_service.
  ///
  /// In en, this message translates to:
  /// **'Woosong University Campus Navigation Service'**
  String get woosong_campus_guide_service;

  /// No description provided for @register_description.
  ///
  /// In en, this message translates to:
  /// **'Create a new account to use all features'**
  String get register_description;

  /// No description provided for @login_description.
  ///
  /// In en, this message translates to:
  /// **'Log in with your existing account to use the service'**
  String get login_description;

  /// No description provided for @browse_as_guest.
  ///
  /// In en, this message translates to:
  /// **'Browse as Guest'**
  String get browse_as_guest;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @campus_navigator_version.
  ///
  /// In en, this message translates to:
  /// **'Campus Navigator v1.0'**
  String get campus_navigator_version;

  /// No description provided for @guest_mode.
  ///
  /// In en, this message translates to:
  /// **'Guest Mode'**
  String get guest_mode;

  /// No description provided for @guest_mode_description.
  ///
  /// In en, this message translates to:
  /// **'In guest mode, you can only view basic campus information.\nPlease register and log in to use all features.'**
  String get guest_mode_description;

  /// No description provided for @continue_as_guest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continue_as_guest;

  /// No description provided for @moved_to_my_location.
  ///
  /// In en, this message translates to:
  /// **'Automatically moved to my location'**
  String get moved_to_my_location;

  /// No description provided for @friends_screen_bottom_sheet.
  ///
  /// In en, this message translates to:
  /// **'Friends screen is displayed as bottom sheet'**
  String get friends_screen_bottom_sheet;

  /// No description provided for @finding_current_location.
  ///
  /// In en, this message translates to:
  /// **'Finding current location...'**
  String get finding_current_location;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @timetable.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get timetable;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @my_page.
  ///
  /// In en, this message translates to:
  /// **'MY'**
  String get my_page;

  /// No description provided for @cafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe'**
  String get cafe;

  /// No description provided for @restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @educational_facility.
  ///
  /// In en, this message translates to:
  /// **'Educational Facility'**
  String get educational_facility;

  /// No description provided for @estimated_distance.
  ///
  /// In en, this message translates to:
  /// **'Est. Distance'**
  String get estimated_distance;

  /// No description provided for @estimated_time.
  ///
  /// In en, this message translates to:
  /// **'Est. Time'**
  String get estimated_time;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @calculating_route.
  ///
  /// In en, this message translates to:
  /// **'Calculating route...'**
  String get calculating_route;

  /// No description provided for @finding_optimal_route.
  ///
  /// In en, this message translates to:
  /// **'Finding optimal route from server'**
  String get finding_optimal_route;

  /// No description provided for @departure.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get departure;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @clear_route.
  ///
  /// In en, this message translates to:
  /// **'Clear Route'**
  String get clear_route;

  /// No description provided for @location_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.\nPlease allow location permission in settings.'**
  String get location_permission_denied;

  /// No description provided for @finding_route_to_building.
  ///
  /// In en, this message translates to:
  /// **'Finding route to {building}...'**
  String finding_route_to_building(String building);

  /// No description provided for @route_displayed_to_building.
  ///
  /// In en, this message translates to:
  /// **'Route to {building} displayed'**
  String route_displayed_to_building(String building);

  /// No description provided for @set_as_departure.
  ///
  /// In en, this message translates to:
  /// **'Set {building} as departure.'**
  String set_as_departure(String building);

  /// No description provided for @set_as_destination.
  ///
  /// In en, this message translates to:
  /// **'Set {building} as destination.'**
  String set_as_destination(String building);

  /// No description provided for @woosong_library_w1.
  ///
  /// In en, this message translates to:
  /// **'Woosong Library (W1)'**
  String get woosong_library_w1;

  /// No description provided for @woosong_library_info.
  ///
  /// In en, this message translates to:
  /// **'B2F\tParking\nB1F\tSmall auditorium, Equipment room, Electrical room, Parking\n1F\tCareer Support Center (630-9976), Loan desk, Information lounge\n2F\tGeneral reading room, Group study room\n3F\tGeneral reading room\n4F\tLiterature books/Western books'**
  String get woosong_library_info;

  /// No description provided for @woosong_library_desc.
  ///
  /// In en, this message translates to:
  /// **'Woosong University Central Library'**
  String get woosong_library_desc;

  /// No description provided for @sol_cafe.
  ///
  /// In en, this message translates to:
  /// **'Sol Cafe'**
  String get sol_cafe;

  /// No description provided for @sol_cafe_info.
  ///
  /// In en, this message translates to:
  /// **'1F\tRestaurant\n2F\tCafe'**
  String get sol_cafe_info;

  /// No description provided for @sol_cafe_desc.
  ///
  /// In en, this message translates to:
  /// **'Campus cafe'**
  String get sol_cafe_desc;

  /// No description provided for @cheongun_1_dormitory.
  ///
  /// In en, this message translates to:
  /// **'Cheongun 1 Dormitory'**
  String get cheongun_1_dormitory;

  /// No description provided for @cheongun_1_dormitory_info.
  ///
  /// In en, this message translates to:
  /// **'1F\tPractice room\n2F\tStudent restaurant\n2F\tCheongun 1 Dormitory (Female) (629-6542)\n2F\tDormitory\n3~5F\tDormitory'**
  String get cheongun_1_dormitory_info;

  /// No description provided for @cheongun_1_dormitory_desc.
  ///
  /// In en, this message translates to:
  /// **'Female dormitory'**
  String get cheongun_1_dormitory_desc;

  /// No description provided for @industry_cooperation_w2.
  ///
  /// In en, this message translates to:
  /// **'Industry-University Cooperation (W2)'**
  String get industry_cooperation_w2;

  /// No description provided for @industry_cooperation_info.
  ///
  /// In en, this message translates to:
  /// **'1F\tIndustry-University Cooperation\n2F\tArchitectural Engineering (630-9720)\n3F\tWoosong University Convergence Technology Research Institute, Industry-Academia-Research General Enterprise Support Center\n4F\tCorporate Research Institute, LG CNS Classroom, Railway Digital Academy Classroom'**
  String get industry_cooperation_info;

  /// No description provided for @industry_cooperation_desc.
  ///
  /// In en, this message translates to:
  /// **'Industry-academia cooperation and research facilities'**
  String get industry_cooperation_desc;

  /// No description provided for @rotc_w2_1.
  ///
  /// In en, this message translates to:
  /// **'ROTC (W2-1)'**
  String get rotc_w2_1;

  /// No description provided for @rotc_info.
  ///
  /// In en, this message translates to:
  /// **'\tROTC (630-4601)'**
  String get rotc_info;

  /// No description provided for @rotc_desc.
  ///
  /// In en, this message translates to:
  /// **'ROTC facilities'**
  String get rotc_desc;

  /// No description provided for @international_dormitory_w3.
  ///
  /// In en, this message translates to:
  /// **'International Student Dormitory (W3)'**
  String get international_dormitory_w3;

  /// No description provided for @international_dormitory_info.
  ///
  /// In en, this message translates to:
  /// **'1F\tInternational Student Support Team (629-6623)\n1F\tStudent restaurant\n2F\tInternational Student Dormitory (629-6655)\n2F\tHealth center\n3~12F\tDormitory'**
  String get international_dormitory_info;

  /// No description provided for @international_dormitory_desc.
  ///
  /// In en, this message translates to:
  /// **'International student dormitory'**
  String get international_dormitory_desc;

  /// No description provided for @railway_logistics_w4.
  ///
  /// In en, this message translates to:
  /// **'Railway Logistics Building (W4)'**
  String get railway_logistics_w4;

  /// No description provided for @railway_logistics_info.
  ///
  /// In en, this message translates to:
  /// **'B1F\tPractice room\n1F\tPractice room\n2F\tRailway Construction System Department (629-6710)\n2F\tRailway Vehicle System Department (629-6780)\n3F\tClassroom/Practice room\n4F\tRailway System Department (630-6730,9700)\n5F\tFire and Disaster Prevention Department (629-6770)\n5F\tLogistics System Department (630-9330)'**
  String get railway_logistics_info;

  /// No description provided for @railway_logistics_desc.
  ///
  /// In en, this message translates to:
  /// **'Railway and logistics related departments'**
  String get railway_logistics_desc;

  /// No description provided for @health_medical_science_w5.
  ///
  /// In en, this message translates to:
  /// **'Health and Medical Science Building (W5)'**
  String get health_medical_science_w5;

  /// No description provided for @health_medical_science_info.
  ///
  /// In en, this message translates to:
  /// **'B1F\tParking\n1F\tAudiovisual room/Parking\n2F\tClassroom\n2F\tSports Health Rehabilitation Department (630-9840)\n3F\tEmergency Medical Services Department (630-9280)\n3F\tNursing Department (630-9290)\n4F\tOccupational Therapy Department (630-9820)\n4F\tSpeech Therapy and Audiology Department (630-9220)\n5F\tPhysical Therapy Department (630-4620)\n5F\tHealth and Medical Management Department (630-4610)\n5F\tClassroom\n6F\tRailway Management Department (630-9770)'**
  String get health_medical_science_info;

  /// No description provided for @health_medical_science_desc.
  ///
  /// In en, this message translates to:
  /// **'Health and medical related departments'**
  String get health_medical_science_desc;

  /// No description provided for @liberal_arts_w6.
  ///
  /// In en, this message translates to:
  /// **'Liberal Arts Building (W6)'**
  String get liberal_arts_w6;

  /// No description provided for @liberal_arts_info.
  ///
  /// In en, this message translates to:
  /// **'2F\tClassroom\n3F\tClassroom\n4F\tClassroom\n5F\tClassroom'**
  String get liberal_arts_info;

  /// No description provided for @liberal_arts_desc.
  ///
  /// In en, this message translates to:
  /// **'Liberal arts classrooms'**
  String get liberal_arts_desc;

  /// No description provided for @woosong_hall_w7.
  ///
  /// In en, this message translates to:
  /// **'Woosong Hall (W7)'**
  String get woosong_hall_w7;

  /// No description provided for @woosong_hall_info.
  ///
  /// In en, this message translates to:
  /// **'1F\tAdmissions Office (630-9627)\n1F\tAcademic Affairs Office (630-9622)\n1F\tFacilities Office (630-9970)\n1F\tManagement Team (629-6658)\n1F\tIndustry-University Cooperation (630-4653)\n1F\tExternal Cooperation Office (630-9636)\n2F\tStrategic Planning Office (630-9102)\n2F\tGeneral Affairs Office-General Affairs, Purchasing (630-9653)\n2F\tPlanning Office (630-9661)\n3F\tPresident\'s Office (630-8501)\n3F\tInternational Exchange Office (630-9373)\n3F\tEarly Childhood Education Department (630-9360)\n3F\tBusiness Administration Major (629-6640)\n3F\tFinance/Real Estate Major (630-9350)\n4F\tLarge conference room\n5F\tConference room'**
  String get woosong_hall_info;

  /// No description provided for @woosong_hall_desc.
  ///
  /// In en, this message translates to:
  /// **'University main building'**
  String get woosong_hall_desc;

  /// No description provided for @woosong_kindergarten_w8.
  ///
  /// In en, this message translates to:
  /// **'Woosong Kindergarten (W8)'**
  String get woosong_kindergarten_w8;

  /// No description provided for @woosong_kindergarten_info.
  ///
  /// In en, this message translates to:
  /// **'1F, 2F\tWoosong Kindergarten (629~6750~1)'**
  String get woosong_kindergarten_info;

  /// No description provided for @woosong_kindergarten_desc.
  ///
  /// In en, this message translates to:
  /// **'University affiliated kindergarten'**
  String get woosong_kindergarten_desc;

  /// No description provided for @west_campus_culinary_w9.
  ///
  /// In en, this message translates to:
  /// **'West Campus Culinary Institute (W9)'**
  String get west_campus_culinary_w9;

  /// No description provided for @west_campus_culinary_info.
  ///
  /// In en, this message translates to:
  /// **'B1F\tPractice room\n1F\tPractice room\n2F\tPractice room'**
  String get west_campus_culinary_info;

  /// No description provided for @west_campus_culinary_desc.
  ///
  /// In en, this message translates to:
  /// **'Culinary practice facilities'**
  String get west_campus_culinary_desc;

  /// No description provided for @social_welfare_w10.
  ///
  /// In en, this message translates to:
  /// **'Social Welfare Convergence Building (W10)'**
  String get social_welfare_w10;

  /// No description provided for @social_welfare_info.
  ///
  /// In en, this message translates to:
  /// **'1F\tAudiovisual room/Practice room\n2F\tClassroom/Practice room\n3F\tSocial Welfare Department (630-9830)\n3F\tGlobal Child Education Department (630-9260)\n4F\tClassroom/Practice room\n5F\tClassroom/Practice room'**
  String get social_welfare_info;

  /// No description provided for @social_welfare_desc.
  ///
  /// In en, this message translates to:
  /// **'Social welfare related departments'**
  String get social_welfare_desc;

  /// No description provided for @gymnasium_w11.
  ///
  /// In en, this message translates to:
  /// **'Gymnasium (W11)'**
  String get gymnasium_w11;

  /// No description provided for @gymnasium_info.
  ///
  /// In en, this message translates to:
  /// **'1F\tFitness center\n2F~4F\tGymnasium'**
  String get gymnasium_info;

  /// No description provided for @gymnasium_desc.
  ///
  /// In en, this message translates to:
  /// **'Sports facilities'**
  String get gymnasium_desc;

  /// No description provided for @sica_w12.
  ///
  /// In en, this message translates to:
  /// **'SICA (W12)'**
  String get sica_w12;

  /// No description provided for @sica_info.
  ///
  /// In en, this message translates to:
  /// **'B1F\tPractice room\n1F\tStarrico Cafe\n2F~3F\tClassroom\n5F\tGlobal Culinary Department (629-6860)'**
  String get sica_info;

  /// No description provided for @sica_desc.
  ///
  /// In en, this message translates to:
  /// **'International Culinary Institute'**
  String get sica_desc;

  /// No description provided for @woosong_tower_w13.
  ///
  /// In en, this message translates to:
  /// **'Woosong Tower (W13)'**
  String get woosong_tower_w13;

  /// No description provided for @woosong_tower_info.
  ///
  /// In en, this message translates to:
  /// **'B1~1F\tParking\n2F\tParking, Solpine Bakery (629-6429)\n4F\tSeminar room\n5F\tClassroom\n6F\tFood Service Culinary Nutrition Department (630-9380,9740)\n7F\tClassroom\n8F\tFood Service, Culinary Management Major (630-9250)\n9F\tClassroom/Practice room\n10F\tFood Service Culinary Major (629-6821), Global Korean Culinary Major (629-6560)\n11F, 12F\tPractice room\n13F\tSolpine Restaurant (629-6610)'**
  String get woosong_tower_info;

  /// No description provided for @woosong_tower_desc.
  ///
  /// In en, this message translates to:
  /// **'Complex educational facility'**
  String get woosong_tower_desc;

  /// No description provided for @culinary_center_w14.
  ///
  /// In en, this message translates to:
  /// **'Culinary Center (W14)'**
  String get culinary_center_w14;

  /// No description provided for @culinary_center_info.
  ///
  /// In en, this message translates to:
  /// **'1F\tClassroom/Practice room\n2F\tClassroom/Practice room\n3F\tClassroom/Practice room\n4F\tClassroom/Practice room\n5F\tClassroom/Practice room'**
  String get culinary_center_info;

  /// No description provided for @culinary_center_desc.
  ///
  /// In en, this message translates to:
  /// **'Culinary specialized educational facility'**
  String get culinary_center_desc;

  /// No description provided for @food_architecture_w15.
  ///
  /// In en, this message translates to:
  /// **'Food Architecture Building (W15)'**
  String get food_architecture_w15;

  /// No description provided for @food_architecture_info.
  ///
  /// In en, this message translates to:
  /// **'B1F\tPractice room\n1F\tPractice room\n2F\tClassroom\n3F\tClassroom\n4F\tClassroom\n5F\tClassroom'**
  String get food_architecture_info;

  /// No description provided for @food_architecture_desc.
  ///
  /// In en, this message translates to:
  /// **'Food and architecture related departments'**
  String get food_architecture_desc;

  /// No description provided for @student_hall_w16.
  ///
  /// In en, this message translates to:
  /// **'Student Hall (W16)'**
  String get student_hall_w16;

  /// No description provided for @student_hall_info.
  ///
  /// In en, this message translates to:
  /// **'1F\tStudent restaurant, Campus bookstore (629-6127)\n2F\tFaculty restaurant\n3F\tClub rooms\n3F\tStudent Welfare Office-Student Team (630-9641), Scholarship Team (630-9876)\n3F\tDisabled Student Support Center (630-9903)\n3F\tSocial Service Corps (630-9904)\n3F\tStudent Counseling Center (630-9645)\n4F\tReturn to School Support Center (630-9139)\n4F\tCenter for Teaching and Learning Development (630-9285)'**
  String get student_hall_info;

  /// No description provided for @student_hall_desc.
  ///
  /// In en, this message translates to:
  /// **'Student welfare facilities'**
  String get student_hall_desc;

  /// No description provided for @media_convergence_w17.
  ///
  /// In en, this message translates to:
  /// **'Media Convergence Building (W17)'**
  String get media_convergence_w17;

  /// No description provided for @media_convergence_info.
  ///
  /// In en, this message translates to:
  /// **'B1F\tClassroom/Practice room\n1F\tMedia Design/Video Major (630-9750)\n2F\tClassroom/Practice room\n3F\tGame Multimedia Major (630-9270)\n5F\tClassroom/Practice room'**
  String get media_convergence_info;

  /// No description provided for @media_convergence_desc.
  ///
  /// In en, this message translates to:
  /// **'Media related departments'**
  String get media_convergence_desc;

  /// No description provided for @woosong_arts_center_w18.
  ///
  /// In en, this message translates to:
  /// **'Woosong Arts Center (W18)'**
  String get woosong_arts_center_w18;

  /// No description provided for @woosong_arts_center_info.
  ///
  /// In en, this message translates to:
  /// **'B1F\tPerformance preparation room\n1F\tWoosong Arts Center (629-6363)\n2F\tPractice room\n3F\tPractice room\n4F\tPractice room\n5F\tPractice room'**
  String get woosong_arts_center_info;

  /// No description provided for @woosong_arts_center_desc.
  ///
  /// In en, this message translates to:
  /// **'Arts performance facility'**
  String get woosong_arts_center_desc;

  /// No description provided for @west_campus_andycut_w19.
  ///
  /// In en, this message translates to:
  /// **'West Campus AndyCut Building (W19)'**
  String get west_campus_andycut_w19;

  /// No description provided for @west_campus_andycut_info.
  ///
  /// In en, this message translates to:
  /// **'2F\tGlobal Convergence Business Department (630-9249)\n2F\tLiberal Arts Department (630-9390)\n2F\tAI/Big Data Department (630-9807)\n2F\tGlobal Hotel Management Department (630-9249)\n2F\tGlobal Media Video Department (630-9346)\n2F\tGlobal Medical Service Management Department (630-9283)\n2F\tGlobal Railway/Transportation Logistics Department (630-9347)\n2F\tGlobal Food Service Entrepreneurship Department (629-6860)'**
  String get west_campus_andycut_info;

  /// No description provided for @west_campus_andycut_desc.
  ///
  /// In en, this message translates to:
  /// **'Global departments building'**
  String get west_campus_andycut_desc;

  /// No description provided for @operating.
  ///
  /// In en, this message translates to:
  /// **'Operating'**
  String get operating;

  /// No description provided for @dormitory.
  ///
  /// In en, this message translates to:
  /// **'Dormitory'**
  String get dormitory;

  /// No description provided for @military_facility.
  ///
  /// In en, this message translates to:
  /// **'Military Facility'**
  String get military_facility;

  /// No description provided for @kindergarten.
  ///
  /// In en, this message translates to:
  /// **'Kindergarten'**
  String get kindergarten;

  /// No description provided for @sports_facility.
  ///
  /// In en, this message translates to:
  /// **'Sports Facility'**
  String get sports_facility;

  /// No description provided for @complex_facility.
  ///
  /// In en, this message translates to:
  /// **'Complex Facility'**
  String get complex_facility;

  /// No description provided for @search_campus_buildings.
  ///
  /// In en, this message translates to:
  /// **'Search campus buildings'**
  String get search_campus_buildings;

  /// No description provided for @no_search_results.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get no_search_results;

  /// No description provided for @building_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get building_details;

  /// No description provided for @parking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get parking;

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @facilities.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get facilities;

  /// No description provided for @elevator.
  ///
  /// In en, this message translates to:
  /// **'Elevator'**
  String get elevator;

  /// No description provided for @restroom.
  ///
  /// In en, this message translates to:
  /// **'Restroom'**
  String get restroom;

  /// No description provided for @navigate_from_current_location.
  ///
  /// In en, this message translates to:
  /// **'Navigate from current location'**
  String get navigate_from_current_location;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get title;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get nameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile has been updated.'**
  String get saveSuccess;

  /// No description provided for @my_info.
  ///
  /// In en, this message translates to:
  /// **'My Info'**
  String get my_info;

  /// No description provided for @guest_user.
  ///
  /// In en, this message translates to:
  /// **'Yejilebae Crew'**
  String get guest_user;

  /// No description provided for @guest_role.
  ///
  /// In en, this message translates to:
  /// **'Slave of JinYoung Jung'**
  String get guest_role;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @edit_profile_subtitle.
  ///
  /// In en, this message translates to:
  /// **'You can modify your personal information'**
  String get edit_profile_subtitle;

  /// No description provided for @help_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Check how to use the app'**
  String get help_subtitle;

  /// No description provided for @app_info_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Version info and developer info'**
  String get app_info_subtitle;

  /// No description provided for @delete_account_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get delete_account_subtitle;

  /// No description provided for @login_message.
  ///
  /// In en, this message translates to:
  /// **'Please login or sign up\nto use all features'**
  String get login_message;

  /// No description provided for @login_signup.
  ///
  /// In en, this message translates to:
  /// **'Login / Sign Up'**
  String get login_signup;

  /// No description provided for @delete_account_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get delete_account_confirm;

  /// No description provided for @delete_account_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get delete_account_message;

  /// No description provided for @logout_confirm.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout_confirm;

  /// No description provided for @logout_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logout_message;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @feature_in_progress.
  ///
  /// In en, this message translates to:
  /// **'feature is under development.'**
  String get feature_in_progress;

  /// No description provided for @delete_feature_in_progress.
  ///
  /// In en, this message translates to:
  /// **'Account deletion feature is under development.'**
  String get delete_feature_in_progress;

  /// No description provided for @app_info.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get app_info;

  /// No description provided for @app_version.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get app_version;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @developer_name.
  ///
  /// In en, this message translates to:
  /// **'Name: Hong Gil-dong'**
  String get developer_name;

  /// No description provided for @developer_email.
  ///
  /// In en, this message translates to:
  /// **'Email: example@email.com'**
  String get developer_email;

  /// No description provided for @developer_github.
  ///
  /// In en, this message translates to:
  /// **'GitHub: github.com/yourid'**
  String get developer_github;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @no_help_images.
  ///
  /// In en, this message translates to:
  /// **'No help images available'**
  String get no_help_images;

  /// No description provided for @image_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load image'**
  String get image_load_error;

  /// No description provided for @description_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get description_hint;

  /// No description provided for @email_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get email_required;

  /// No description provided for @name_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get name_required;

  /// No description provided for @profile_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile has been updated'**
  String get profile_updated;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @winter_semester.
  ///
  /// In en, this message translates to:
  /// **'Winter'**
  String get winter_semester;

  /// No description provided for @spring_semester.
  ///
  /// In en, this message translates to:
  /// **'Spring'**
  String get spring_semester;

  /// No description provided for @summer_semester.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get summer_semester;

  /// No description provided for @fall_semester.
  ///
  /// In en, this message translates to:
  /// **'Fall'**
  String get fall_semester;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get friday;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @add_class.
  ///
  /// In en, this message translates to:
  /// **'Add Class'**
  String get add_class;

  /// No description provided for @edit_class.
  ///
  /// In en, this message translates to:
  /// **'Edit Class'**
  String get edit_class;

  /// No description provided for @delete_class.
  ///
  /// In en, this message translates to:
  /// **'Delete Class'**
  String get delete_class;

  /// No description provided for @class_name.
  ///
  /// In en, this message translates to:
  /// **'Class Name'**
  String get class_name;

  /// No description provided for @professor_name.
  ///
  /// In en, this message translates to:
  /// **'Professor'**
  String get professor_name;

  /// No description provided for @classroom.
  ///
  /// In en, this message translates to:
  /// **'Classroom'**
  String get classroom;

  /// No description provided for @day_of_week.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day_of_week;

  /// No description provided for @start_time.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get start_time;

  /// No description provided for @end_time.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get end_time;

  /// No description provided for @color_selection.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get color_selection;

  /// No description provided for @monday_full.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday_full;

  /// No description provided for @tuesday_full.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday_full;

  /// No description provided for @wednesday_full.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday_full;

  /// No description provided for @thursday_full.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday_full;

  /// No description provided for @friday_full.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday_full;

  /// No description provided for @class_added.
  ///
  /// In en, this message translates to:
  /// **'Class has been added.'**
  String get class_added;

  /// No description provided for @class_updated.
  ///
  /// In en, this message translates to:
  /// **'Class has been updated.'**
  String get class_updated;

  /// No description provided for @class_deleted.
  ///
  /// In en, this message translates to:
  /// **'Class has been deleted.'**
  String get class_deleted;

  /// No description provided for @delete_class_confirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete {className}?'**
  String delete_class_confirm(String className);

  /// No description provided for @view_on_map.
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get view_on_map;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @schedule_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get schedule_time;

  /// No description provided for @schedule_day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get schedule_day;

  /// No description provided for @map_feature_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Map feature will be added later.'**
  String get map_feature_coming_soon;

  /// No description provided for @current_year.
  ///
  /// In en, this message translates to:
  /// **'{year}'**
  String current_year(int year);

  /// No description provided for @my_friends.
  ///
  /// In en, this message translates to:
  /// **'My Friends'**
  String get my_friends;

  /// No description provided for @online_friends.
  ///
  /// In en, this message translates to:
  /// **'Total {total} • Online {online}'**
  String online_friends(int total, int online);

  /// No description provided for @add_friend.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get add_friend;

  /// No description provided for @friend_name_or_id.
  ///
  /// In en, this message translates to:
  /// **'Enter friend\'s name or student ID'**
  String get friend_name_or_id;

  /// No description provided for @friend_request_sent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent.'**
  String get friend_request_sent;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @in_class.
  ///
  /// In en, this message translates to:
  /// **'In Class'**
  String get in_class;

  /// No description provided for @last_location.
  ///
  /// In en, this message translates to:
  /// **'Last location: {location}'**
  String last_location(String location);

  /// No description provided for @central_library.
  ///
  /// In en, this message translates to:
  /// **'Central Library'**
  String get central_library;

  /// No description provided for @engineering_building.
  ///
  /// In en, this message translates to:
  /// **'Engineering Building 201'**
  String get engineering_building;

  /// No description provided for @student_center.
  ///
  /// In en, this message translates to:
  /// **'Student Center'**
  String get student_center;

  /// No description provided for @cafeteria.
  ///
  /// In en, this message translates to:
  /// **'Cafeteria'**
  String get cafeteria;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @view_location.
  ///
  /// In en, this message translates to:
  /// **'View Location'**
  String get view_location;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @start_chat_with.
  ///
  /// In en, this message translates to:
  /// **'Starting chat with {name}.'**
  String start_chat_with(String name);

  /// No description provided for @view_location_on_map.
  ///
  /// In en, this message translates to:
  /// **'View {name}\'s location on map.'**
  String view_location_on_map(String name);

  /// No description provided for @calling.
  ///
  /// In en, this message translates to:
  /// **'Calling {name}.'**
  String calling(String name);

  /// Add button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Search button text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Search buildings placeholder
  ///
  /// In en, this message translates to:
  /// **'Search buildings...'**
  String get searchBuildings;

  /// My location button text
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get myLocation;

  /// Navigation text
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// Route text
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// Distance text
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// Minutes unit
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// Meters unit
  ///
  /// In en, this message translates to:
  /// **'meters'**
  String get meters;

  /// Find route button text
  ///
  /// In en, this message translates to:
  /// **'Find Route'**
  String get findRoute;

  /// Clear route button text
  ///
  /// In en, this message translates to:
  /// **'Clear Route'**
  String get clearRoute;

  /// Set as start point button
  ///
  /// In en, this message translates to:
  /// **'Set as Start'**
  String get setAsStart;

  /// Set as destination button
  ///
  /// In en, this message translates to:
  /// **'Set as Destination'**
  String get setAsDestination;

  /// Navigate from current location button
  ///
  /// In en, this message translates to:
  /// **'Navigate from Here'**
  String get navigateFromHere;

  /// Building information title
  ///
  /// In en, this message translates to:
  /// **'Building Information'**
  String get buildingInfo;

  /// Category text
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Location permission required message
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get locationPermissionRequired;

  /// Enable location services message
  ///
  /// In en, this message translates to:
  /// **'Please enable location services'**
  String get enableLocationServices;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No search results message
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// Settings text
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// About text
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Friends count and online status
  ///
  /// In en, this message translates to:
  /// **'Total {total} • Online {online}'**
  String friends_count_status(int total, int online);

  /// Add friend input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter friend\'s name or student ID'**
  String get enter_friend_info;

  /// Show location message
  ///
  /// In en, this message translates to:
  /// **'Showing {name}\'s location on map.'**
  String show_location_on_map(String name);

  /// No description provided for @open_settings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get open_settings;

  /// No description provided for @location_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to find your location.'**
  String get location_error;

  /// No description provided for @view_floor_plan.
  ///
  /// In en, this message translates to:
  /// **'View Floor Plan'**
  String get view_floor_plan;

  /// No description provided for @floor_plan.
  ///
  /// In en, this message translates to:
  /// **'Floor Plan'**
  String get floor_plan;

  /// No description provided for @floor_plan_title.
  ///
  /// In en, this message translates to:
  /// **'{buildingName} Floor Plan'**
  String floor_plan_title(String buildingName);

  /// No description provided for @floor_plan_not_available.
  ///
  /// In en, this message translates to:
  /// **'Unable to load floor plan image'**
  String get floor_plan_not_available;

  /// No description provided for @floor_plan_default_text.
  ///
  /// In en, this message translates to:
  /// **'Floor Plan'**
  String get floor_plan_default_text;

  /// No description provided for @delete_account_success.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get delete_account_success;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
