import 'dart:ui';

import 'package:flutter/material.dart';

import '../../main.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() =>
      _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  final TextEditingController
  messageController =
  TextEditingController();

  final List<Map<String, dynamic>>
  messages = [

    {
      "text":
      "Good morning sir, can you share today's notes?",
      "isMe": true,
    },

    {
      "text":
      "Sure, I will upload them after class.",
      "isMe": false,
    },

    {
      "text":
      "Thank you sir.",
      "isMe": true,
    },
  ];

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

                    Stack(

                      children: [

                        Container(
                          width: 64,
                          height: 64,

                          decoration: BoxDecoration(
                            shape: BoxShape.circle,

                            gradient:
                            const LinearGradient(
                              colors: [
                                Color(0xFF005BEA),
                                Color(0xFF00C6FB),
                              ],
                            ),
                          ),

                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),

                        Positioned(
                          right: 4,
                          bottom: 4,

                          child: Container(
                            width: 16,
                            height: 16,

                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,

                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 18),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Text(
                            "Prof. Sharma",

                            style: TextStyle(
                              fontSize: 22,
                              fontWeight:
                              FontWeight.bold,

                              color:
                              isDark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            "Online",
                            style: TextStyle(
                              color: Colors.green,
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

            /// MESSAGES
            Expanded(

              child: ListView.builder(

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                itemCount: messages.length,

                itemBuilder:
                    (context, index) {

                  final message =
                  messages[index];

                  return Align(

                    alignment:
                    message["isMe"]
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
                        maxWidth: 280,
                      ),

                      decoration: BoxDecoration(

                        color:
                        message["isMe"]
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
                        message["text"],

                        style: TextStyle(
                          fontSize: 16,

                          color:
                          message["isMe"]
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

            /// MESSAGE INPUT
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
                          "Type message...",

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

                        onPressed: () {

                          if (messageController
                              .text
                              .isNotEmpty) {

                            setState(() {

                              messages.add({

                                "text":
                                messageController
                                    .text,

                                "isMe": true,
                              });
                            });

                            messageController
                                .clear();
                          }
                        },

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