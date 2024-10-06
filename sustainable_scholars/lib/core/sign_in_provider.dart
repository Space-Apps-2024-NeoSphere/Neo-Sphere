import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInProvider extends ChangeNotifier {
  final String accessKey = "ACCESS-KEY";
  late SharedPreferencesAsync s;
  String akey = '';

  SignInProvider() {
    s = SharedPreferencesAsync();
    init();
  }

  void init() async {
    akey = await s.getString(accessKey) ?? '';
    notifyListeners();
  }

  void setAkey(String acc) async {
    await s.setString(accessKey, acc);
    akey = acc;
    notifyListeners();
  }

  String getAkey() {
    return akey;
  }
}
