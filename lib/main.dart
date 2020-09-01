import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.light,
      darkTheme: ThemeData.dark(),
      theme: ThemeData(
        primarySwatch: Colors.purple,
        // accentColor: Colors.yellow
      ),
      // darkTheme: ,
      // theme: ThemeData(
      //   primarySwatch: Colors.blue,
      //   visualDensity: VisualDensity.adaptivePlatformDensity,
      // ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final db = FirebaseFirestore.instance;
  String task = '';
  final GlobalKey<ScaffoldState> _scaffoldkey = new GlobalKey<ScaffoldState>();

  void showdialog({String id: ""}) async {
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: id.isEmpty ? Text("Add Item") : Text("Update item"),
          content: Form(
            key: formKey,
            autovalidate: true,
            child: TextFormField(
              initialValue: task.isEmpty ? '' : task,
              onChanged: (value) => task = value,
              autofocus: true,
              validator: (val) {
                if (val.isEmpty) {
                  return "can't be empty";
                } else {
                  return null;
                }
              },
              decoration: InputDecoration(hintText: "Add Here"),
            ),
          ),
          actions: [
            RaisedButton(
              onPressed: () {
                formKey.currentState.validate();
                if (id.isNotEmpty) {
                  db
                      .collection('todos')
                      .doc(id)
                      .update({'task': task}).then((value) {
                    Navigator.pop(context);
                    _scaffoldkey.currentState
                        .showSnackBar(SnackBar(content: Text("updated")));
                  });
                } else {
                  db.collection('todos').add({'task': task}).then((value) {
                    Navigator.pop(context);
                    _scaffoldkey.currentState
                        .showSnackBar(SnackBar(content: Text("added")));
                  });
                }
              },
              child: id.isEmpty ? Text("Add") : Text("Update"),
              color: Colors.amberAccent,
            ),
          ],
        );
      },
    ).whenComplete(() => task = "");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldkey,
      appBar: AppBar(
        title: Text("TODO"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('todos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  return Dismissible(
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      db
                          .collection('todos')
                          .doc(ds.id)
                          .delete()
                          .then((value) => print("done"))
                          .catchError((onError) => print(onError));
                      print(ds.id);
                    },
                    key: ObjectKey(ds.id),
                    background: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.red),
                    ),
                    child: ListTile(
                      title: Text(ds.data()['task']),
                      onTap: () {
                        task = ds.data()['task'];
                        showdialog(id: ds.id);
                      },
                    ),
                  );
                },
                itemCount: snapshot.data.docs.length);
          } else if (snapshot.hasError) {
            return Text("Error");
          } else if (snapshot.connectionState != null) {
            return CircularProgressIndicator();
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showdialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
