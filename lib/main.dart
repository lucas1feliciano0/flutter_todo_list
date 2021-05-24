import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _todoList = [];

  final _formKey = GlobalKey<FormState>();

  late Map<String, dynamic> _lastRemoved;

  @override
  void initState() {
    super.initState();
    FlutterStatusbarcolor.setStatusBarColor(Colors.transparent);

    _readData().then((value) {
      setState(() {
        _todoList = json.decode(value);
      });
    });
  }

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/data.json");
  }

  Future<File> _saveData() async {
    String jsonData = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(jsonData);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      print(e);
      return 'Erro ao ler dados.';
    }
  }

  Icon _getIcon(task) {
    IconData icon;
    if (task["value"]) {
      icon = Icons.check;
    } else {
      if (task["isPriority"]) {
        icon = Icons.flag;
      } else {
        icon = Icons.label;
      }
    }

    return Icon(icon, color: Colors.white);
  }

  Widget buildList(context) {
    if (_todoList.length > 0) {
      return ListView.builder(
        padding: EdgeInsets.only(top: 10),
        itemCount: _todoList.length,
        itemBuilder: buildItem,
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Lottie.asset('animations/empty.json', width: 250),
            Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text(
                'Você não tem nenhuma tarefa',
                style: GoogleFonts.koHo(
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            )
          ],
        ),
      );
    }
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key('$index ${DateTime.now()}'),
      onDismissed: (d) => removeTodo(index),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      child: CheckboxListTile(
        activeColor: Color(0xFFfc8907),
        title: Text(
          _todoList[index]["title"],
          style: GoogleFonts.koHo(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            decoration: _todoList[index]["value"]
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: Text(
          _todoList[index]["description"],
          style: GoogleFonts.koHo(
            decoration: _todoList[index]["value"]
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        value: _todoList[index]["value"],
        onChanged: (newValue) {
          setState(() {
            _todoList[index]["value"] = newValue;
            _saveData();
          });
        },
        secondary: CircleAvatar(
          backgroundColor: Color(0xFFfc8907),
          child: _getIcon(_todoList[index]),
        ),
      ),
      direction: DismissDirection.startToEnd,
    );
  }

  void _addTodo(String title, String description, bool priority) {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tarefa adicionada com sucesso',
            style: GoogleFonts.koHo(),
          ),
        ),
      );

      setState(() {
        Map<String, dynamic> newTodo = Map();

        newTodo["title"] = title;
        newTodo["description"] = description;

        newTodo["value"] = false;
        newTodo["isPriority"] = priority;

        _todoList.add(newTodo);
        _saveData();
      });
    }
  }

  void removeTodo(index) {
    setState(() {
      _lastRemoved = _todoList[index];
      _todoList.removeAt(index);
      _saveData();

      final snack = SnackBar(
        content:
            Text('Tarefa \"${_lastRemoved["title"]}" removida com sucesso.'),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: "Desfazer",
          onPressed: () {
            setState(() {
              _todoList.insert(index, _lastRemoved);
              _saveData();
            });
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(snack);
    });
  }

  Future<Null> refreshItems() async {
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _todoList.sort((a, b) {
        if (a["isPriority"] && !a["value"] && !b["isPriority"]) {
          return 1;
        } else if (!a["isPriority"] && b["isPriority"] && !b["value"]) {
          return -1;
        } else {
          if (a["value"] && !b["value"])
            return 1;
          else if (!a["value"] && b["value"])
            return -1;
          else
            return 0;
        }
      });
    });

    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lista de tarefas',
          style: GoogleFonts.koHo(
            textStyle: TextStyle(
              color: Color(0xFFfc8907),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFfc8907),
        onPressed: () {
          showBarModalBottomSheet(
            context: context,
            builder: (context) => SingleChildScrollView(
                controller: ModalScrollController.of(context),
                child: AnimatedPadding(
                  duration: Duration(milliseconds: 250),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 20,
                        ),
                        child: CreateTodoModal(
                          addTodo: _addTodo,
                          formKey: _formKey,
                        ),
                      )
                    ],
                  ),
                )),
          );
        },
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: RefreshIndicator(
                edgeOffset: 5,
                displacement: 10,
                onRefresh: refreshItems,
                child: buildList(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget textField(
  context,
  String label,
  String hint,
  TextEditingController controller,
) {
  return Padding(
    padding: EdgeInsets.only(bottom: 30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Text(
            label,
            style: GoogleFonts.koHo(
              color: Color(0xffaaaaba),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.koHo(
              color: Color(0xffaaaaba),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                width: 0,
                style: BorderStyle.none,
              ),
            ),
            filled: true,
            fillColor: Color(0xFFf5f6fa),
          ),
          validator: (value) {
            return (value!.isEmpty) ? 'Insira um valor' : null;
          },
        )
      ],
    ),
  );
}

class CreateTodoModal extends StatefulWidget {
  CreateTodoModal({this.addTodo, this.formKey}) : super();

  final addTodo;
  final formKey;

  @override
  _CreateTodoModalState createState() => _CreateTodoModalState();
}

class _CreateTodoModalState extends State<CreateTodoModal> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool isPriority = false;

  Widget buildCheckBox(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 30),
      child: Container(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: Icon(
                    Icons.flag,
                    color: isPriority ? Color(0xFFfc8907) : Colors.grey[400],
                  ),
                ),
                Text(
                  "É prioridade",
                  style: GoogleFonts.koHo(fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
          onTap: () {
            setState(() {
              print(!isPriority);
              isPriority = !isPriority;
            });
          },
        ),
      ),
    );
  }

  void submit() {
    widget.addTodo(
        _titleController.text, _descriptionController.text, isPriority);

    setState(() {
      _titleController.text = "";
      _descriptionController.text = "";
      isPriority = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Form(
            key: widget.formKey,
            child: Column(
              children: [
                textField(context, "Título", "Insira um título para a tarefa",
                    _titleController),
                textField(
                    context,
                    "Descrição",
                    "Insira uma descrição para a tarefa",
                    _descriptionController),
                buildCheckBox(context),
                RaisedButton(
                  onPressed: submit,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(80.0)),
                  padding: EdgeInsets.all(0.0),
                  child: Ink(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xffff570d), Color(0xffff8200)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30.0)),
                    child: Container(
                      constraints:
                          BoxConstraints(maxWidth: 250.0, minHeight: 50.0),
                      alignment: Alignment.center,
                      child: Text(
                        "Adicionar tarefa",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.koHo(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
