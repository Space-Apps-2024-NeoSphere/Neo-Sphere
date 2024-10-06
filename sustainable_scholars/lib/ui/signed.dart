import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sustainable_scholars/core/sign_in_provider.dart';
import 'package:sustainable_scholars/ui/courses.dart';
import 'package:sustainable_scholars/ui/login.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class SignedInView extends StatefulWidget {
  const SignedInView({super.key, required this.apiKey});
  final String apiKey;

  @override
  State<SignedInView> createState() => _SignedInViewState();
}

class _SignedInViewState extends State<SignedInView> {
  final Player player = Player();
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    player.open(Media('asset:///assets/bkg.mp4'));
    _controller = VideoController(player);
    player.setPlaylistMode(PlaylistMode.single);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String p = Provider.of<SignInProvider>(context, listen: false).getAkey();
    print("The key is: $p");
    print(p.length);
    if (p == '' || p.isEmpty || p.trim() == '') {
      double width = MediaQuery.sizeOf(context).width;
      double height = MediaQuery.sizeOf(context).height;
      _controller.setSize(
        height: height.toInt(),
        width: width.toInt(),
      );
      return Scaffold(
        body: Stack(
          children: [
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Video(
                    controller: _controller,
                    controls: NoVideoControls,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: const ButtonStyle(
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(5.0),
                            ),
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => LogInPage(
                              apiKey: widget.apiKey,
                            ),
                          ),
                        );
                      },
                      child: const Text('Sign In'),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      );
    } else {
      return CoursesPage(
        apiKey: widget.apiKey,
      );
    }
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/person.jpg',
                    height: 100,
                    width: 100,
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Consumer<SignInProvider>(
                    builder: (context, value, child) {
                      var akeyDec = utf8.decode(base64.decode(value.akey));
                      var emailId = akeyDec.split('-')[0];
                      return Text(emailId.toString());
                    },
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Student"),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
