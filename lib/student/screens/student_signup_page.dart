import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'student_main_navigation.dart';

class StudentSignupPage
    extends StatefulWidget {

  const StudentSignupPage({
    super.key,
  });

  @override
  State<StudentSignupPage>
  createState() =>
      _StudentSignupPageState();
}

class _StudentSignupPageState
    extends State<StudentSignupPage> {

  bool obscurePassword = true;

  final TextEditingController
  nameController =
  TextEditingController();

  final TextEditingController
  rollController =
  TextEditingController();

  final TextEditingController
  emailController =
  TextEditingController();

  final TextEditingController
  passwordController =
  TextEditingController();

  final TextEditingController
  departmentController =
  TextEditingController();

  final TextEditingController
  yearController =
  TextEditingController();



  final TextEditingController
  sectionController =
  TextEditingController();

  @override
  Widget build(
      BuildContext context) {

    final bool isDark =
        Theme.of(context)
            .brightness ==
            Brightness.dark;

    return Scaffold(

      backgroundColor:
      isDark
          ? const Color(
        0xFF081120,
      )
          : const Color(
        0xFFF4F8FC,
      ),

      body: SafeArea(

        child:
        SingleChildScrollView(

          child: Column(

            children: [

              Container(

                width:
                double.infinity,

                height: 260,

                decoration:
                const BoxDecoration(

                  gradient:
                  LinearGradient(

                    colors: [

                      Color(
                        0xFF005BEA,
                      ),

                      Color(
                        0xFF00C6FB,
                      ),
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
                  const EdgeInsets
                      .all(24),

                  child: Column(

                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      GestureDetector(

                        onTap: () {

                          Navigator.pop(
                            context,
                          );
                        },

                        child:
                        const CircleAvatar(

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

                        "Student Sign Up",

                        style: TextStyle(

                          fontSize:
                          34,

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

                        "Create your student account",

                        style: TextStyle(

                          fontSize:
                          16,

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
                const Offset(
                  0,
                  -30,
                ),

                child: Padding(

                  padding:
                  const EdgeInsets.symmetric(
                    horizontal:
                    20,
                  ),

                  child:
                  ClipRRect(

                    borderRadius:
                    BorderRadius.circular(
                      30,
                    ),

                    child:
                    BackdropFilter(

                      filter:
                      ImageFilter.blur(
                        sigmaX: 20,
                        sigmaY: 20,
                      ),

                      child:
                      Container(

                        padding:
                        const EdgeInsets.all(
                          24,
                        ),

                        decoration:
                        BoxDecoration(

                          color:
                          isDark

                              ? Colors.white
                              .withOpacity(.08)

                              : Colors.white
                              .withOpacity(.35),

                          borderRadius:
                          BorderRadius.circular(
                            30,
                          ),
                        ),

                        child:
                        Column(

                          children: [

                            buildField(
                              nameController,
                              "Full Name",
                              Icons.person,
                              isDark,
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            buildField(
                              rollController,
                              "Roll Number",
                              Icons.badge,
                              isDark,
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            buildField(
                              emailController,
                              "Email",
                              Icons.email,
                              isDark,
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            buildField(
                              departmentController,
                              "Department",
                              Icons.school,
                              isDark,
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            buildField(
                              yearController,
                              "Year",
                              Icons.calendar_today,
                              isDark,
                            ),

                            const SizedBox(
                              height: 20,
                            ),



                            buildField(
                              sectionController,
                              "Section",
                              Icons.group,
                              isDark,
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
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),

                                  onPressed:
                                      () {

                                    setState(() {

                                      obscurePassword =
                                      !obscurePassword;
                                    });
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

                              height:
                              58,

                              child:
                              ElevatedButton(

                                onPressed:
                                    () async {

                                  try {

                                    UserCredential user =

                                    await FirebaseAuth
                                        .instance

                                        .createUserWithEmailAndPassword(

                                      email:
                                      emailController.text.trim(),

                                      password:
                                      passwordController.text.trim(),
                                    );

                                    await FirebaseFirestore
                                        .instance

                                        .collection(
                                      "users",
                                    )

                                        .doc(
                                      user.user!.uid,
                                    )

                                        .set({

                                      "name":
                                      nameController.text,

                                      "rollNumber":
                                      rollController.text,

                                      "department":
                                      departmentController.text,

                                      "year":
                                      yearController.text.trim(),





                                      "section":
                                      sectionController.text.trim(),

                                      "email":
                                      emailController.text,

                                      "semester":
                                      1,

                                      "cgpa":
                                      0.0,

                                      "attendance":
                                      0.0,

                                      "totalClasses":
                                      0,

                                      "attendedClasses":
                                      0,

                                      "feesDue":
                                      0.0,

                                      "role":
                                      "student",

                                      "biometricEnabled":
                                      false,

                                    });

                                    Navigator.pushReplacement(

                                      context,

                                      MaterialPageRoute(

                                        builder:
                                            (_) =>
                                        const StudentMainNavigation(),
                                      ),
                                    );

                                  } catch (e) {

                                    ScaffoldMessenger.of(
                                        context)

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
                                  "Create Account",
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
      TextEditingController controller,
      String hint,
      IconData icon,
      bool isDark) {

    return TextField(

      controller:
      controller,

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
      bool isDark) {

    return InputDecoration(

      hintText: hint,

      prefixIcon:
      Icon(icon),

      filled: true,

      fillColor:

      isDark

          ? Colors.white
          .withOpacity(.08)

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