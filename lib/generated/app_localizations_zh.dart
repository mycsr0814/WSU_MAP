// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Campus Navigator';

  @override
  String get subtitle => '智能校园指南';

  @override
  String get woosong => '又松';

  @override
  String get start => '开始';

  @override
  String get login => '登录';

  @override
  String get logout => '注销';

  @override
  String get guest => '访客';

  @override
  String get student_professor => '学生/教授';

  @override
  String get admin => '管理员';

  @override
  String get student => '学生';

  @override
  String get professor => '教授';

  @override
  String get external_user => '外部用户';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get confirm_password => '确认密码';

  @override
  String get remember_me => '记住登录信息';

  @override
  String get remember_me_description => '下次将自动登录';

  @override
  String get login_as_guest => '以访客身份浏览';

  @override
  String get login_failed => '登录失败';

  @override
  String get login_success => '登录成功';

  @override
  String get logout_success => '已成功注销';

  @override
  String get enter_username => '请输入用户名';

  @override
  String get enter_password => '请输入密码';

  @override
  String get password_hint => '请输入6位以上字符';

  @override
  String get confirm_password_hint => '请再次输入密码';

  @override
  String get username_password_required => '请输入用户名和密码';

  @override
  String get login_error => '登录失败';

  @override
  String get find_password => '找回密码';

  @override
  String get find_username => '找回用户名';

  @override
  String get back => '返回';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String get coming_soon => '即将推出';

  @override
  String feature_coming_soon(String feature) {
    return '$feature 功能正在开发中。\n将很快添加。';
  }

  @override
  String get start_campus_exploration => '开始探索校园';

  @override
  String get woosong_university => '又松大学';

  @override
  String get campus_navigator => '校园导航';

  @override
  String get user_info_not_found => '登录响应中未找到用户信息';

  @override
  String get unexpected_login_error => '登录过程中发生意外错误';

  @override
  String get login_required => '需要登录';

  @override
  String get register => '注册';

  @override
  String get register_success => '注册成功完成';

  @override
  String get register_success_message => '注册完成！\n正在跳转到登录页面。';

  @override
  String get register_error => '注册过程中发生意外错误';

  @override
  String get update_user_info => '更新用户信息';

  @override
  String get update_success => '用户信息更新成功';

  @override
  String get update_error => '更新用户信息时发生意外错误';

  @override
  String get delete_account => '删除账户';

  @override
  String get delete_success => '账户删除成功';

  @override
  String get delete_error => '删除账户时发生意外错误';

  @override
  String get name => '姓名';

  @override
  String get phone => '电话号码';

  @override
  String get email => '邮箱';

  @override
  String get student_number => '学号';

  @override
  String get user_type => '用户类型';

  @override
  String get optional => '可选';

  @override
  String get required_fields_empty => '请填写所有必填项';

  @override
  String get password_mismatch => '密码不匹配';

  @override
  String get password_too_short => '密码必须至少6个字符';

  @override
  String get invalid_phone_format => '请输入有效的电话号码格式 (例如: 010-1234-5678)';

  @override
  String get invalid_email_format => '请输入有效的邮箱格式';

  @override
  String get required_fields_notice => '* 标记的项目为必填项';

  @override
  String get welcome_to_campus_navigator => '欢迎使用又松大学校园导航';

  @override
  String get enter_real_name => '请输入真实姓名';

  @override
  String get phone_format_hint => '010-1234-5678';

  @override
  String get enter_student_number => '请输入学号或工号';

  @override
  String get email_hint => 'example@woosong.org';

  @override
  String get create_account => '创建账户';

  @override
  String get loading => '加载中...';

  @override
  String get error => '错误';

  @override
  String get success => '成功';

  @override
  String get validation_error => '请检查您的输入';

  @override
  String get network_error => '发生网络错误';

  @override
  String get server_error => '发生服务器错误';

  @override
  String get unknown_error => '发生未知错误';

  @override
  String get select_auth_method => '选择认证方式';

  @override
  String get woosong_campus_guide_service => '又松大学校园导航服务';

  @override
  String get register_description => '创建新账户以使用所有功能';

  @override
  String get login_description => '使用现有账户登录以使用服务';

  @override
  String get browse_as_guest => '以访客身份浏览';

  @override
  String get processing => '处理中...';

  @override
  String get campus_navigator_version => 'Campus Navigator v1.0';

  @override
  String get guest_mode => '访客模式';

  @override
  String get guest_mode_description => '在访客模式下，您只能查看基本的校园信息。\n请注册并登录以使用所有功能。';

  @override
  String get continue_as_guest => '继续作为访客';

  @override
  String get moved_to_my_location => '已自动移动到我的位置';

  @override
  String get friends_screen_bottom_sheet => '朋友界面显示为底部表单';

  @override
  String get finding_current_location => '正在查找当前位置...';

  @override
  String get home => '主页';

  @override
  String get timetable => '时间表';

  @override
  String get friends => '朋友';

  @override
  String get my_page => '我的';

  @override
  String get cafe => '咖啡厅';

  @override
  String get restaurant => '餐厅';

  @override
  String get library => '图书馆';

  @override
  String get educational_facility => '教育设施';

  @override
  String get estimated_distance => '预计距离';

  @override
  String get estimated_time => '预计时间';

  @override
  String get calculating => '计算中...';

  @override
  String get calculating_route => '正在计算路线...';

  @override
  String get finding_optimal_route => '服务器正在寻找最佳路线';

  @override
  String get departure => '出发地';

  @override
  String get destination => '目的地';

  @override
  String get clear_route => '清除路线';

  @override
  String get location_permission_denied => '位置权限被拒绝。\n请在设置中允许位置权限。';

  @override
  String finding_route_to_building(String building) {
    return '正在查找到$building的路线...';
  }

  @override
  String route_displayed_to_building(String building) {
    return '已显示到$building的路线';
  }

  @override
  String set_as_departure(String building) {
    return '已将$building设为出发地。';
  }

  @override
  String set_as_destination(String building) {
    return '已将$building设为目的地。';
  }

  @override
  String get woosong_library_w1 => '又松图书馆 (W1)';

  @override
  String get woosong_library_info =>
      'B2F\t停车场\nB1F\t小礼堂、设备室、电气室、停车场\n1F\t就业支持中心 (630-9976)、借阅台、信息休息室\n2F\t普通阅览室、团体学习室\n3F\t普通阅览室\n4F\t文学图书/西方图书';

  @override
  String get woosong_library_desc => '又松大学中央图书馆';

  @override
  String get sol_cafe => 'Sol咖啡厅';

  @override
  String get sol_cafe_info => '1F\t餐厅\n2F\t咖啡厅';

  @override
  String get sol_cafe_desc => '校园内咖啡厅';

  @override
  String get cheongun_1_dormitory => '青云1宿舍';

  @override
  String get cheongun_1_dormitory_info =>
      '1F\t实习室\n2F\t学生餐厅\n2F\t青云1宿舍(女) (629-6542)\n2F\t生活馆\n3~5F\t生活馆';

  @override
  String get cheongun_1_dormitory_desc => '女学生宿舍';

  @override
  String get industry_cooperation_w2 => '产学合作团 (W2)';

  @override
  String get industry_cooperation_info =>
      '1F\t产学合作团\n2F\t建筑工程专业 (630-9720)\n3F\t又松大学融合技术研究所、产学研综合企业支持中心\n4F\t企业附设研究所、LG CNS教室、铁道数字学院教室';

  @override
  String get industry_cooperation_desc => '产学合作及研究设施';

  @override
  String get rotc_w2_1 => '学军团 (W2-1)';

  @override
  String get rotc_info => '\t学军团 (630-4601)';

  @override
  String get rotc_desc => '学军团设施';

  @override
  String get international_dormitory_w3 => '留学生宿舍 (W3)';

  @override
  String get international_dormitory_info =>
      '1F\t留学生支持团队 (629-6623)\n1F\t学生餐厅\n2F\t留学生宿舍 (629-6655)\n2F\t保健室\n3~12F\t生活馆';

  @override
  String get international_dormitory_desc => '留学生专用宿舍';

  @override
  String get railway_logistics_w4 => '铁道物流馆 (W4)';

  @override
  String get railway_logistics_info =>
      'B1F\t实习室\n1F\t实习室\n2F\t铁道建设系统学部 (629-6710)\n2F\t铁道车辆系统学科 (629-6780)\n3F\t教室/实习室\n4F\t铁道系统学部 (630-6730,9700)\n5F\t消防防灾学科 (629-6770)\n5F\t物流系统学科 (630-9330)';

  @override
  String get railway_logistics_desc => '铁道及物流相关学科';

  @override
  String get health_medical_science_w5 => '保健医疗科学馆 (W5)';

  @override
  String get health_medical_science_info =>
      'B1F\t停车场\n1F\t视听室/停车场\n2F\t教室\n2F\t运动健康康复学科 (630-9840)\n3F\t急救学科 (630-9280)\n3F\t护理学科 (630-9290)\n4F\t作业治疗学科 (630-9820)\n4F\t语言治疗听觉康复学科 (630-9220)\n5F\t物理治疗学科 (630-4620)\n5F\t保健医疗经营学科 (630-4610)\n5F\t教室\n6F\t铁道经营学科 (630-9770)';

  @override
  String get health_medical_science_desc => '保健医疗相关学科';

  @override
  String get liberal_arts_w6 => '教养教育馆 (W6)';

  @override
  String get liberal_arts_info => '2F\t教室\n3F\t教室\n4F\t教室\n5F\t教室';

  @override
  String get liberal_arts_desc => '教养教室';

  @override
  String get woosong_hall_w7 => '又松馆 (W7)';

  @override
  String get woosong_hall_info =>
      '1F\t入学处 (630-9627)\n1F\t教务处 (630-9622)\n1F\t设施处 (630-9970)\n1F\t管理团队 (629-6658)\n1F\t产学合作团 (630-4653)\n1F\t对外合作处 (630-9636)\n2F\t战略企划处 (630-9102)\n2F\t总务处-总务、采购 (630-9653)\n2F\t企划处 (630-9661)\n3F\t校长室 (630-8501)\n3F\t国际交流处 (630-9373)\n3F\t幼儿教育科 (630-9360)\n3F\t经营学专业 (629-6640)\n3F\t金融/房地产学专业 (630-9350)\n4F\t大会议室\n5F\t会议室';

  @override
  String get woosong_hall_desc => '大学本部建筑';

  @override
  String get woosong_kindergarten_w8 => '又松幼儿园 (W8)';

  @override
  String get woosong_kindergarten_info => '1F, 2F\t又松幼儿园 (629~6750~1)';

  @override
  String get woosong_kindergarten_desc => '大学附属幼儿园';

  @override
  String get west_campus_culinary_w9 => '西校区烹饪学院 (W9)';

  @override
  String get west_campus_culinary_info => 'B1F\t实习室\n1F\t实习室\n2F\t实习室';

  @override
  String get west_campus_culinary_desc => '烹饪实习设施';

  @override
  String get social_welfare_w10 => '社会福利融合馆 (W10)';

  @override
  String get social_welfare_info =>
      '1F\t视听室/实习室\n2F\t教室/实习室\n3F\t社会福利学科 (630-9830)\n3F\t全球儿童教育学科 (630-9260)\n4F\t教室/实习室\n5F\t教室/实习室';

  @override
  String get social_welfare_desc => '社会福利相关学科';

  @override
  String get gymnasium_w11 => '体育馆 (W11)';

  @override
  String get gymnasium_info => '1F\t体力锻炼室\n2F~4F\t体育馆';

  @override
  String get gymnasium_desc => '体育设施';

  @override
  String get sica_w12 => 'SICA (W12)';

  @override
  String get sica_info =>
      'B1F\t实习室\n1F\tStarrico咖啡厅\n2F~3F\t教室\n5F\t全球烹饪学部 (629-6860)';

  @override
  String get sica_desc => '国际烹饪学院';

  @override
  String get woosong_tower_w13 => '又松塔 (W13)';

  @override
  String get woosong_tower_info =>
      'B1~1F\t停车场\n2F\t停车场、Solpine面包店 (629-6429)\n4F\t研讨室\n5F\t教室\n6F\t餐饮烹饪营养学科 (630-9380,9740)\n7F\t教室\n8F\t餐饮、烹饪经营专业 (630-9250)\n9F\t教室/实习室\n10F\t餐饮烹饪专业 (629-6821)、全球韩式烹饪专业 (629-6560)\n11F, 12F\t实习室\n13F\tSolpine餐厅 (629-6610)';

  @override
  String get woosong_tower_desc => '综合教育设施';

  @override
  String get culinary_center_w14 => '烹饪中心 (W14)';

  @override
  String get culinary_center_info =>
      '1F\t教室/实习室\n2F\t教室/实习室\n3F\t教室/实习室\n4F\t教室/实习室\n5F\t教室/实习室';

  @override
  String get culinary_center_desc => '烹饪专业教育设施';

  @override
  String get food_architecture_w15 => '食品建筑馆 (W15)';

  @override
  String get food_architecture_info =>
      'B1F\t实习室\n1F\t实习室\n2F\t教室\n3F\t教室\n4F\t教室\n5F\t教室';

  @override
  String get food_architecture_desc => '食品及建筑相关学科';

  @override
  String get student_hall_w16 => '学生会馆 (W16)';

  @override
  String get student_hall_info =>
      '1F\t学生餐厅、校内书店 (629-6127)\n2F\t教职员餐厅\n3F\t社团房\n3F\t学生福利处-学生团队 (630-9641)、奖学金团队 (630-9876)\n3F\t残疾学生支持中心 (630-9903)\n3F\t社会服务团 (630-9904)\n3F\t学生咨询中心 (630-9645)\n4F\t复学支持中心 (630-9139)\n4F\t教授学习开发中心 (630-9285)';

  @override
  String get student_hall_desc => '学生福利设施';

  @override
  String get media_convergence_w17 => '媒体融合馆 (W17)';

  @override
  String get media_convergence_info =>
      'B1F\t教室/实习室\n1F\t媒体设计/影像专业 (630-9750)\n2F\t教室/实习室\n3F\t游戏多媒体专业 (630-9270)\n5F\t教室/实习室';

  @override
  String get media_convergence_desc => '媒体相关学科';

  @override
  String get woosong_arts_center_w18 => '又松艺术会馆 (W18)';

  @override
  String get woosong_arts_center_info =>
      'B1F\t演出准备室\n1F\t又松艺术会馆 (629-6363)\n2F\t实习室\n3F\t实习室\n4F\t实习室\n5F\t实习室';

  @override
  String get woosong_arts_center_desc => '艺术演出设施';

  @override
  String get west_campus_andycut_w19 => '西校区AndyCut建筑 (W19)';

  @override
  String get west_campus_andycut_info =>
      '2F\t全球融合商务学科 (630-9249)\n2F\t自由专业学部 (630-9390)\n2F\tAI/大数据学科 (630-9807)\n2F\t全球酒店管理学科 (630-9249)\n2F\t全球媒体影像学科 (630-9346)\n2F\t全球医疗服务经营学科 (630-9283)\n2F\t全球铁道/交通物流学部 (630-9347)\n2F\t全球餐饮创业学科 (629-6860)';

  @override
  String get west_campus_andycut_desc => '全球学科建筑';

  @override
  String get operating => '运营中';

  @override
  String get dormitory => '宿舍';

  @override
  String get military_facility => '军事设施';

  @override
  String get kindergarten => '幼儿园';

  @override
  String get sports_facility => '体育设施';

  @override
  String get complex_facility => '综合设施';

  @override
  String get search_campus_buildings => '搜索校园建筑';

  @override
  String get no_search_results => '没有搜索结果';

  @override
  String get building_details => '详细信息';

  @override
  String get parking => '停车';

  @override
  String get accessibility => '无障碍';

  @override
  String get facilities => '设施';

  @override
  String get elevator => '电梯';

  @override
  String get restroom => '洗手间';

  @override
  String get navigate_from_current_location => '从当前位置导航';

  @override
  String get title => '编辑个人资料';

  @override
  String get nameRequired => '请输入姓名';

  @override
  String get emailRequired => '请输入邮箱';

  @override
  String get save => '保存';

  @override
  String get saveSuccess => '个人资料已更新';

  @override
  String get my_info => '我的信息';

  @override
  String get guest_user => '예질배 크루';

  @override
  String get guest_role => '정진영의 노예';

  @override
  String get user => '用户';

  @override
  String get edit_profile => '编辑个人资料';

  @override
  String get edit_profile_subtitle => '您可以修改个人信息';

  @override
  String get help_subtitle => '查看应用使用方法';

  @override
  String get app_info_subtitle => '版本信息和开发者信息';

  @override
  String get delete_account_subtitle => '永久删除您的账户';

  @override
  String get login_message => '请登录或注册\n以使用所有功能';

  @override
  String get login_signup => '登录 / 注册';

  @override
  String get delete_account_confirm => '删除账户';

  @override
  String get delete_account_message => '您确定要删除账户吗？';

  @override
  String get logout_confirm => '注销';

  @override
  String get logout_message => '您确定要注销吗？';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get feature_in_progress => '功能正在开发中';

  @override
  String get delete_feature_in_progress => '账户删除功能正在开发中';

  @override
  String get app_info => '应用信息';

  @override
  String get app_version => '应用版本';

  @override
  String get developer => '开发者';

  @override
  String get developer_name => '姓名: 홍길동';

  @override
  String get developer_email => '邮箱: example@email.com';

  @override
  String get developer_github => 'GitHub: github.com/yourid';

  @override
  String get help => '帮助';

  @override
  String get no_help_images => '没有帮助图片';

  @override
  String get image_load_error => '无法加载图片';

  @override
  String get description_hint => '输入描述';

  @override
  String get email_required => '请输入邮箱';

  @override
  String get name_required => '请输入姓名';

  @override
  String get profile_updated => '个人资料已更新';

  @override
  String get schedule => '课程表';

  @override
  String get winter_semester => '冬季学期';

  @override
  String get spring_semester => '春季学期';

  @override
  String get summer_semester => '夏季学期';

  @override
  String get fall_semester => '秋季学期';

  @override
  String get monday => '周一';

  @override
  String get tuesday => '周二';

  @override
  String get wednesday => '周三';

  @override
  String get thursday => '周四';

  @override
  String get friday => '周五';

  @override
  String get time => '时间';

  @override
  String get add_class => '添加课程';

  @override
  String get edit_class => '编辑课程';

  @override
  String get delete_class => '删除课程';

  @override
  String get class_name => '课程名称';

  @override
  String get professor_name => '教授姓名';

  @override
  String get classroom => '教室';

  @override
  String get day_of_week => '星期';

  @override
  String get start_time => '开始时间';

  @override
  String get end_time => '结束时间';

  @override
  String get color_selection => '选择颜色';

  @override
  String get monday_full => '星期一';

  @override
  String get tuesday_full => '星期二';

  @override
  String get wednesday_full => '星期三';

  @override
  String get thursday_full => '星期四';

  @override
  String get friday_full => '星期五';

  @override
  String get class_added => '课程已添加。';

  @override
  String get class_updated => '课程已更新。';

  @override
  String get class_deleted => '课程已删除。';

  @override
  String delete_class_confirm(String className) {
    return '您要删除$className课程吗？';
  }

  @override
  String get view_on_map => '在地图上查看';

  @override
  String get location => '位置';

  @override
  String get schedule_time => '时间';

  @override
  String get schedule_day => '星期';

  @override
  String get map_feature_coming_soon => '地图功能将在以后添加。';

  @override
  String current_year(int year) {
    return '$year年';
  }

  @override
  String get my_friends => '我的朋友';

  @override
  String online_friends(int total, int online) {
    return '总计$total人 • 在线$online人';
  }

  @override
  String get add_friend => '添加朋友';

  @override
  String get friend_name_or_id => '请输入朋友的姓名或学号';

  @override
  String get friend_request_sent => '好友请求已发送。';

  @override
  String get online => '在线';

  @override
  String get offline => '离线';

  @override
  String get in_class => '上课中';

  @override
  String last_location(String location) {
    return '最后位置：$location';
  }

  @override
  String get central_library => '中央图书馆';

  @override
  String get engineering_building => '工程楼201';

  @override
  String get student_center => '学生中心';

  @override
  String get cafeteria => '自助餐厅';

  @override
  String get message => '消息';

  @override
  String get view_location => '查看位置';

  @override
  String get call => '通话';

  @override
  String start_chat_with(String name) {
    return '开始与$name聊天。';
  }

  @override
  String view_location_on_map(String name) {
    return '在地图上查看$name的位置。';
  }

  @override
  String calling(String name) {
    return '正在呼叫$name。';
  }

  @override
  String get add => '添加';

  @override
  String get close => '关闭';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get search => '搜索';

  @override
  String get searchBuildings => '搜索建筑...';

  @override
  String get myLocation => '我的位置';

  @override
  String get navigation => '导航';

  @override
  String get route => '路线';

  @override
  String get distance => '距离';

  @override
  String get minutes => '分钟';

  @override
  String get meters => '米';

  @override
  String get findRoute => '查找路线';

  @override
  String get clearRoute => '清除路线';

  @override
  String get setAsStart => '设为起点';

  @override
  String get setAsDestination => '设为终点';

  @override
  String get navigateFromHere => '从这里导航';

  @override
  String get buildingInfo => '建筑信息';

  @override
  String get category => '类别';

  @override
  String get locationPermissionRequired => '需要位置权限';

  @override
  String get enableLocationServices => '请启用位置服务';

  @override
  String get retry => '重试';

  @override
  String get noResults => '未找到结果';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get about => '关于';

  @override
  String friends_count_status(int total, int online) {
    return '总共 $total人 • 在线 $online人';
  }

  @override
  String get enter_friend_info => '请输入朋友的姓名或学号';

  @override
  String show_location_on_map(String name) {
    return '在地图上显示$name的位置。';
  }

  @override
  String get open_settings => '打开设置';

  @override
  String get location_error => '无法获取您的位置。';

  @override
  String get view_floor_plan => '查看平面图';

  @override
  String get floor_plan => '平面图';

  @override
  String floor_plan_title(String buildingName) {
    return '$buildingName 平面图';
  }

  @override
  String get floor_plan_not_available => '无法加载平面图图像';

  @override
  String get floor_plan_default_text => '平面图';

  @override
  String get delete_account_success => '您的账户已被删除。';

  @override
  String get convenience_store => '便利店';

  @override
  String get vending_machine => '自动售货机';

  @override
  String get printer => '打印机';

  @override
  String get copier => '复印机';

  @override
  String get atm => '自动取款机';

  @override
  String get bank_atm => '银行(ATM)';

  @override
  String get medical => '医疗';

  @override
  String get health_center => '卫生所';

  @override
  String get gym => '体育馆';

  @override
  String get fitness_center => '健身中心';

  @override
  String get lounge => '休息室';

  @override
  String get extinguisher => '灭火器';

  @override
  String get water_purifier => '饮水机';

  @override
  String get bookstore => '书店';

  @override
  String get post_office => '邮局';

  @override
  String get instructionExitToOutdoor => '请前往建筑出口';

  @override
  String instructionMoveToDestination(Object place) {
    return '前往 $place';
  }

  @override
  String instructionMoveToDestinationBuilding(Object building) {
    return '前往 $building 建筑';
  }

  @override
  String get instructionMoveToRoom => '前往目标房间';

  @override
  String get instructionArrived => '您已到达目的地！';

  @override
  String get search_hint => '请搜索校区建筑';

  @override
  String get searchHint => '请输入建筑名称或房间号进行搜索';

  @override
  String get searchInitialGuide => '搜索大楼或教室';

  @override
  String get searchHintExample => '例如：W19，工程馆，401室';

  @override
  String get searchLoading => '搜索中...';

  @override
  String get searchNoResult => '未找到搜索结果';

  @override
  String get searchTryAgain => '请尝试使用其他关键词';

  @override
  String get lectureRoom => '教室';

  @override
  String get status_open => '营业中';

  @override
  String get status_closed => '已关闭';

  @override
  String get status_next_open => '上午 9 点开始营业';

  @override
  String get status_next_close => '下午 6 点结束营业';

  @override
  String get status_next_open_tomorrow => '明天上午 9 点开始营业';

  @override
  String get office_hours => '09:00 - 18:00';

  @override
  String get status_24hours => '24小时';

  @override
  String get status_temp_closed => '临时休业';

  @override
  String get status_closed_permanently => '休业';

  @override
  String get label_basic_info => '基本信息';

  @override
  String get label_category_type => '分类';

  @override
  String get label_status => '状态';

  @override
  String get label_hours => '营业时间';

  @override
  String get label_phone => '电话号码';

  @override
  String get label_coordinates => '坐标';

  @override
  String get unified_navigation => '统一导航';

  @override
  String get unified_navigation_in_progress => '统一导航进行中';

  @override
  String get search_start_location => '请搜索出发地（建筑名或房间号）';

  @override
  String get search_end_location => '请搜索目的地（建筑名或房间号）';

  @override
  String get enter_start_location => '请输入出发地';

  @override
  String get enter_end_location => '请输入目的地';

  @override
  String get recent_searches => '最近搜索';

  @override
  String get clear_all => '全部删除';

  @override
  String get searching => '搜索中...';

  @override
  String get try_different_keyword => '请尝试其他关键词';

  @override
  String get my_location => '我的位置';

  @override
  String get start_from_current_location => '从当前位置出发';

  @override
  String get getting_current_location => '正在获取当前位置...';

  @override
  String get current_location_set_as_start => '当前位置已设为出发地';

  @override
  String get using_default_location => '使用默认位置';

  @override
  String get start_unified_navigation => '开始统一导航';

  @override
  String get set_both_locations => '请设置出发地和目的地';

  @override
  String get navigation_ended => '导航已结束';

  @override
  String get route_preview => '路线预览';

  @override
  String get calculating_optimal_route => '正在计算最优路线...';

  @override
  String get set_departure_and_destination => '请设置出发地和目的地\\n可以输入建筑名或房间号';

  @override
  String get total_distance => '总距离';

  @override
  String get route_type => '路线类型';

  @override
  String get departure_indoor => '出发地室内';

  @override
  String get to_building_exit => '到建筑出口';

  @override
  String get outdoor_movement => '室外移动';

  @override
  String get to_destination_building => '到目的地建筑';

  @override
  String get arrival_indoor => '到达地室内';

  @override
  String get to_final_destination => '到最终目的地';

  @override
  String get building_to_building => '建筑间';

  @override
  String get room_to_building => '房间→建筑';

  @override
  String get building_to_room => '建筑→房间';

  @override
  String get room_to_room => '房间间';

  @override
  String get location_to_building => '位置→建筑';

  @override
  String get unified_route => '统一路线';

  @override
  String preset_room_start(Object building, Object room) {
    return '$building $room号房间已设为出发地';
  }

  @override
  String preset_room_end(Object building, Object room) {
    return '$building $room号房间已设为目的地';
  }

  @override
  String preset_building_start(Object building) {
    return '$building已设为出发地';
  }

  @override
  String preset_building_end(Object building) {
    return '$building已设为目的地';
  }

  @override
  String floor_room(Object floor, Object room) {
    return '$floor层$room号房间';
  }

  @override
  String get available => '可用';

  @override
  String get current_location => '当前位置';

  @override
  String get start_navigation_from_here => '从当前位置开始导航';

  @override
  String get directions => '导航';

  @override
  String get navigateHere => '导航到这里';

  @override
  String get startLocation => '起点';

  @override
  String get endLocation => '终点';

  @override
  String get floor_plans => '楼层平面图';

  @override
  String get select_floor_to_view => '选择每层查看详细平面图';

  @override
  String get floor_info => '楼层信息';

  @override
  String get view_floor_plan_button => '查看楼层平面图';

  @override
  String get no_detailed_info => '无详细信息。';

  @override
  String get pinch_to_zoom => '捏合缩放，拖动移动';

  @override
  String get floor_plan_loading_failed => '楼层平面图加载失败';

  @override
  String loading_floor_plan(Object floor) {
    return '正在加载$floor楼层平面图...';
  }

  @override
  String server_info(Object building, Object floor) {
    return '服务器: $building/$floor';
  }

  @override
  String get building_name => '建筑物';

  @override
  String get floor_number => '楼层';

  @override
  String get room_name => '教室';

  @override
  String get overlap_message => '在该时间已注册课程。';

  @override
  String get memo => '备注';

  @override
  String get friendManagement => '朋友管理';

  @override
  String get friendManagementAndRequests => '朋友管理和请求';

  @override
  String get showLocation => '显示位置';

  @override
  String get removeLocation => '移除位置';

  @override
  String get accept => '接受';

  @override
  String get reject => '拒绝';

  @override
  String get id => 'ID';

  @override
  String get contact => '联系方式';

  @override
  String get lastLocation => '最后位置';

  @override
  String get noLocationInfo => '无位置信息';

  @override
  String get noContactInfo => '无信息';

  @override
  String friendRequestSent(String name) {
    return '已向$name发送好友请求！';
  }

  @override
  String friendRequestAccepted(String name) {
    return '已接受$name的好友请求。';
  }

  @override
  String friendRequestRejected(String name) {
    return '已拒绝$name的好友请求。';
  }

  @override
  String friendRequestCanceled(String name) {
    return '已取消向$name发送的好友请求。';
  }

  @override
  String friendDeleted(String name) {
    return '已从好友列表中删除$name。';
  }

  @override
  String friendLocationShown(String name) {
    return '$name的位置已在地图上显示。';
  }

  @override
  String friendLocationRemoved(String name) {
    return '$name的位置已从地图上移除。';
  }

  @override
  String friendCount(int count) {
    return '我的朋友 ($count)';
  }

  @override
  String sentRequestsCount(int count) {
    return '已发送 ($count)';
  }

  @override
  String receivedRequestsCount(int count) {
    return '已接收 ($count)';
  }

  @override
  String newFriendRequests(int count) {
    return '$count个新的好友请求';
  }

  @override
  String get addFriend => '添加';

  @override
  String get sent => '已发送';

  @override
  String get received => '已接收';

  @override
  String get sendFriendRequest => '发送好友请求';

  @override
  String get friendId => '朋友ID';

  @override
  String get enterFriendId => '请输入对方ID';

  @override
  String get enterFriendIdPrompt => '请输入要添加的朋友的ID';

  @override
  String get errorEnterFriendId => '请输入朋友ID。';

  @override
  String get errorCannotAddSelf => '不能添加自己为好友。';

  @override
  String get errorAddFriend => '添加好友时发生错误。';

  @override
  String get errorNetworkError => '网络错误，请重试。';

  @override
  String get errorCannotShowLocation => '无法显示朋友位置。';

  @override
  String get errorCannotRemoveLocation => '无法移除朋友位置。';

  @override
  String get realTimeSyncActive => '实时同步中 • 自动更新';

  @override
  String realTimeSyncStatus(String time) {
    return '实时同步激活 • $time';
  }

  @override
  String get noSentRequests => '没有已发送的好友请求。';

  @override
  String get noReceivedRequests => '没有收到的好友请求。';

  @override
  String get noFriends => '还没有朋友。\n点击上方的+按钮添加朋友吧！';

  @override
  String get cancelFriendRequest => '取消好友请求';

  @override
  String cancelFriendRequestConfirm(String name) {
    return '确定要取消向$name发送的好友请求吗？';
  }

  @override
  String get deleteFriend => '删除好友';

  @override
  String deleteFriendConfirm(String name) {
    return '确定要从好友列表中删除$name吗？';
  }

  @override
  String get cancelRequest => '取消';

  @override
  String requestDate(String date) {
    return '请求日期：$date';
  }

  @override
  String get newBadge => '新';

  @override
  String get friend_delete_title => '删除好友';

  @override
  String get friend_delete_warning => '请慎重决定';

  @override
  String friendDeleteQuestion(Object userName) {
    return '您确定要将$userName从好友列表中删除吗？\n删除的好友可以再次添加。';
  }

  @override
  String get empty_friend_list_message => '没有好友。';

  @override
  String get friendDeleteTitle => '删除好友';

  @override
  String get friendDeleteWarning => '请慎重决定';

  @override
  String get friendDeleteHeader => '待删除好友';

  @override
  String friendDeleteToConfirm(Object userName) {
    return '您确定要将$userName从好友列表中删除吗？\n删除的好友可以再次添加。';
  }

  @override
  String get friendDeleteCancel => '取消';

  @override
  String get friendDeleteButton => '删除';

  @override
  String friendDeleteSuccessMessage(Object userName) {
    return '已从好友列表中删除$userName。';
  }

  @override
  String get friendOfflineError => '此好友当前离线。';

  @override
  String get scheduleDeleteTitle => '删除时间表';

  @override
  String get scheduleDeleteSubtitle => '请慎重决定';

  @override
  String get scheduleDeleteLabel => '要删除的时间表';

  @override
  String scheduleDeleteDescription(Object title) {
    return '您确定要从时间表中删除“$title”课程吗？\n已删除的时间表无法恢复。';
  }

  @override
  String get cancelButton => '取消';

  @override
  String get deleteButton => '删除';

  @override
  String get phone_required => '请输入您的电话号码';
}
