// friends_controller.dart
// 친구 및 친구 요청 상태 관리, UI와 연결

import 'package:flutter/material.dart';
import 'friend.dart';
import 'friend_repository.dart';

class FriendsController extends ChangeNotifier {
  final FriendRepository repository;
  final String myId; // 내 ID

  FriendsController(this.repository, this.myId);

  List<Friend> friends = [];
  List<FriendRequest> friendRequests = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      friends = await repository.getMyFriends(myId);
      friendRequests = await repository.getFriendRequests(myId);
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
}

