import 'package:flutter/material.dart';
import 'dart:ui';
import 'student_dashboard_page.dart';
import 'attendance_page.dart';
import 'materials_page.dart';
import 'receipts_page.dart';
import 'student_profile_page.dart';

class StudentMainNavigation extends StatefulWidget {
  const StudentMainNavigation({super.key});

  @override
  State<StudentMainNavigation> createState() =>
      _StudentMainNavigationState();
}

class _StudentMainNavigationState
    extends State<StudentMainNavigation> {

  int currentIndex = 0;

  final List<Widget> pages = [
    const StudentDashboardPage(),


    const AttendancePage(),
    const MaterialsPage(),
    const ReceiptsPage(),
    const StudentProfilePage(),
  ];

  Widget navItem(

      int index,

      IconData icon,

      String label,

      ){

    bool selected =

        currentIndex == index;

    final isDark =

        Theme.of(context)
            .brightness

            ==

            Brightness.dark;

    return GestureDetector(

      onTap:(){

        setState(() {

          currentIndex = index;
        });
      },

      child:

      Column(

        mainAxisAlignment:
        MainAxisAlignment.center,

        children:[

          AnimatedContainer(

            duration:

            const Duration(
              milliseconds:300,
            ),

            padding:

            const EdgeInsets.all(
              12,
            ),

            decoration:

            BoxDecoration(

              borderRadius:

              BorderRadius.circular(
                18,
              ),

              gradient:

              selected

                  ?

              const LinearGradient(

                colors:[

                  Color(
                    0xFF008CFF,
                  ),

                  Color(
                    0xFF0057FF,
                  ),
                ],
              )

                  : null,

              color:

              selected

                  ?

              null

                  :

              Colors.transparent,

              boxShadow:

              selected

                  ?

              [

                BoxShadow(

                  color:

                  Colors.blue
                      .withOpacity(
                    0.35,
                  ),

                  blurRadius:15,
                ),
              ]

                  : [],
            ),

            child:

            Icon(

              icon,

              size:20,

              color:

              selected

                  ?

              Colors.white

                  :

              isDark

                  ?

              Colors.white70

                  :

              Colors.black54,
            ),
          ),

          const SizedBox(
            height:5,
          ),

          Text(

            label,

            style:

            TextStyle(

              fontSize:11,

              fontWeight:

              selected

                  ?

              FontWeight.bold

                  :

              FontWeight.w500,

              color:

              selected

                  ?

              Colors.blue

                  :

              isDark

                  ?

              Colors.white70

                  :

              Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: pages[currentIndex],

      bottomNavigationBar:

      Padding(

        padding:

        const EdgeInsets.only(

          left:18,

          right:18,

          bottom:14,
        ),

        child:

        ClipRRect(

          borderRadius:

          BorderRadius.circular(
            34,
          ),

          child:

          BackdropFilter(

            filter:

            ImageFilter.blur(

              sigmaX:25,

              sigmaY:25,
            ),

            child:

            Container(

              height:84,

              decoration:

              BoxDecoration(

                gradient:

                LinearGradient(

                  begin:
                  Alignment.topLeft,

                  end:
                  Alignment.bottomRight,

                  colors:

                  Theme.of(context)
                      .brightness

                      ==

                      Brightness.dark

                      ?

                  [

                    Colors.white
                        .withOpacity(
                      0.10,
                    ),

                    Colors.white
                        .withOpacity(
                      0.04,
                    ),
                  ]

                      :

                  [

                    Colors.white
                        .withOpacity(
                      0.92,
                    ),

                    Colors.white
                        .withOpacity(
                      0.75,
                    ),
                  ],
                ),

                borderRadius:

                BorderRadius.circular(
                  34,
                ),

                border:

                Border.all(

                  color:

                  Theme.of(context)
                      .brightness

                      ==

                      Brightness.dark

                      ?

                  Colors.white24

                      :

                  Colors.white,
                ),

                boxShadow:[

                  BoxShadow(

                    blurRadius:30,

                    spreadRadius:2,

                    offset:

                    const Offset(
                      0,
                      10,
                    ),

                    color:

                    Colors.black
                        .withOpacity(
                      0.10,
                    ),
                  ),
                ],
              ),

              child:

              Row(

                mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,

                children:[

                  navItem(
                    0,
                    Icons.home_rounded,
                    "Home",
                  ),

                  navItem(
                    1,
                    Icons.calendar_month,
                    "Attend",
                  ),

                  navItem(
                    2,
                    Icons.menu_book,
                    "Material",
                  ),

                  navItem(
                    3,
                    Icons.receipt_long,
                    "Fees",
                  ),

                  navItem(
                    4,
                    Icons.person,
                    "Me",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}