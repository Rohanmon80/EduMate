import 'dart:ui';

import 'package:flutter/material.dart';

import '../../main.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() =>
      _LibraryPageState();
}

class _LibraryPageState
    extends State<LibraryPage> {

  final TextEditingController
  searchController =
  TextEditingController();

  final List<Map<String, dynamic>>
  books = [

    {
      "title": "Operating System Concepts",
      "author": "Silberschatz",
      "category": "OS",
      "color": Colors.blue,
    },

    {
      "title": "Database System Concepts",
      "author": "Korth",
      "category": "DBMS",
      "color": Colors.green,
    },

    {
      "title": "Artificial Intelligence",
      "author": "Russell",
      "category": "AI",
      "color": Colors.orange,
    },

    {
      "title": "Java Complete Reference",
      "author": "Herbert Schildt",
      "category": "JAVA",
      "color": Colors.purple,
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

        child: SingleChildScrollView(

          padding:
          const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              /// TOP BAR
              Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

                children: [

                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [

                      Text(
                        "Digital Library",

                        style: TextStyle(
                          fontSize: 36,
                          fontWeight:
                          FontWeight.bold,

                          color:
                          isDark
                              ? Colors.white
                              : const Color(
                            0xFF0B1736,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        "Explore study resources",

                        style: TextStyle(
                          fontSize: 16,

                          color:
                          isDark
                              ? Colors.white70
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  glassIcon(
                    icon:
                    isDark
                        ? Icons.light_mode
                        : Icons.dark_mode,

                    onTap: () {

                      EduMateApp.of(
                        context,
                      )?.toggleTheme();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 35),

              /// SEARCH
              TextField(

                controller:
                searchController,

                style: TextStyle(
                  color:
                  isDark
                      ? Colors.white
                      : Colors.black,
                ),

                decoration:
                InputDecoration(

                  filled: true,

                  fillColor:
                  isDark
                      ? Colors.white
                      .withOpacity(
                    0.08,
                  )
                      : Colors.white
                      .withOpacity(
                    0.35,
                  ),

                  hintText:
                  "Search books...",

                  hintStyle: TextStyle(
                    color:
                    isDark
                        ? Colors.white70
                        : Colors.grey,
                  ),

                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.blue,
                  ),

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      22,
                    ),

                    borderSide:
                    BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              Text(
                "Trending Books",

                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.bold,

                  color:
                  isDark
                      ? Colors.white
                      : Colors.black,
                ),
              ),

              const SizedBox(height: 20),

              ...books.map(
                    (book) => bookTile(
                  isDark: isDark,
                  book: book,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget bookTile({
    required bool isDark,
    required Map<String, dynamic>
    book,
  }) {

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 18,
      ),

      child: glassCard(

        isDark: isDark,

        child: Row(

          children: [

            Container(
              width: 70,
              height: 90,

              decoration:
              BoxDecoration(
                color:
                book["color"]
                    .withOpacity(
                  0.15,
                ),

                borderRadius:
                BorderRadius.circular(
                  20,
                ),
              ),

              child: Icon(
                Icons.menu_book,
                color: book["color"],
                size: 38,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [

                  Text(
                    book["title"],

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.bold,

                      color:
                      isDark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    book["author"],

                    style: TextStyle(
                      color:
                      isDark
                          ? Colors
                          .white70
                          : Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Container(

                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    decoration:
                    BoxDecoration(
                      color:
                      book["color"]
                          .withOpacity(
                        0.15,
                      ),

                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),

                    child: Text(
                      book["category"],

                      style: TextStyle(
                        color:
                        book["color"],
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Column(

              children: [

                IconButton(

                  onPressed: () {},

                  icon: Icon(
                    Icons.download,
                    color:
                    book["color"],
                  ),
                ),

                const SizedBox(height: 10),

                IconButton(

                  onPressed: () {},

                  icon: const Icon(
                    Icons.picture_as_pdf,
                    color:
                    Colors.redAccent,
                  ),
                ),
              ],
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

          padding:
          const EdgeInsets.all(22),

          decoration: BoxDecoration(

            color:
            isDark
                ? Colors.white
                .withOpacity(0.08)
                : Colors.white
                .withOpacity(0.35),

            borderRadius:
            BorderRadius.circular(
              28,
            ),

            border: Border.all(
              color:
              Colors.white
                  .withOpacity(0.2),
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

        decoration:
        BoxDecoration(

          color: Colors.white
              .withOpacity(
            0.12,
          ),

          borderRadius:
          BorderRadius.circular(
            18,
          ),

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