import 'package:flutter/material.dart';
import 'admin_dashboard_page.dart';
import '../../main.dart';
import 'admin_signup_page.dart';
import 'admin_main_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});



  @override
  State<AdminLoginPage> createState() =>
      _AdminLoginPageState();
}

class _AdminLoginPageState
    extends State<AdminLoginPage> {

  final LocalAuthentication
  auth =
  LocalAuthentication();

  Future<void>
  loginWithBiometric()

  async {

    try {

      SharedPreferences prefs =

      await SharedPreferences
          .getInstance();

      bool allowed =

          prefs.getBool(
            "adminBiometric",
          )

              ??

              false;

      if(!allowed){

        ScaffoldMessenger.of(
          context,
        )

            .showSnackBar(

          const SnackBar(

            content:
            Text(
              "Biometric not enabled",
            ),
          ),
        );

        return;
      }

      bool authenticated =

      await auth.authenticate(

        localizedReason:
        "Admin Login",

        options:

        const AuthenticationOptions(

          biometricOnly:false,

          stickyAuth:true,
        ),
      );

      if(
      authenticated &&
          mounted
      ){

        String? email =

        prefs.getString(
          "adminEmail",
        );

        String? password =

        prefs.getString(
          "savedPassword",
        );

        if(
        email == null ||
            password == null
        ){

          ScaffoldMessenger.of(
            context,
          )

              .showSnackBar(

            const SnackBar(

              content:
              Text(
                "Login normally first",
              ),
            ),
          );

          return;
        }

        await FirebaseAuth
            .instance

            .signInWithEmailAndPassword(

          email:email,

          password:password,
        );

        Navigator.pushReplacement(

          context,

          MaterialPageRoute(

            builder:
                (_)=>

            const AdminMainNavigation(),
          ),
        );
      }

    }

    catch(e){

      ScaffoldMessenger.of(
        context,
      )

          .showSnackBar(

        SnackBar(

          content:
          Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  bool obscurePassword = true;
  final TextEditingController
  adminIdController =
  TextEditingController();

  final TextEditingController
  passwordController =
  TextEditingController();

  @override

  void dispose(){

    adminIdController.dispose();

    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(


      backgroundColor:
      isDark
          ? const Color(0xFF0B1736)
          : const Color(0xFFF4F8FC),

      body: SafeArea(

        child: Stack(

          children: [

            /// TOP BLUE BACKGROUND
            Container(
              height: 320,

              decoration: const BoxDecoration(

                gradient: LinearGradient(
                  colors: [
                    Color(0xFF005BEA),
                    Color(0xFF00C6FB),
                  ],
                ),

                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(45),
                  bottomRight: Radius.circular(45),
                ),
              ),
            ),

            /// CONTENT
            SingleChildScrollView(

              child: Column(

                children: [

                  const SizedBox(height: 18),

                  /// TOP BUTTONS
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),

                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                      children: [

                        GestureDetector(

                          onTap: () {

                            Navigator.pop(context);
                          },

                          child: CircleAvatar(
                            backgroundColor:
                            Colors.white.withOpacity(0.15),

                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        CircleAvatar(
                          backgroundColor:
                          Colors.white.withOpacity(0.15),

                          child: IconButton(

                            onPressed: () {
                              Navigator.pop(context);

                              EduMateApp.of(context)
                                  ?.toggleTheme();
                            },

                            icon: Icon(

                              isDark
                                  ? Icons.light_mode
                                  : Icons.dark_mode,

                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// TITLE
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 25,
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        Text(
                          "Admin Login",

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          "Welcome back, Admin",

                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),

                  /// LOGIN CARD
                  Container(

                    margin: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),

                    padding: const EdgeInsets.all(25),

                    decoration: BoxDecoration(

                      color:
                      isDark
                          ? const Color(0xFF16213E)
                          : const Color(0xFFEFF7FD),

                      borderRadius:
                      BorderRadius.circular(38),

                      boxShadow: [
                        BoxShadow(
                          color:
                          Colors.black.withOpacity(0.08),

                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),

                    child: Column(

                      children: [

                        /// COLLEGE LOGO
                        CircleAvatar(
                          radius: 42,

                          backgroundColor: Colors.white,

                          child: ClipRRect(
                            borderRadius:
                            BorderRadius.circular(40),

                            child: Image.asset(
                              "assets/images/college_logo.png",

                              fit: BoxFit.cover,

                              width: 75,
                              height: 75,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        /// ROLL NUMBER
                        Align(
                          alignment: Alignment.centerLeft,

                          child: Text(
                            "Admin ID",

                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,

                              color:
                              isDark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(

                          decoration: BoxDecoration(

                            color:
                            isDark
                                ? const Color(0xFF1E2A47)
                                : Colors.white,

                            borderRadius:
                            BorderRadius.circular(22),

                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),

                          child: TextField(

                            controller:
                            adminIdController,

                            style: TextStyle(
                              color:
                              isDark
                                  ? Colors.white
                                  : Colors.black,
                            ),

                            decoration:
                            const InputDecoration(

                              hintText:
                              "admin@gmail.com",

                              prefixIcon:
                              Icon(
                                Icons.mail_outline,
                                color:
                                Colors.blue,
                              ),

                              border:
                              InputBorder.none,

                              contentPadding:
                              EdgeInsets.symmetric(
                                vertical:22,
                              ),
                            ),
                          ),
                        ),






                          /// PASSWORD
                          Align(

                            alignment:
                            Alignment.centerLeft,

                            child: Text(

                              "Password",

                              style: TextStyle(

                                fontSize: 18,

                                fontWeight:
                                FontWeight.w600,

                                color:
                                isDark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Container(

                            decoration:
                            BoxDecoration(

                              color:
                              isDark
                                  ? const Color(
                                0xFF1E2A47,
                              )
                                  : Colors.white,

                              borderRadius:
                              BorderRadius.circular(
                                22,
                              ),

                              border:
                              Border.all(

                                color:
                                Colors.grey.shade300,
                              ),
                            ),

                            child: TextField(

                              controller:
                              passwordController,

                              obscureText:
                              obscurePassword,

                              style: TextStyle(

                                color:
                                isDark
                                    ? Colors.white
                                    : Colors.black,
                              ),

                              decoration:
                              InputDecoration(

                                prefixIcon:
                                const Icon(

                                  Icons.key,

                                  color:
                                  Colors.blue,
                                ),

                                suffixIcon:
                                IconButton(

                                  onPressed: () {

                                    setState(() {

                                      obscurePassword =
                                      !obscurePassword;
                                    });
                                  },

                                  icon: Icon(

                                    obscurePassword

                                        ? Icons.visibility_off

                                        : Icons.visibility,

                                    color:
                                    Colors.grey,
                                  ),
                                ),

                                border:
                                InputBorder.none,

                                contentPadding:
                                const EdgeInsets.symmetric(
                                  vertical: 22,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 35,
                          ),


                        /// LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 65,

                          child: ElevatedButton(

                            onPressed: () async {

                              try{

                                UserCredential user =

                                await FirebaseAuth
                                    .instance

                                    .signInWithEmailAndPassword(

                                  email:
                                  adminIdController
                                      .text
                                      .trim(),

                                  password:
                                  passwordController
                                      .text
                                      .trim(),
                                );

                                String uid =

                                    user.user!.uid;

                                DocumentSnapshot doc =

                                await FirebaseFirestore
                                    .instance

                                    .collection(
                                  "admins",
                                )

                                    .doc(uid)

                                    .get();

                                if(
                                doc.exists &&

                                    doc["role"]
                                        ==
                                        "admin"
                                ){

                                  SharedPreferences prefs =

                                  await SharedPreferences
                                      .getInstance();

                                  await prefs.setString(

                                    "adminUid",

                                    user.user!.uid,
                                  );

                                  await prefs.setString(

                                    "adminEmail",

                                    user.user!.email!,
                                  );

                                  await prefs.setString(

                                    "savedPassword",

                                    passwordController.text
                                        .trim(),
                                  );

                                  await prefs.setString(
                                    "userRole",
                                    "admin",
                                  );

                                  bool alreadyAsked =

                                      prefs.getBool(
                                        "adminBiometricAsked",
                                      )

                                          ??

                                          false;

                                  if(
                                  !alreadyAsked
                                  ){

                                    showDialog(

                                      context:context,

                                      builder:(_){

                                        return AlertDialog(

                                          title:
                                          const Text(
                                            "Enable Biometric?",
                                          ),

                                          content:
                                          const Text(
                                            "Use fingerprint login?",
                                          ),

                                          actions:[

                                            TextButton(

                                              onPressed:(){

                                                prefs.setBool(

                                                  "adminBiometric",

                                                  false,
                                                );

                                                prefs.setBool(

                                                  "adminBiometricAsked",

                                                  true,
                                                );

                                                Navigator.pop(
                                                  context,
                                                );

                                                Navigator.pushReplacement(

                                                  context,

                                                  MaterialPageRoute(

                                                    builder:
                                                        (_)=>

                                                    const AdminMainNavigation(),
                                                  ),
                                                );
                                              },

                                              child:
                                              const Text(
                                                "No",
                                              ),
                                            ),

                                            ElevatedButton(

                                              onPressed:(){

                                                prefs.setBool(

                                                  "adminBiometric",

                                                  true,
                                                );

                                                prefs.setBool(

                                                  "adminBiometricAsked",

                                                  true,
                                                );

                                                Navigator.pop(
                                                  context,
                                                );

                                                Navigator.pushReplacement(

                                                  context,

                                                  MaterialPageRoute(

                                                    builder:
                                                        (_)=>

                                                    const AdminMainNavigation(),
                                                  ),
                                                );
                                              },

                                              child:
                                              const Text(
                                                "Enable",
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }

                                  else{

                                    Navigator.pushReplacement(

                                      context,

                                      MaterialPageRoute(

                                        builder:
                                            (_)=>

                                        const AdminMainNavigation(),
                                      ),
                                    );
                                  }
                                }




                                else{

                                  await FirebaseAuth
                                      .instance
                                      .signOut();

                                  ScaffoldMessenger.of(
                                    context,
                                  )

                                      .showSnackBar(

                                    const SnackBar(

                                      content:
                                      Text(
                                        "Not Admin Account",
                                      ),
                                    ),
                                  );
                                }
                              }

                              catch(e){

                                ScaffoldMessenger.of(
                                  context,
                                )

                                    .showSnackBar(

                                  SnackBar(
                                    content:
                                    Text(
                                      e.toString(),
                                    ),
                                  ),
                                );
                              }
                            },

                            style: ElevatedButton.styleFrom(

                              backgroundColor:
                              const Color(0xFF008CFF),

                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(22),
                              ),
                            ),

                            child: const Text(
                              "Sign in",

                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        Row(

                          children: [

                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade400,
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ),

                              child: Text("or"),
                            ),

                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),


                        /// CREATE ACCOUNT
                        GestureDetector(

                          onTap: () {

                            Navigator.push(

                              context,

                              MaterialPageRoute(
                                builder: (_) =>
                                const AdminSignupPage(),
                              ),
                            );
                          },

                          child: Container(
                            width: double.infinity,
                            height: 62,

                            decoration: BoxDecoration(

                              borderRadius:
                              BorderRadius.circular(22),

                              border: Border.all(
                                color: Colors.blue.shade200,
                              ),
                            ),

                            child: const Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,

                              children: [

                                Icon(
                                  Icons.person_add_alt_1,
                                  color: Colors.blue,
                                ),

                                SizedBox(width: 10),

                                Text(
                                  "Create new account",

                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        GestureDetector(

                          onTap:
                          loginWithBiometric,

                          child:
                          Container(

                            width:
                            double.infinity,

                            height:
                            62,

                            decoration:
                            BoxDecoration(

                              color:

                              isDark

                                  ? const Color(
                                0xFF1E2A47,
                              )

                                  : Colors.white,

                              borderRadius:
                              BorderRadius.circular(
                                22,
                              ),

                              border:
                              Border.all(
                                color:
                                Colors.grey.shade300,
                              ),
                            ),

                            child:
                            const Row(

                              mainAxisAlignment:
                              MainAxisAlignment.center,

                              children:[

                                Icon(
                                  Icons.fingerprint,
                                  color:
                                  Colors.blue,
                                ),

                                SizedBox(
                                  width:10,
                                ),

                                Text(
                                  "Use Biometric",
                                  style:
                                  TextStyle(
                                    fontSize:20,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,

                    children: [

                      Text(
                        "Don't have an account?",

                        style: TextStyle(
                          color:
                          isDark
                              ? Colors.white70
                              : Colors.grey,
                        ),
                      ),

                      const SizedBox(width: 5),

                      const Text(
                        "Sign up",

                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}