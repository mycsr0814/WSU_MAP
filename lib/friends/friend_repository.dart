// friend_repository.dart
// 친구 관련 비즈니스 로직 및 데이터 가공

import 'friend_api_service.dart';
import 'friend.dart';

class FriendRepository {
  final FriendApiService apiService;
  FriendRepository(this.apiService);

  Future<List<Friend>> getMyFriends(String myId) => apiService.fetchMyFriends(myId);
  Future<void> requestFriend(String myId, String addId) => apiService.addFriend(myId, addId);
  Future<List<FriendRequest>> getFriendRequests(String myId) => apiService.fetchFriendRequests(myId);
  Future<void> acceptRequest(String myId, String addId) => apiService.acceptFriendRequest(myId, addId);
  Future<void> rejectRequest(String myId, String addId) => apiService.rejectFriendRequest(myId, addId);
  Future<void> deleteFriend(String myId, String addId) => apiService.deleteFriend(myId, addId);
}

