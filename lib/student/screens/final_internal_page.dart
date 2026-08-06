import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FinalInternalPage extends StatefulWidget {
  const FinalInternalPage({super.key});

  @override
  State<FinalInternalPage> createState() =>
      _FinalInternalPageState();
}

class _FinalInternalPageState
    extends State<FinalInternalPage> {

  int? semester;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Final Internal Marks"),
      ),

      body: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          children: [

            DropdownButtonFormField<int>(

              value: semester,

              decoration: const InputDecoration(

                labelText: "Select Semester",

                border: OutlineInputBorder(),

              ),

              items: List.generate(

                8,

                    (i)=>DropdownMenuItem(

                  value: i+1,

                  child: Text(
                    "Semester ${i+1}",
                  ),

                ),

              ),

              onChanged: (v){

                setState(() {

                  semester=v;

                });

              },

            ),

            const SizedBox(height:20),

            if(semester==null)

              const Expanded(

                child: Center(

                  child: Text(
                    "Select Semester",
                  ),

                ),

              )

            else

              Expanded(

                child: StreamBuilder<QuerySnapshot>(

                  stream: FirebaseFirestore.instance

                      .collection("student_marks")

                      .where(
                    "studentId",
                    isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                  )

                      .where(
                    "semester",
                    isEqualTo: semester,
                  )

                      .where(
                    "released",
                    isEqualTo: true,
                  )

                      .snapshots(),

                  builder: (context,snapshot){

                    if(!snapshot.hasData){

                      return const Center(
                        child:
                        CircularProgressIndicator(),
                      );

                    }

                    final docs =
                        snapshot.data!.docs;

                    if(docs.isEmpty){

                      return const Center(
                        child:
                        Text("No Results Released"),
                      );

                    }

                    Map<String,List<Map<String,dynamic>>> grouped={};

                    for(final d in docs){

                      final data=
                      d.data()
                      as Map<String,dynamic>;

                      grouped.putIfAbsent(
                        data["subjectCode"],
                            ()=>[],
                      );

                      grouped[data["subjectCode"]]!
                          .add(data);

                    }

                    return ListView(

                      children:

                      grouped.entries.map((entry){

                        final list=entry.value;

                        final first=list.first;

                        double internal1=0;

                        double internal2=0;

                        bool isTheory=
                            first["subjectType"]=="Theory";

                        for(final item in list){

                          if(item["exam"]=="Mid 1"){

                            internal1=
                                (item["marks"] as num)
                                    .toDouble();

                          }

                          if(item["exam"]=="Mid 2"){

                            internal2=
                                (item["marks"] as num)
                                    .toDouble();

                          }

                          if(item["exam"]=="Lab Internal 1"){

                            internal1=
                                (item["marks"] as num)
                                    .toDouble();

                          }

                          if(item["exam"]=="Lab Internal 2"){

                            internal2=
                                (item["marks"] as num)
                                    .toDouble();

                          }

                        }

                        final average=
                            (internal1+internal2)/2;

                        final pass=
                            average>=14;

                        return Card(

                          margin:
                          const EdgeInsets.only(
                            bottom:15,
                          ),

                          elevation:4,

                          shape:
                          RoundedRectangleBorder(

                            borderRadius:
                            BorderRadius.circular(15),

                          ),

                          child: Padding(

                            padding:
                            const EdgeInsets.all(16),

                            child: Column(

                              crossAxisAlignment:
                              CrossAxisAlignment.start,

                              children:[

                                Text(

                                  first["subjectName"],

                                  style:
                                  const TextStyle(

                                    fontSize:20,

                                    fontWeight:
                                    FontWeight.bold,

                                  ),

                                ),

                                const SizedBox(height:10),

                                Text(
                                  "Subject Code : ${first["subjectCode"]}",
                                ),

                                Text(
                                  "Type : ${first["subjectType"]}",
                                ),

                                const Divider(),

                                Text(
                                  isTheory
                                      ? "Mid 1 : $internal1"
                                      : "Internal 1 : $internal1",
                                ),

                                Text(
                                  isTheory
                                      ? "Mid 2 : $internal2"
                                      : "Internal 2 : $internal2",
                                ),

                                const SizedBox(height:10),

                                Text(
                                  "Average : ${average.toStringAsFixed(1)}",
                                  style:
                                  const TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height:8),

                                Text(

                                  pass
                                      ? "PASS"
                                      : "FAIL",

                                  style: TextStyle(

                                    color:
                                    pass
                                        ? Colors.green
                                        : Colors.red,

                                    fontWeight:
                                    FontWeight.bold,

                                    fontSize:18,

                                  ),

                                ),

                              ],

                            ),

                          ),

                        );

                      }).toList(),

                    );

                  },

                ),

              ),

          ],

        ),

      ),

    );

  }

}