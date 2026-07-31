import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() =>
      _AIAssistantPageState();
}

class _AIAssistantPageState
    extends State<AIAssistantPage> {

  final TextEditingController
  messageController =
  TextEditingController();

  final List<Map<String, dynamic>>
  chats = [

    {
      "message":
      "Hello 👋 I am EduMate AI Assistant. How can I help you today?",
      "isUser": false,
    },
  ];

  Future<void> sendMessage() async {

    if(
    messageController.text
        .isEmpty
    ){

      return;
    }

    String question =

    messageController.text
        .toLowerCase();

    setState(() {

      chats.add({

        "message":

        messageController.text,

        "isUser":
        true,
      });
    });

    messageController.clear();

    final uid =

        FirebaseAuth
            .instance
            .currentUser!
            .uid;

    final doc =

    await FirebaseFirestore
        .instance

        .collection(
      "users",
    )

        .doc(uid)

        .get();

    final student =

    doc.data()!;

    double attendance =

    (student[
    "attendance"
    ] ?? 0)
        .toDouble();

    String reply =

        "Ask attendance, CGPA, fees, semester or exam dates.";

    if(

    question.contains(
        "attendance"
    )

        &&

        question.contains(
            "percentage"
        )

    ){

      reply =

      "Attendance: ${attendance.toStringAsFixed(1)}%";
    }

    else if(

    question.contains(
        "cgpa"
    )

        ||

        question.contains(
            "result"
        )

    ){

      reply =

      "CGPA: ${student["cgpa"]}";
    }

    else if(

    question.contains(
        "fees"
    )

    ){

      reply =

      "Pending fees ₹${student["feesDue"] ?? 0}";
    }

    else if(

    question.contains(
        "semester"
    )

    ){

      reply =

      "Semester ${student["semester"]}";
    }

    else if(

    question.contains(
        "exam"
    )

    ){

      reply =

      "Check notices page for exam dates.";
    }

    else if(

    question.contains(
        "75"
    )

        ||

        question.contains(
            "attendance short"
        )

    ){

      int total =

          student[
          "totalClasses"
          ] ?? 0;

      int attended =

          student[
          "attendedClasses"
          ] ?? 0;

      int extra = 0;

      while(

      ((attended+extra)

          /

          (total+extra))

          *100

          <75

      ){

        extra++;
      }

      reply =

      attendance >=75

          ?

      "Attendance safe"

          :

      "You need $extra more classes to cross 75%.";
    }

    setState(() {

      chats.add({

        "message":
        reply,

        "isUser":
        false,
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(

      appBar: AppBar(

        backgroundColor: Colors.transparent,

        elevation: 0,

        leading: IconButton(

          icon: const Icon(Icons.arrow_back),

          onPressed: () {

            Navigator.pop(context);
          },
        ),
      ),

      backgroundColor:
      isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      body: SafeArea(

        child: Column(

          children: [

            /// TOP BAR
            Padding(
              padding: const EdgeInsets.all(20),

              child: glassCard(

                isDark: isDark,

                child: Row(

                  children: [

                    Container(
                      width: 70,
                      height: 70,

                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,

                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF005BEA),
                            Color(0xFF00C6FB),
                          ],
                        ),
                      ),

                      child: ClipOval(

                        child:

                        Image.asset(

                          "assets/images/logo.png",

                          fit:
                          BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(width: 18),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Text(
                            "EduMate AI",

                            style: TextStyle(
                              fontSize: 24,
                              fontWeight:
                              FontWeight.bold,

                              color:
                              isDark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            "AI Student Assistant",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    glassIcon(
                      icon:
                      isDark
                          ? Icons.light_mode
                          : Icons.dark_mode,

                      onTap: () {

                        EduMateApp.of(context)
                            ?.toggleTheme();
                      },
                    ),
                  ],
                ),
              ),
            ),

            /// CHAT AREA
            Expanded(

              child: ListView.builder(

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                itemCount: chats.length,

                itemBuilder:
                    (context, index) {

                  final chat =
                  chats[index];

                  return Align(

                    alignment:
                    chat["isUser"]
                        ? Alignment.centerRight
                        : Alignment.centerLeft,

                    child: Container(

                      margin:
                      const EdgeInsets.only(
                        bottom: 16,
                      ),

                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),

                      constraints:
                      const BoxConstraints(
                        maxWidth: 300,
                      ),

                      decoration: BoxDecoration(

                        color:
                        chat["isUser"]
                            ? const Color(
                          0xFF008CFF,
                        )
                            : isDark
                            ? Colors.white
                            .withOpacity(
                          0.08,
                        )
                            : Colors.white
                            .withOpacity(
                          0.5,
                        ),

                        borderRadius:
                        BorderRadius.circular(
                          22,
                        ),
                      ),

                      child: Text(
                        chat["message"],

                        style: TextStyle(
                          fontSize: 16,

                          color:
                          chat["isUser"]
                              ? Colors.white
                              : isDark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            /// INPUT
            Padding(
              padding: const EdgeInsets.all(20),

              child: glassCard(

                isDark: isDark,

                child: Row(

                  children: [

                    Expanded(

                      child: TextField(

                        controller:
                        messageController,

                        style: TextStyle(
                          color:
                          isDark
                              ? Colors.white
                              : Colors.black,
                        ),

                        decoration:
                        InputDecoration(

                          hintText:
                          "Ask EduMate AI...",

                          hintStyle: TextStyle(
                            color:
                            isDark
                                ? Colors.white70
                                : Colors.grey,
                          ),

                          border:
                          InputBorder.none,
                        ),
                      ),
                    ),

                    Container(
                      width: 52,
                      height: 52,

                      decoration: const BoxDecoration(
                        color:
                        Color(0xFF008CFF),
                        shape: BoxShape.circle,
                      ),

                      child: IconButton(

                        onPressed: sendMessage,

                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget glassCard({
    required bool isDark,
    required Widget child,
  }) {

    return ClipRRect(

      borderRadius:
      BorderRadius.circular(28),

      child: BackdropFilter(

        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),

        child: Container(

          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(

            color:
            isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.35),

            borderRadius:
            BorderRadius.circular(28),

            border: Border.all(
              color:
              Colors.white.withOpacity(0.2),
            ),
          ),

          child: child,
        ),
      ),
    );
  }

  Widget glassIcon({
    required IconData icon,
    VoidCallback? onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(
        width: 52,
        height: 52,

        decoration: BoxDecoration(

          color:
          Colors.white.withOpacity(0.12),

          borderRadius:
          BorderRadius.circular(18),

          border: Border.all(
            color: Colors.white24,
          ),
        ),

        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }
}