import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Parse().initialize(
    'HT78ysZ1ETIqnI3cAUy8HclIhO79XxC5wKjac6Mg',
    'https://parseapi.back4app.com',
    clientKey: 'Rsw3rC4oNczXm3UGKUCo0B3NNbQdIOW7r9s4tK8M',
    autoSendSessionId: true,
    debug: false,
  );

  runApp(MyApp());
}

class Task extends ParseObject {
  Task() : super('Task');

  Task.clone() : this();

  @override
  Task clone(Map<String, dynamic> map) => Task.clone()..fromJson(map);

  String? get name => get<String>('name');
  set name(String? value) => set<String>('name', value ?? '');

  String? get description => get<String>('description');
  set description(String? value) => set<String>('description', value ?? '');

  bool? get isCompleted => get<bool>('isCompleted');
  set isCompleted(bool? value) => set<bool>('isCompleted', value ?? false);
}




class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Back4App ToDo',
      home: ToDoScreen(),
    );
  }
}

class ToDoScreen extends StatefulWidget {
  @override
  _ToDoScreenState createState() => _ToDoScreenState();
}

class _ToDoScreenState extends State<ToDoScreen> {
  TextEditingController _taskController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  void _openEditTaskScreen(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(task: task),
      ),
    ).then((result) {
      if (result == true) {
        // Task was updated, refresh the task list
        _fetchTasks();
      }
    });
  }

  Future<void> _fetchTasks() async {
  final QueryBuilder<Task> queryBuilder = QueryBuilder<Task>(Task())
    ..orderByDescending('createdAt');

  final ParseResponse? result = await queryBuilder.query();

  if (result?.success == true && result?.results != null) {
    final List<Task> results = result!.results!.cast<Task>();
    setState(() {
      tasks = results;
    });
  } else {
    print('Error fetching tasks: ${result?.error?.message}');
  }
}




  Future<void> _addTask(String name, String description) async {
  final Task newTask = Task()
    ..name = name
    ..description = description;

  await newTask.save();

  _taskController.clear();
  _descriptionController.clear();
  _fetchTasks();
}

  Future<void> _toggleTaskCompletion(Task task) async {
  task.isCompleted = !(task.isCompleted ?? false) as bool;

  await task.save();

  await _fetchTasks(); // Wait for the task update to complete
}


  Future<void> _deleteTask(Task task) async {
  await task.delete();

  await _fetchTasks(); // Wait for the task deletion to complete
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToDo App'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ... (previous widgets remain unchanged)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _taskController,
                        decoration: InputDecoration(
                          hintText: 'Enter task name',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: 'Enter task description',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_taskController.text.isNotEmpty &&
                            _descriptionController.text.isNotEmpty) {
                          _addTask(
                              _taskController.text, _descriptionController.text);
                        }
                      },
                      child: Text('Add'),
                    ),
                    
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskTile(
                  task: task,
                  onCheckboxChanged: (bool? value) {
                    _toggleTaskCompletion(task);
                  },
                  onDeletePressed: () {
                    _deleteTask(task);
                  },
                  onEditPressed: () {
                    _openEditTaskScreen(context, task);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


//task in the form of tiles
class TaskTile extends StatelessWidget {
  final Task task;
  final Function(bool?) onCheckboxChanged;
  final VoidCallback onDeletePressed;
  final VoidCallback onEditPressed;

  TaskTile({
    required this.task,
    required this.onCheckboxChanged,
    required this.onDeletePressed,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: task.isCompleted == true
            ? Icon(Icons.check, color: Colors.green)
            : Icon(Icons.pending, color: Colors.orange), // Use your pending icon
        title: Text(
          task.name ?? '',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            decoration: task.isCompleted == true
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.description ?? '',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              'Created on ${DateFormat.yMMMd().format(task.createdAt!)}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: onEditPressed,
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: onDeletePressed,
            ),
            Checkbox(
              value: task.isCompleted ?? false,
              onChanged: onCheckboxChanged,
            ),
          ],
        ),
        onLongPress: onDeletePressed,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailsScreen(task: task),
            ),
          );
        },// Enable editing on tap as well
      ),
     
        
    
   
    );
  }
}



class EditTaskScreen extends StatefulWidget {
  final Task task;

  EditTaskScreen({required this.task});

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();

  void _openEditTaskScreen(BuildContext context, Task task) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditTaskScreen(task: task),
    ),
  );
}

}

class _EditTaskScreenState extends State<EditTaskScreen> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.task.name ?? '';
    _descriptionController.text = widget.task.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Name:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter task name',
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Task Description:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Enter task description',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _updateTask();
              },
              child: Text('Update Task'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateTask() async {
    widget.task.name = _nameController.text;
    widget.task.description = _descriptionController.text;
    await widget.task.save();
    Navigator.pop(context, true); // Pass true to indicate task was updated
  }
}

class TaskDetailsScreen extends StatelessWidget {
  final Task task;

  TaskDetailsScreen({required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Name:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              task.name ?? '',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Text(
              'Task Description:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              task.description ?? '',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Created on ${DateFormat.yMMMd().format(task.createdAt!)}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}


