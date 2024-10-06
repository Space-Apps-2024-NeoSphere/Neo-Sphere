import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sustainable_scholars/core/sign_in_provider.dart';
import 'package:http/http.dart' as http;
import 'package:sustainable_scholars/ui/login.dart';
import 'package:sustainable_scholars/ui/signed.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: non_constant_identifier_names
final String APIKEY = Platform.environment["GEMINI_API_KEY"]!;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.apiKey});
  final String apiKey;

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  late final GenerativeModel model;
  final safe = [
    SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
    SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
    SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
    SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
    SafetySetting(HarmCategory.unspecified, HarmBlockThreshold.none),
  ];

  ChatScreenState() {
    model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: APIKEY,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'text/plain',
      ),
      safetySettings: safe,
      systemInstruction: Content.system(
        'You are a tutor specializing in SDGs from UN. You will respond accuately to any queries regarding the 17 SDGs and will ignore all other questions. Integrate data from https://eo4sdg.org/, https://eotoolkit.unhabitat.org/, https://www.earthdata.nasa.gov/worldview, https://earthobservatory.nasa.gov/ for explaining with example.if  anything is asked give priority to https://www.earthdata.nasa.gov/worldview and fetch data . ',
      ),
    );
  }

  void _sendMessage({bool user = true}) {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add({"Message": message, "User": user.toString()});
        _aiSendMessage(message);
      });
      _controller.clear();
    }
  }

  void _aiSendMessage(String prompt) async {
    List chatHistory = [];
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i]["User"] == "true") {
        chatHistory.add(
          Content.multi(
            [
              TextPart(_messages[i]["Message"]!),
            ],
          ),
        );
      } else {
        chatHistory.add(
          Content.model(
            [
              TextPart(_messages[i]["Message"]!),
            ],
          ),
        );
      }
    }
    final chat = model.startChat();
    final msg = prompt;
    final content = Content.text(msg);

    final resp = await chat.sendMessage(content);
    print(resp.toString());
    var txt = resp.text!;

    // final resp = chat.sendMessageStream(content);
    // var txt = '';
    // await for (var response in resp) {
    //   txt += response.text!;
    // }
    setState(() {
      _messages.add(
        {"Message": txt, "User": "false"},
      );
    });
  }

  Widget _buildMessageBubble(String message, bool isUser) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(
          ClipboardData(text: message),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content copied to clipboard.'),
          ),
        );
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
          padding: const EdgeInsets.all(15),
          width: 350,
          decoration: BoxDecoration(
            color: isUser ? Colors.blue[100] : Colors.grey[300],
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              String m = _messages[index]["Message"]!;
              bool isUser = bool.parse(_messages[index]["User"]!);
              return _buildMessageBubble(m, isUser);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  textInputAction: TextInputAction.done,
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter your query',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key, required this.apiKey});
  final String apiKey;

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 97, 158, 158),
        actions: [
          Consumer<SignInProvider>(
            builder: (context, value, child) {
              return IconButton(
                onPressed: () async {
                  await http.post(
                    Uri.parse("http://127.0.0.1:5000/logout"),
                    body: {
                      "ACCESS-KEY":
                          Provider.of<SignInProvider>(context, listen: false)
                              .akey,
                    },
                  );
                  if (context.mounted) {
                    value.setAkey('');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SignedInView(
                          apiKey: widget.apiKey,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
              );
            },
          ),
          const SizedBox(
            width: 20,
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return const ProfileView();
                  },
                ),
              );
            },
            icon: const Icon(Icons.person),
          ),
          const SizedBox(
            width: 20,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) => setState(
          () {
            currentPageIndex = index;
          },
        ),
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'AI Assist',
          ),
          NavigationDestination(
            icon: Icon(Icons.event),
            label: 'Events',
          )
        ],
      ),
      body: <Widget>[
        HomePageIg(
          apiKey: widget.apiKey,
        ),
        ChatScreen(
          apiKey: widget.apiKey,
        ),
        const Events(),
      ][currentPageIndex],
    );
  }
}

class HomePageIg extends StatefulWidget {
  const HomePageIg({super.key, required this.apiKey});
  final String apiKey;

  @override
  State<HomePageIg> createState() => _HomePageIgState();
}

