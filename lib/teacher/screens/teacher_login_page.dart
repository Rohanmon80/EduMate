import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import 'teacher_signup_page.dart';
import 'teacher_main_navigation.dart';

class TeacherLoginPage extends StatefulWidget {
  const TeacherLoginPage({super.key});

  @override
  State<TeacherLoginPage> createState() =>
      _TeacherLoginPageState();
}

class _TeacherLoginPageState
    extends State<TeacherLoginPage> {

  bool obscurePassword = true;

  final TextEditingController
  emailController =
  TextEditingController();

  final TextEditingController
  passwordController =
  TextEditingController();

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
            "teacherBiometric",
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
        "Teacher Login",

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
          "teacherEmail",
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

                TeacherMainNavigation(),
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

  @override

  void dispose(){

    emailController.dispose();

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

            SingleChildScrollView(

              child: Column(

                children: [

                  const SizedBox(height: 18),

                  Padding(
                    padding:
                    const EdgeInsets.symmetric(
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

                  const Padding(
                    padding:
                    EdgeInsets.symmetric(
                      horizontal: 25,
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        Text(
                          "Teacher Login",

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          "Welcome back, Faculty",

                          style: TextStyle(
                            color:
                            Colors.white70,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),

                  Container(

                    margin:
                    const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),

                    padding:
                    const EdgeInsets.all(25),

                    decoration: BoxDecoration(

                      color:
                      isDark
                          ? const Color(
                        0xFF16213E,
                      )
                          : const Color(
                        0xFFEFF7FD,
                      ),

                      borderRadius:
                      BorderRadius.circular(
                        38,
                      ),

                      boxShadow: [

                        BoxShadow(
                          color:
                          Colors.black
                              .withOpacity(
                            0.08,
                          ),

                          blurRadius: 25,

                          offset:
                          const Offset(
                            0,
                            10,
                          ),
                        ),
                      ],
                    ),

                    child: Column(

                      children: [

                        CircleAvatar(
                          radius: 42,

                          backgroundColor:
                          Colors.white,

                          child: ClipRRect(

                            borderRadius:
                            BorderRadius.circular(
                              40,
                            ),

                            child: Image.asset(
                              "assets/images/college_logo.png",

                              fit: BoxFit.cover,

                              width: 75,
                              height: 75,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 28,
                        ),

                        Align(
                          alignment:
                          Alignment.centerLeft,

                          child: Text(
                            "Teacher Email",
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
                          ),

                          child: TextField(

                            controller:
                            emailController,

                            decoration:
                            const InputDecoration(

                              hintText:
                              "teacher@gmail.com",

                              prefixIcon:
                              Icon(
                                Icons.mail_outline,
                                color:
                                Colors.blue,
                              ),

                              border:
                              InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 28,
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
                          ),

                          child: TextField(

                            controller:
                            passwordController,

                            obscureText:
                            obscurePassword,

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

                                onPressed:
                                    () {

                                  setState(() {

                                    obscurePassword =
                                    !obscurePassword;
                                  });
                                },

                                icon: Icon(

                                  obscurePassword

                                      ? Icons.visibility_off

                                      : Icons.visibility,
                                ),
                              ),

                              border:
                              InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 35,
                        ),

                        SizedBox(

                          width:
                          double.infinity,

                          height:
                          65,

                          child:
                          ElevatedButton(

                            onPressed:
                                () async {

                              try {

                                UserCredential user =

                                await FirebaseAuth
                                    .instance

                                    .signInWithEmailAndPassword(

                                  email:
                                  emailController.text.trim(),

                                  password:
                                  passwordController.text.trim(),
                                );

                                SharedPreferences prefs =

                                await SharedPreferences
                                    .getInstance();

                                await prefs.setString(

                                  "teacherUid",

                                  user.user!.uid,
                                );

                                await prefs.setString(

                                  "teacherEmail",

                                  user.user!.email!,
                                );

                                await prefs.setString(

                                  "savedPassword",

                                  passwordController.text
                                      .trim(),
                                );

                                await prefs.setString(
                                  "userRole",
                                  "teacher",
                                );

                                bool alreadyAsked =

                                    prefs.getBool(
                                      "teacherBiometricAsked",
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

                                                "teacherBiometric",

                                                false,
                                              );

                                              prefs.setBool(

                                                "teacherBiometricAsked",

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

                                                      TeacherMainNavigation(),
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

                                                "teacherBiometric",

                                                true,
                                              );

                                              prefs.setBool(

                                                "teacherBiometricAsked",

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

                                                      TeacherMainNavigation(),
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

                                          TeacherMainNavigation(),
                                    ),
                                  );
                                }
                              }

                              catch (e) {

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

                            child:
                            const Text(
                              "Sign in",
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        GestureDetector(

                          onTap: () {

                            Navigator.push(

                              context,

                              MaterialPageRoute(

                                builder:
                                    (_) =>

                                const TeacherSignupPage(),
                              ),
                            );
                          },

                          child: Container(

                            width:
                            double.infinity,

                            height:
                            62,

                            alignment:
                            Alignment.center,

                            child:
                            const Text(
                              "Create new account",
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 18,
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
                            ),

                            child:
                            const Row(

                              mainAxisAlignment:
                              MainAxisAlignment.center,

                              children: [

                                Icon(
                                  Icons.fingerprint,
                                  color:
                                  Colors.blue,
                                ),

                                SizedBox(
                                  width: 10,
                                ),

                                Text(
                                  "Use Biometric",
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}