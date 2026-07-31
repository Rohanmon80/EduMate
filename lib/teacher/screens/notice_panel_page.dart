import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
class TeacherNoticePage
    extends StatefulWidget {

  const TeacherNoticePage({
    super.key,
  });

  @override
  State<TeacherNoticePage>
  createState() =>
      _TeacherNoticePageState();
}

class _TeacherNoticePageState
    extends State<TeacherNoticePage> {

  final TextEditingController
  titleController =
  TextEditingController();

  final TextEditingController
  descriptionController =
  TextEditingController();

  String selectedYear =
      "1st";

  String selectedDepartment =
      "CSE";

  String selectedSemester = "1";

  String selectedSection = "A";

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(

      appBar: AppBar(
        title:
        const Text("Notice Panel"),
      ),

      body: SingleChildScrollView(

        padding:
        const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            TextField(
              controller:
              titleController,

              decoration:
              const InputDecoration(
                labelText:
                "Notice Title",
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller:
              descriptionController,

              maxLines: 5,

              decoration:
              const InputDecoration(
                labelText:
                "Notice Description",
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Select Year",
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            DropdownButton<String>(

              value: selectedYear,

              isExpanded:true,

              items:[

                "1st",
                "2nd",
                "3rd",
                "4th"

              ]

                  .map(

                    (year)=>

                    DropdownMenuItem(

                      value:year,

                      child:
                      Text(year),
                    ),
              )

                  .toList(),

              onChanged:(v){

                setState(() {

                  selectedYear = v!;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Select Department",
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            DropdownButton<String>(

              value:
              selectedDepartment,

              isExpanded: true,

              items: [

                "CSE",
                "AIML",
                "CSM",
                "ECE",
                "EEE"
              ]
                  .map(
                    (dept) =>
                    DropdownMenuItem(
                      value: dept,
                      child:
                      Text(dept),
                    ),
              )
                  .toList(),

              onChanged: (value) {

                setState(() {

                  selectedDepartment =
                  value!;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Select Section",
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            DropdownButton<String>(

              value:
              selectedSection,

              isExpanded: true,

              items: [
                "A",
                "B",
                "C",
                "D"
              ]
                  .map(
                    (section) =>
                    DropdownMenuItem(
                      value:
                      section,
                      child:
                      Text(section),
                    ),
              )
                  .toList(),

              onChanged: (value) {

                setState(() {

                  selectedSection =
                  value!;


                  });
                  },
                  ),


            const SizedBox(
              height:20,
            ),

            const Text(

              "Select Semester",

              style:
              TextStyle(

                fontSize:18,

                fontWeight:
                FontWeight.bold,
              ),
            ),

            DropdownButton<String>(

              value:
              selectedSemester,

              isExpanded:true,

              items:[

                "1",
                "2",
                "3",
                "4",
                "5",
                "6",
                "7",
                "8"

              ]

                  .map(

                    (e)=>

                    DropdownMenuItem(

                      value:e,

                      child:
                      Text(e),
                    ),
              )

                  .toList(),

              onChanged:(v){

                setState(() {

                  selectedSemester = v!;
                });
              },
            ),

            const SizedBox(height: 40),

            SizedBox(

              width:
              double.infinity,

              height: 55,

              child: ElevatedButton(

                onPressed: () async {

                  await FirebaseFirestore
                      .instance

                      .collection(
                    "notices",
                  )

                      .add({

                    "title":

                    titleController.text,

                    "description":

                    descriptionController.text,

                    "year": selectedYear,

                    "department":

                    selectedDepartment,

                    "semester":

                    int.parse(
                      selectedSemester,
                    ),

                    "section":

                    selectedSection,

                    "teacherId":

                    FirebaseAuth
                        .instance
                        .currentUser!
                        .uid,

                    "sender":
                    "Teacher",

                    "pinned":
                    false,

                    "date":

                    Timestamp.now(),
                  });

                  if(
                  mounted
                  ){

                    ScaffoldMessenger.of(
                      context,
                    )

                        .showSnackBar(

                      const SnackBar(

                        content:

                        Text(
                          "Notice Sent Successfully",
                        ),
                      ),
                    );
                  }

                  titleController.clear();

                  descriptionController.clear();
                },

                child: const Text(
                  "Send Notice",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}