import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sustainable_scholars/core/sign_in_provider.dart';
import 'package:sustainable_scholars/ui/signed.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key, required this.apiKey});

  final String apiKey;

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final signInFormKey = GlobalKey<FormState>();

  TextEditingController email = TextEditingController();

  TextEditingController pswd = TextEditingController();

  String? validateEmail() {
    const String pattern =
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$";
    final RegExp regExp = RegExp(pattern);
    if (email.text.isEmpty) {
      return "Email cannot be empty";
    } else if (!regExp.hasMatch(email.text)) {
      return "Enter a valid email id";
    } else {
      return null;
    }
  }

  String? validatePassword() {
    if (pswd.text.isEmpty) {
      return "Password cannot be empty";
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Form(
            key: signInFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      child: TextFormField(
                        autofocus: true,
                        autovalidateMode: AutovalidateMode.onUnfocus,
                        controller: email,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(5.0),
                            ),
                          ),
                          icon: Icon(Icons.email_outlined),
                          labelText: "Enter school email ID",
                          // suffixIcon: getEmailSuffixIcon(),
                        ),
                        autocorrect: false,
                        maxLines: 1,
                        minLines: 1,
                        textAlign: TextAlign.center,
                        validator: (value) {
                          return validateEmail();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      child: TextFormField(
                        autofocus: false,
                        autovalidateMode: AutovalidateMode.onUnfocus,
                        controller: pswd,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(5.0),
                            ),
                          ),
                          icon: Icon(Icons.password),
                          labelText: "Password",
                          // suffixIcon: getEmailSuffixIcon(),
                        ),
                        autocorrect: false,
                        maxLines: 1,
                        minLines: 1,
                        textAlign: TextAlign.center,
                        validator: (value) {
                          return validatePassword();
                        },
                        obscureText: true,
                      ),
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
                        return ElevatedButton(
                          style: const ButtonStyle(
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5.0),
                                ),
                              ),
                            ),
                          ),
                          onPressed: () async {
                            if (signInFormKey.currentState!.validate()) {
                              signInFormKey.currentState!.save();
                              var resp = await http.post(
                                Uri.parse(
                                  "http://127.0.0.1:5000/login",
                                ),
                                body: {
                                  "Email": email.text,
                                  "Password": pswd.text,
                                },
                              );
      
                              if (context.mounted) {
                                if (resp.statusCode == 403) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Login Failed"),
                                      content: const Text(
                                        "Check your username and password",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).popUntil(
                                              (route) => route.isFirst,
                                            );
                                          },
                                          child: const Text("Ok"),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  value.setAkey(
                                    json.decode(resp.body)["ACCESS-KEY"],
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => SignedInView(
                                          apiKey: widget.apiKey,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          },
                          child: const Text('Sign In'),
                        );
                      },
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    TextButton(
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
                        email.text = '';
                        pswd.text = '';
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
