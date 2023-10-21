import 'package:chatapp/firebase_options.dart';
import 'package:chatapp/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:generic_social_widgets/chat_bubble.dart';
import 'package:generic_social_widgets/chat_input.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Chat App",
      theme: ThemeData(useMaterial3: true),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("A great chat app"),
        centerTitle: false,
        actions: [
          ElevatedButton(
            onPressed: () async {
              final auth = FirebaseAuth.instance;
              if (auth.currentUser != null) {
                await auth.signOut();
              } else {
                await auth.signInAnonymously();
              }
            },
            child: const Text('Log In or Out'),
          )
        ],
      ),
      body: ChatView(),
    );
  }
}

class ChatView extends StatelessWidget {
  ChatView({super.key});

  final messagesQuery = FirebaseFirestore.instance
      .collection('messages')
      .orderBy('timestamp', descending: true);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        return Column(
          children: [
            Text('User id: ${authSnapshot.data?.uid}'),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: messagesQuery.snapshots(),
                builder: (context, messagesSnapshot) {
                  if (messagesSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (messagesSnapshot.hasData) {
                    return ListView.builder(
                        reverse: true,
                        itemCount: messagesSnapshot.data!.size,
                        itemBuilder: (BuildContext context, int idx) {
                          final message = Message.fromFirestore(
                              messagesSnapshot.data!.docs[idx] as DocumentSnapshot<Map<String, dynamic>>);
                          return ChatBubble(text: message.message);
                        });
                  }
                  return const Text('Error maybe?');
                },
              ),
            ),
            ChatTextInput(
              onSend: (message) {
                FirebaseFirestore.instance.collection('messages').add(
                      Message(
                        uid: authSnapshot.data!.uid,
                        message: message,
                      ).toFirestore(),
                    );
              },
            )
          ],
        );
      },
    );
  }
}
