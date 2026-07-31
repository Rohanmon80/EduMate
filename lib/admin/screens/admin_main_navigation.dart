import 'package:flutter/material.dart';
import 'admin_dashboard_page.dart';
import 'admin_profile_page.dart';

import 'database_page.dart';
import 'admin_student_management_page.dart';
import 'admin_fee_management_page.dart';
import 'admin_analytics_page.dart';


class AdminMainNavigation
    extends StatefulWidget {

  const AdminMainNavigation({
    super.key,
  });

  @override
  State<AdminMainNavigation>
  createState() =>
      _AdminMainNavigationState();
}

class _AdminMainNavigationState
    extends State<AdminMainNavigation> {

  int currentIndex = 0;

  final List<Widget> pages = [
    AdminDashboardPage(),

    const DatabasePage(),

    const AdminFeeManagementPage(),

    const AdminAnalyticsPage(),

    const AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(

      extendBody: false,

      backgroundColor:
      isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

        body: Stack(

            clipBehavior:
            Clip.none,

        children: [

        Padding(

        padding:

        const EdgeInsets.only(
          bottom:120,
        ),

      child:

      pages[currentIndex],
    ),

          Positioned(

            left:14,

            right:14,

            bottom:12,

            child:

            SafeArea(

              child:

              ClipRRect(

                borderRadius:

                BorderRadius.circular(
                  32,
                ),

                child:

                Container(

              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),

              decoration: BoxDecoration(

                color:
                isDark
                    ? Colors.white
                    .withOpacity(0.08)
                    : Colors.white,

                borderRadius:
                BorderRadius.circular(32),

                border: Border.all(

                  color:
                  isDark
                      ? Colors.white
                      .withOpacity(0.08)
                      : Colors.black12,
                ),
              ),

                  child: Row(

                    mainAxisAlignment:
                    MainAxisAlignment.spaceAround,

                    children:[

                      Expanded(
                        child:
                        navItem(
                          context,
                          Icons.home,
                          "Home",
                          0,
                        ),
                      ),

                      Expanded(
                        child:
                        navItem(
                          context,
                          Icons.groups,
                          "DB",
                          1,
                        ),
                      ),

                      Expanded(
                        child:
                        navItem(
                          context,
                          Icons.account_balance_wallet,
                          "Receipt",
                          2,
                        ),
                      ),

                      Expanded(
                        child:
                        navItem(
                          context,
                          Icons.bar_chart,
                          "Stats",
                          3,
                        ),
                      ),

                      Expanded(
                        child:
                        navItem(
                          context,
                          Icons.person,
                          "Me",
                          4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
    );
  }

  Widget navItem(
      BuildContext context,
      IconData icon,
      String label,
      int index,
      ) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final bool isSelected =
        currentIndex == index;

    return GestureDetector(

      onTap: () {

        setState(() {

          currentIndex = index;
        });
      },

      child: AnimatedContainer(

        duration:
        const Duration(
          milliseconds: 250,
        ),

        padding:
        const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),

        decoration: BoxDecoration(

          color:
          isSelected
              ? Colors.blue
              .withOpacity(0.18)
              : Colors.transparent,

          borderRadius:
          BorderRadius.circular(20),
        ),

        child: SizedBox(

          width:50,

          child:

          Column(

          mainAxisSize:
          MainAxisSize.min,

          children: [

            Icon(

              icon,

              size: 24,

              color:
              isSelected
                  ? Colors.blue
                  : isDark
                  ? Colors.white70
                  : Colors.black54,
            ),

            const SizedBox(height: 4),

            Text(

              label,

              overflow:
              TextOverflow.ellipsis,

              maxLines:1,

              style: TextStyle(

                fontSize: 10,

                color:
                isSelected
                    ? Colors.blue
                    : isDark
                    ? Colors.white70
                    : Colors.black54,

              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}