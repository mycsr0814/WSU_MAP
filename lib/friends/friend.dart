// friend.dart
// 친구 및 친구 요청 관련 데이터 모델 정의
//
// 이 파일은 친구(Friend)와 친구 요청(FriendRequest) 객체의 구조와
// JSON 직렬화/역직렬화(factory 생성자) 로직을 포함합니다.

/// 친구 정보 모델 클래스
///
/// 서버에서 내려주는 친구 정보(JSON)를 앱 내부에서 다루기 위한 데이터 구조입니다.
class Friend {
  final String userId;
  final String userName;
  final String profileImage;

  Friend({
    required this.userId,
    required this.userName,
    required this.profileImage,
  });

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
    userId: (json['user_id'] ?? json['Id'] ?? '').toString(),
    userName: (json['user_name'] ?? json['Name'] ?? '').toString(),
    profileImage: (json['profile_image'] ?? '').toString(),
  );
}

/// 친구 요청 정보 모델 클래스
class FriendRequest {
  final String fromUserId;
  final String fromUserName;

  FriendRequest({required this.fromUserId, required this.fromUserName});

  /// JSON 데이터를 FriendRequest 객체로 변환하는 팩토리 생성자
  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
    fromUserId: (json['from_user_id'] ?? json['Id'] ?? '').toString(),
    fromUserName: (json['from_user_name'] ?? json['Name'] ?? '').toString(),
  );
}
