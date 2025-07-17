// lib/friends/friend_repository.dart
import 'friend_api_service.dart';
import 'friend.dart';

class FriendRepository {
  final FriendApiService apiService;
  FriendRepository(this.apiService);

  Future<List<Friend>> getMyFriends(String myId) =>
      apiService.fetchMyFriends(myId);
  Future<void> requestFriend(String myId, String addId) =>
      apiService.addFriend(myId, addId);
  Future<List<FriendRequest>> getFriendRequests(String myId) =>
      apiService.fetchFriendRequests(myId);
  Future<void> acceptRequest(String myId, String addId) =>
      apiService.acceptFriendRequest(myId, addId);
  Future<void> rejectRequest(String myId, String addId) =>
      apiService.rejectFriendRequest(myId, addId);
  Future<void> deleteFriend(String myId, String addId) =>
      apiService.deleteFriend(myId, addId);
  Future<Friend?> getFriendInfo(String friendId) async {
    return await apiService.fetchFriendInfo(friendId);
  }

  /// 내가 보낸 친구 요청 목록 조회
  Future<List<SentFriendRequest>> getSentFriendRequests(String myId) =>
      apiService.fetchSentFriendRequests(myId);

  /// 보낸 친구 요청 취소
  Future<void> cancelSentRequest(String myId, String friendId) =>
      apiService.cancelSentFriendRequest(myId, friendId);
}
