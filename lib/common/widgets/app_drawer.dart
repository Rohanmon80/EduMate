import 'package:flutter/material.dart';
import '../screens/ai_assistant_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/bus_tracking_page.dart';
import '../screens/campus_map_page.dart';
import '../screens/certificate_vault_page.dart';
import '../screens/chat_page.dart';
import '../screens/coding_contest_page.dart';
import '../screens/events_page.dart';
import '../screens/library_page.dart';
import '../screens/placement_page.dart';

import '../screens/project_hub_page.dart';
import '../screens/scholarship_page.dart';
import '../screens/settings_page.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  Future<Map<String, dynamic>?> getUserData() async {

    final email = FirebaseAuth.instance.currentUser?.email;

    if (email == null) return null;

    final collections = [
      "users",
      "teachers",
      "admins",
    ];

    for (final collection in collections) {

      final query = await FirebaseFirestore.instance
          .collection(collection)
          .where("email", isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {

        return query.docs.first.data();

      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {

    return Drawer(

      child: ListView(

        padding: EdgeInsets.zero,

        children: [

          FutureBuilder<Map<String, dynamic>?>(
            future: getUserData(),

            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const UserAccountsDrawerHeader(
                  accountName: Text("Loading..."),
                  accountEmail: Text(""),
                  currentAccountPicture: CircleAvatar(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                );
              }

              final user = snapshot.data!;

              final photoUrl =
              user.containsKey("photoUrl")
                  ? user["photoUrl"] ?? ""
                  : "";

              return UserAccountsDrawerHeader(

                accountName: Text(user["name"] ?? ""),

                accountEmail: Text(user["email"] ?? ""),

                currentAccountPicture: CircleAvatar(

                  backgroundImage:
                  photoUrl.toString().isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,

                  child:
                  photoUrl.toString().isEmpty
                      ? const Icon(Icons.person, size: 42)
                      : null,
                ),
              );
            },
          ),





          drawerTile(
            context,
            "Library",
            Icons.local_library,
            const LibraryPage(),
          ),

          drawerTile(
            context,
            "Chat",
            Icons.chat,
            const ChatPage(),
          ),

          drawerTile(
            context,
            "AI Assistant",
            Icons.smart_toy,
            const AIAssistantPage(),
          ),

          drawerTile(
            context,
            "Events",
            Icons.event,
            const EventsPage(),
          ),

          drawerTile(
            context,
            "Placement",
            Icons.business_center,
            const PlacementPage(),
          ),

          drawerTile(
            context,
            "Project Hub",
            Icons.groups,
            const ProjectHubPage(),
          ),

          drawerTile(
            context,
            "Scholarships",
            Icons.workspace_premium,
            const ScholarshipPage(),
          ),

          drawerTile(
            context,
            "Coding Contest",
            Icons.code,
            const CodingContestPage(),
          ),

          drawerTile(
            context,
            "Campus Map",
            Icons.map,
            const CampusMapPage(),
          ),

          drawerTile(
            context,
            "Bus Tracking",
            Icons.directions_bus,
            const BusTrackingPage(),
          ),

          drawerTile(
            context,
            "Certificates",
            Icons.folder,
            const CertificateVaultPage(),
          ),

          drawerTile(
            context,
            "Settings",
            Icons.settings,
            const SettingsPage(),
          ),
        ],
      ),
    );
  }

  Widget drawerTile(
      BuildContext context,
      String title,
      IconData icon,
      Widget page,
      ) {

    return ListTile(

      leading: Icon(icon),

      title: Text(title),

      onTap: () {

        Navigator.push(

          context,

          MaterialPageRoute(
            builder: (_) => page,
          ),
        );
      },
    );
  }
}