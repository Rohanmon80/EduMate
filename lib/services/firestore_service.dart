import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {

  final FirebaseFirestore db =
      FirebaseFirestore.instance;

  Future addStudent({



    required String name,

    required String roll,

    required String department,

    required String email,

    required String role,

  }) async {

    final uid =

        FirebaseAuth
            .instance
            .currentUser!
            .uid;

    await db

        .collection(
      "users",
    )

        .doc(uid)

        .set({



      "rollNumber":roll,

      "name":name,

      "department":department,

      "email":email,

      "role":role,

      "semester":1,

      "cgpa":0.0,

      "attendance":0,

      "phone":"",

      "section":"",

      "bio":"",

      "photoUrl":"",

      "studentBiometric":false,

      "totalFee":0,

      "paidFee":0,

      "feesDue":0,
    });
  }

  Future addTeacher({

    required String id,

    required String name,

    required String department,

    required String email,

    required String role,

  }) async {

    final uid =
        FirebaseAuth
            .instance
            .currentUser!
            .uid;

    await db

        .collection(
      "teachers",
    )

        .doc(uid)

        .set({

      "id":id,

      "name":name,

      "department":department,

      "email":email,

      "role":role,

      "experience":0,

      "phone":"",

      "bio":"",

      "photoUrl":"",

      "teacherBiometric":false,
    });
  }

  Future addAdmin({

    required String id,

    required String name,

    required String email,

    required String role,

  }) async {

    final uid =

        FirebaseAuth
            .instance
            .currentUser!
            .uid;

    await db

        .collection(
      "admins",
    )

        .doc(uid)

        .set({

      "id":id,

      "name":name,

      "email":email,

      "role":role,

      "phone":"",

      "bio":"",

      "photoUrl":"",

      "office":"",

      "adminBiometric":false,
    });
  }

  Future addNotice({

    required String title,

    required String message,

  }) async {

    await db
        .collection(
      "notices",
    )

        .add({

      "title":
      title,

      "message":
      message,

      "date":
      DateTime.now(),
    });
  }
}