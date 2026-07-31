import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_main_navigation.dart';


class AdminSignupPage
    extends StatefulWidget {

  const AdminSignupPage({
    super.key,
  });

  @override
  State<AdminSignupPage>
  createState() =>
      _AdminSignupPageState();
}

class _AdminSignupPageState
    extends State<AdminSignupPage> {

  bool obscurePassword = true;
  final TextEditingController
  nameController =
  TextEditingController();

  final TextEditingController
  adminIdController =
  TextEditingController();

  final TextEditingController
  emailController =
  TextEditingController();

  final TextEditingController
  passwordController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(

      backgroundColor:
      isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      body: SafeArea(

        child: SingleChildScrollView(

          child: Column(

            children: [

              /// TOP SECTION
              Container(

                width: double.infinity,
                height: 260,

                decoration:
                const BoxDecoration(

                  gradient:
                  LinearGradient(
                    colors: [
                      Color(0xFF005BEA),
                      Color(0xFF00C6FB),
                    ],
                  ),

                  borderRadius:
                  BorderRadius.only(
                    bottomLeft:
                    Radius.circular(
                      40,
                    ),
                    bottomRight:
                    Radius.circular(
                      40,
                    ),
                  ),
                ),

                child: Padding(

                  padding:
                  const EdgeInsets.all(
                    24,
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [

                      GestureDetector(

                        onTap: () {

                          Navigator.pop(
                            context,
                          );
                        },

                        child: const CircleAvatar(
                          backgroundColor:
                          Colors.white24,

                          child: Icon(
                            Icons.arrow_back,
                            color:
                            Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 35,
                      ),

                      const Text(
                        "Admin Sign Up",

                        style: TextStyle(
                          fontSize: 34,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          Colors.white,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      const Text(
                        "Create your admin account",

                        style: TextStyle(
                          fontSize: 16,
                          color:
                          Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Transform.translate(

                offset:
                const Offset(0, -30),

                child: Padding(

                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 20,
                  ),

                  child: ClipRRect(

                    borderRadius:
                    BorderRadius.circular(
                      30,
                    ),

                    child: BackdropFilter(

                      filter:
                      ImageFilter.blur(
                        sigmaX: 20,
                        sigmaY: 20,
                      ),

                      child: Container(

                        padding:
                        const EdgeInsets
                            .all(24),

                        decoration:
                        BoxDecoration(

                          color:
                          isDark
                              ? Colors
                              .white
                              .withOpacity(
                            0.08,
                          )
                              : Colors
                              .white
                              .withOpacity(
                            0.35,
                          ),

                          borderRadius:
                          BorderRadius.circular(
                            30,
                          ),
                        ),

                        child: Column(

                          children: [

                            TextField(

                              controller:
                              nameController,

                              decoration:
                              inputDecoration(

                                "Full Name",

                                Icons.person,

                                isDark,
                              ),
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            TextField(

                              controller:
                              adminIdController,

                              decoration:
                              inputDecoration(

                                "Admin ID",

                                Icons.badge,

                                isDark,
                              ),
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            TextField(

                              controller:
                              emailController,

                              decoration:
                              inputDecoration(

                                "Email",

                                Icons.email,

                                isDark,
                              ),
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            TextField(

                              controller:
                              passwordController,

                              obscureText:
                              obscurePassword,

                              decoration:
                              inputDecoration(
                                "Password",
                                Icons.lock,
                                isDark,
                              ).copyWith(

                                suffixIcon:
                                IconButton(

                                  icon: Icon(

                                    obscurePassword
                                        ? Icons
                                        .visibility_off
                                        : Icons
                                        .visibility,
                                  ),

                                  onPressed:
                                      () {

                                    setState(
                                          () {

                                        obscurePassword =
                                        !obscurePassword;
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 30,
                            ),

                            SizedBox(

                              width:
                              double.infinity,

                              height: 58,

                              child:
                              ElevatedButton(

                                onPressed:
                                    () async {

                                  try{

                                    if(

                                    nameController.text.isEmpty ||

                                        adminIdController.text.isEmpty ||

                                        emailController.text.isEmpty ||

                                        passwordController.text.isEmpty
                                    ){

                                      ScaffoldMessenger.of(
                                        context,
                                      )

                                          .showSnackBar(

                                        const SnackBar(

                                          content:
                                          Text(
                                            "Fill all fields",
                                          ),
                                        ),
                                      );

                                      return;
                                    }

                                    UserCredential user =

                                    await FirebaseAuth
                                        .instance

                                        .createUserWithEmailAndPassword(

                                      email:
                                      emailController
                                          .text
                                          .trim(),

                                      password:
                                      passwordController
                                          .text
                                          .trim(),
                                    );

                                    await FirebaseFirestore
                                        .instance

                                        .collection(
                                      "admins",
                                    )

                                        .doc(
                                      user.user!.uid,
                                    )

                                        .set({

                                      "id":
                                      adminIdController.text,

                                      "name":
                                      nameController.text,

                                      "adminId":
                                      adminIdController.text,

                                      "designation":
                                      "Administrator",

                                      "email":
                                      emailController.text,

                                      "phone":"",

                                      "bio":"",

                                      "photoUrl":"",

                                      "designation":
                                      "Administrator",

                                      "office":
                                      "Main Office",

                                      "role":"admin",

                                      "adminBiometric":false,
                                    });

                                    if(
                                    mounted
                                    ){

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
                                },

                                style:
                                ElevatedButton.styleFrom(

                                  backgroundColor:
                                  const Color(
                                    0xFF007BFF,
                                  ),

                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                      18,
                                    ),
                                  ),
                                ),

                                child: const Text(
                                  "Create Account",

                                  style:
                                  TextStyle(
                                    fontSize:
                                    18,
                                    fontWeight:
                                    FontWeight.bold,
                                    color:
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(
      String hint,
      IconData icon,
      bool isDark,
      ) {

    return TextField(

      decoration:
      inputDecoration(
        hint,
        icon,
        isDark,
      ),
    );
  }

  InputDecoration inputDecoration(
      String hint,
      IconData icon,
      bool isDark,
      ) {

    return InputDecoration(

      hintText: hint,

      prefixIcon:
      Icon(icon),

      filled: true,

      fillColor:
      isDark
          ? Colors.white
          .withOpacity(0.08)
          : Colors.white,

      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          18,
        ),

        borderSide:
        BorderSide.none,
      ),
    );
  }
}