class _HomePageIgState extends State<HomePageIg> {
  final List<Map<String, dynamic>> courseList = [
    {
      "title": "No Poverty",
      "thumbnail": "assets/no-poverty.jpg",
      "hasContent": 'https://google.com',
    },
    {
      "title": "Zero Hunger",
      "thumbnail": "assets/zero-hunger.jpg",
      "hasContent": '',
    },
    {
      "title": "Good Health & Well Being",
      "thumbnail": "assets/good-health.jpg",
      "hasContent": '',
    },
    {
      "title": "Quality Education",
      "thumbnail": "assets/quality-education.jpg",
      "hasContent": '',
    },
    {
      "title": "Gender Equality",
      "thumbnail": "assets/gender-equalty.jpg",
      "hasContent": '',
    },
    {
      "title": "Clean Water & Sanitation",
      "thumbnail": "assets/clean-water.jpg",
      "hasContent": '',
    },
    {
      "title": "Affordable & Clean Energy",
      "thumbnail": "assets/clean-energy.jpg",
      "hasContent": '',
    },
    {
      "title": "Decent Work & Economic Growth",
      "thumbnail": "assets/work.jpg",
      "hasContent": '',
    },
    {
      "title": "Industry, Innovation & Infrastructure",
      "thumbnail": "assets/industry.jpg",
      "hasContent": '',
    },
    {
      "title": "Reduced Inequalities",
      "thumbnail": "assets/reduced-inequalities.jpg",
      "hasContent": '',
    },
    {
      "title": "Sustainable Cities & Communities",
      "thumbnail": "assets/sustainable.jpg",
      "hasContent": '',
    },
    {
      "title": "Responsible Consumption & Production",
      "thumbnail": "assets/prod.jpg",
      "hasContent": '',
    },
    {
      "title": "Climate Action",
      "thumbnail": "assets/climate.jpg",
      "hasContent": '',
    },
    {
      "title": "Life Below Water",
      "thumbnail": "assets/life-below-water.jpg",
      "hasContent": '',
    },
    {
      "title": "Life On Land",
      "thumbnail": "assets/img-goal-15.jpg",
      "hasContent": '',
    },
    {
      "title": "Peace, Justice & Strong Institutions",
      "thumbnail": "assets/img-goal-16.jpg",
      "hasContent": '',
    },
    {
      "title": "Partnerships for the Goals",
      "thumbnail": "assets/img-goal-17.jpg",
      "hasContent": '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (Provider.of<SignInProvider>(context, listen: false).akey == '') {
      return Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/climate_change.jpg',
            ),
            opacity: 0.4,
          ),
        ),
        child: Column(
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
            ),
          ],
        ),
      );
    } else {
      // return ListView.separated(
      //   itemCount: courseList.length,
      //   itemBuilder: (context, index) {
      //     return Padding(
      //       padding: const EdgeInsets.all(20.0),
      //       child: Container(
      //         decoration: BoxDecoration(
      //           color: Theme.of(context).colorScheme.inversePrimary,
      //           borderRadius: const BorderRadius.all(
      //             Radius.circular(15.0),
      //           ),
      //         ),
      //         child: ListTile(
      //           leading: Image.asset(
      //             courseList[index]["thumbnail"],
      //             height: 100,
      //             width: 100,
      //           ),
      //           title: Text(
      //             courseList[index]["title"],
      //           ),
      //           contentPadding: const EdgeInsets.all(12.0),
      //           shape: const RoundedRectangleBorder(
      //             borderRadius: BorderRadius.all(
      //               Radius.circular(12.0),
      //             ),
      //           ),
      //         ),
      //       ),
      //     );
      //   },
      //   separatorBuilder: (BuildContext context, int index) {
      //     return const SizedBox(
      //       height: 10,
      //     );
      //   },
      // );
      return GridView.builder(
        padding: const EdgeInsets.all(20.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of columns
          childAspectRatio: 0.5, // Aspect ratio of each grid item
          crossAxisSpacing: 20.0,
          mainAxisSpacing: 25.0,
        ),
        itemCount: courseList.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 236, 234, 234),
              borderRadius: BorderRadius.all(
                Radius.circular(15.0),
              ),
            ),
            child: GestureDetector(
              onTap: () async {
                if (courseList[index]["hasContent"] != '') {
                  await launchUrl(
                    Uri.parse(
                      courseList[index]["hasContent"],
                    ),
                  );
                }
              },
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15.0)),
                      child: Image.asset(
                        courseList[index]["thumbnail"],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      courseList[index]["title"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}

class Events extends StatefulWidget {
  const Events({super.key});

  @override
  State<Events> createState() => _EventsState();
}

class _EventsState extends State<Events> {
  // final List<Map<String, String>> elist = [];
  final List<Map<String, String>> elist = [
    {"Name": "SDG Webinar", "Date": "Jan 01 2025", "Type": "Online"},
    {"Name": "SDG Workshop", "Date": "Jan 25 2025", "Type": "Offline"},
    {"Name": "SDG Hackathon", "Date": "Feb 24 2025", "Type": "Offline"},
    {"Name": "SDG Conference", "Date": "Apr 16 2025", "Type": "Offline"},
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: elist.isEmpty
          ? const Center(
              child: Text(
                "No events available",
              ),
            )
          : ListView.separated(
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(5.0),
                      ),
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.event_available),
                      title: Text(elist[index]["Name"]!),
                      subtitle: Text(elist[index]["Date"]!),
                      trailing: Text(elist[index]["Type"]!),
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(
                height: 10,
              ),
              itemCount: elist.length,
            ),
    );
  }
}
