// lib/friends/friends_controller.dart
import 'package:flutter/material.dart';
import 'friend.dart';
import 'friend_repository.dart';

class FriendsController extends ChangeNotifier {
  final FriendRepository repository;
  final String myId;

  FriendsController(this.repository, this.myId);

  List<Friend> friends = [];
  List<FriendRequest> friendRequests = [];
  List<SentFriendRequest> sentFriendRequests = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      friends = await repository.getMyFriends(myId);
      friendRequests = await repository.getFriendRequests(myId);
      sentFriendRequests = await repository.getSentFriendRequests(myId);
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> addFriend(String addId) async {
    try {
      await repository.requestFriend(myId, addId);
      await loadAll();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> acceptRequest(String addId) async {
    try {
      await repository.acceptRequest(myId, addId);
      await loadAll();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> rejectRequest(String addId) async {
    try {
      await repository.rejectRequest(myId, addId);
      await loadAll();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteFriend(String addId) async {
    try {
      await repository.deleteFriend(myId, addId);
      await loadAll();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelSentRequest(String friendId) async {
    try {
      await repository.cancelSentRequest(myId, friendId);
      await loadAll();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<Friend?> getFriendInfo(String friendId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final friendInfo = await repository.getFriendInfo(friendId);
      return friendInfo;
    } catch (e) {
      errorMessage = e.toString();
      print('[ERROR] 친구 정보 조회 실패: $e');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
