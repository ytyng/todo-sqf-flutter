import 'package:flutter/material.dart';

import 'models.dart';

void main() async {
  final bool isInitialized = await TodoDbModel().initializeDB();
  if (isInitialized == true) {
    runApp(MyApp());
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Todo App',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: MyScaffold(),
      );
}

class MyScaffold extends StatelessWidget {
  final todoWidgetKey = GlobalKey<_TodoState>();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Todo'),
        ),
        body: TodoWidget(key: todoWidgetKey),
        floatingActionButton: Builder(builder: (BuildContext context) {
          return FloatingActionButton(
            onPressed: () async {
              await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return EditDialog(
                      todoWidgetKey: todoWidgetKey,
                    );
                  });
            },
            child: Icon(Icons.add),
          );
        }),
      );
}

class TodoWidget extends StatefulWidget {
  const TodoWidget({
    Key key,
  }) : super(key: key);

  @override
  _TodoState createState() => _TodoState();
}

class _TodoState extends State<TodoWidget> {
  void update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Todo().select().orderByDesc('id').toList(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return ListView(
              children: snapshot.data.map<Widget>((Todo item) {
                return GestureDetector(
                  onTap: () async {
                    await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return EditDialog(
                            title: item.title,
                            todoId: item.id,
                            todoWidgetKey: widget.key,
                          );
                        });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                          bottom:
                              BorderSide(width: 1.0, color: Colors.black26)),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Text(item.title),
                  ),
                );
              }).toList(),
            );
          } else {
            return Text('wait');
          }
        });
  }
}

class EditDialog extends StatefulWidget {
  final int todoId;
  final String title;
  final GlobalKey<_TodoState> todoWidgetKey;
  final List<Widget> children;

  const EditDialog({
    Key key,
    this.todoId,
    this.title,
    this.todoWidgetKey,
    this.children,
  }) : super(key: key);

  @override
  _EditDialogState createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  final textEditingController = TextEditingController();

  @override
  initState() {
    super.initState();
    if (widget.title != null) {
      textEditingController.text = widget.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      TextField(
        controller: textEditingController,
        autofocus: widget.todoId == null,
        decoration: InputDecoration(
          labelText: 'Task?',
        ),
      ),
      ...widget.todoId == null
          ? buttonsForCreate(context)
          : buttonsForUpdate(context)
    ]));
  }

  List<Widget> buttonsForCreate(BuildContext context) => <Widget>[
        buildButton(
            context: context,
            labelText: '登録',
            onPressed: () {
              if (textEditingController.text.length > 0) {
                Todo(title: textEditingController.text, active: true).save();
                widget.todoWidgetKey.currentState.update();
              }
              Navigator.of(context).pop();
            })
      ];

  List<Widget> buttonsForUpdate(BuildContext context) => <Widget>[
        buildButton(
            context: context,
            labelText: '更新',
            onPressed: () {
              if (textEditingController.text.length > 0) {
                Todo(
                        id: widget.todoId,
                        title: textEditingController.text,
                        active: true)
                    .save();
                widget.todoWidgetKey.currentState.update();
              }
              Navigator.of(context).pop();
            }),
        buildButton(
            context: context,
            labelText: '消去',
            buttonColor: Colors.red,
            onPressed: () {
              Todo().select().id.equals(widget.todoId).delete();
              widget.todoWidgetKey.currentState.update();
              Navigator.of(context).pop();
            })
      ];
}

Widget buildButton(
    {BuildContext context,
    String labelText,
    VoidCallback onPressed,
    Color buttonColor}) {
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: ButtonTheme(
      minWidth: double.infinity,
      height: 50,
      child: RaisedButton(
        color: buttonColor ?? Theme.of(context).primaryColor,
        onPressed: onPressed,
        child: Text(labelText, style: TextStyle(color: Colors.white)),
      ),
    ),
  );
}
