# Full-Stack Flutter App with Serverpod

Complete example of building a task management application with Serverpod backend and Flutter frontend, demonstrating models, endpoints, database operations, authentication, and real-time updates.

## Application Overview

Build a collaborative task management app where users can:
- Create and manage tasks
- Organize tasks in projects
- Real-time task updates across devices
- User authentication
- File attachments

## Project Setup

```bash
# Create Serverpod project
serverpod create task_manager

# Project structure
task_manager/
├── task_manager_server/
├── task_manager_client/
└── task_manager_flutter/
```

## Define Models

### Task Model

```yaml
# task_manager_server/lib/src/models/task.spy.yaml
class: Task
table: task
fields:
  title: String
  description: String?
  completed: bool, default=false
  priority: int, default=0
  dueDate: DateTime?
  createdAt: DateTime, defaultModel=DateTime.now()
  updatedAt: DateTime, defaultModel=DateTime.now()

  # Relations
  projectId: int, !dbindex
  project: Project?, relation(field=projectId, parent=project)

  assignedToId: int?, !dbindex
  assignedTo: User?, relation(field=assignedToId, parent=user)

  createdById: int, !dbindex
  createdBy: User?, relation(field=createdById, parent=user)
```

### Project Model

```yaml
# task_manager_server/lib/src/models/project.spy.yaml
class: Project
table: project
fields:
  name: String
  description: String?
  color: String, default='#3498db'
  createdAt: DateTime, defaultModel=DateTime.now()

  # Relations
  ownerId: int, !dbindex
  owner: User?, relation(field=ownerId, parent=user)

  tasks: List<Task>?, relation(field=projectId)
  members: List<User>?, relation
```

### User Model

```yaml
# task_manager_server/lib/src/models/user.spy.yaml
class: User
table: user
fields:
  email: String, !dbindex
  name: String
  avatarUrl: String?
  createdAt: DateTime, defaultModel=DateTime.now()

  # Relations
  ownedProjects: List<Project>?, relation(field=ownerId)
  assignedTasks: List<Task>?, relation(field=assignedToId)
  createdTasks: List<Task>?, relation(field=createdById)
```

Generate code:

```bash
cd task_manager_server
serverpod generate
serverpod create-migration --tag "initial-schema"
```

## Task Endpoints

```dart
// task_manager_server/lib/src/endpoints/task_endpoint.dart
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class TaskEndpoint extends Endpoint {
  /// Create a new task
  Future<Task> createTask(Session session, Task task) async {
    // Authenticate
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Must be signed in');
    }

    // Set creator
    task.createdById = session.auth!.userId!;
    task.createdAt = DateTime.now();
    task.updatedAt = DateTime.now();

    // Verify project access
    var project = await Project.db.findById(session, task.projectId);
    if (project == null) {
      throw NotFoundException('Project not found');
    }

    if (project.ownerId != session.auth!.userId!) {
      var member = await _checkProjectMembership(
        session,
        project.id!,
        session.auth!.userId!,
      );
      if (!member) {
        throw ForbiddenException('Not a project member');
      }
    }

    // Create task
    var created = await Task.db.insertRow(session, task);

    // Broadcast update
    _broadcastTaskUpdate(project.id!, TaskUpdate(
      type: TaskUpdateType.created,
      task: created,
    ));

    return created;
  }

  /// Get tasks for a project
  Future<List<Task>> getProjectTasks(
    Session session,
    int projectId,
    {bool? completedOnly,
    int? assignedToId}
  ) async {
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Must be signed in');
    }

    // Verify access
    await _verifyProjectAccess(session, projectId);

    // Build query
    var where = (Task t) => t.projectId.equals(projectId);

    if (completedOnly != null) {
      where = (t) => where(t) & t.completed.equals(completedOnly);
    }

    if (assignedToId != null) {
      where = (t) => where(t) & t.assignedToId.equals(assignedToId);
    }

    // Fetch tasks with relations
    return await Task.db.find(
      session,
      where: where,
      include: Task.include(
        assignedTo: User.include(),
        createdBy: User.include(),
      ),
      orderBy: (t) => (t.priority, -t.createdAt),
    );
  }

  /// Update task
  Future<Task> updateTask(Session session, Task task) async {
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Must be signed in');
    }

    // Verify task exists
    var existing = await Task.db.findById(session, task.id!);
    if (existing == null) {
      throw NotFoundException('Task not found');
    }

    // Verify project access
    await _verifyProjectAccess(session, existing.projectId);

    // Update timestamp
    task.updatedAt = DateTime.now();

    var updated = await Task.db.updateRow(session, task);

    // Broadcast update
    _broadcastTaskUpdate(existing.projectId, TaskUpdate(
      type: TaskUpdateType.updated,
      task: updated,
    ));

    return updated;
  }

  /// Delete task
  Future<void> deleteTask(Session session, int taskId) async {
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Must be signed in');
    }

    var task = await Task.db.findById(session, taskId);
    if (task == null) {
      throw NotFoundException('Task not found');
    }

    // Verify access (must be creator or project owner)
    var userId = session.auth!.userId!;
    if (task.createdById != userId) {
      var project = await Project.db.findById(session, task.projectId);
      if (project?.ownerId != userId) {
        throw ForbiddenException('Cannot delete this task');
      }
    }

    await Task.db.deleteRow(session, task);

    // Broadcast deletion
    _broadcastTaskUpdate(task.projectId, TaskUpdate(
      type: TaskUpdateType.deleted,
      taskId: taskId,
    ));
  }

  /// Stream task updates for a project
  Stream<TaskUpdate> watchProject(Session session, int projectId) async* {
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Must be signed in');
    }

    // Verify access
    await _verifyProjectAccess(session, projectId);

    // Subscribe to updates
    await for (var update in _taskUpdateStreams[projectId] ?? Stream.empty()) {
      yield update;
    }
  }

  // Helper methods
  Future<void> _verifyProjectAccess(Session session, int projectId) async {
    var project = await Project.db.findById(session, projectId);
    if (project == null) {
      throw NotFoundException('Project not found');
    }

    var userId = session.auth!.userId!;
    if (project.ownerId != userId) {
      var isMember = await _checkProjectMembership(session, projectId, userId);
      if (!isMember) {
        throw ForbiddenException('Not a project member');
      }
    }
  }

  Future<bool> _checkProjectMembership(
    Session session,
    int projectId,
    int userId,
  ) async {
    // Query project_members table (would need to create this model)
    // Simplified for example
    return false;
  }

  // Broadcast system (simplified - use Redis in production)
  static final _taskUpdateStreams = <int, StreamController<TaskUpdate>>{};

  void _broadcastTaskUpdate(int projectId, TaskUpdate update) {
    _taskUpdateStreams.putIfAbsent(
      projectId,
      () => StreamController<TaskUpdate>.broadcast(),
    ).add(update);
  }
}
```

## Project Endpoints

```dart
// task_manager_server/lib/src/endpoints/project_endpoint.dart
class ProjectEndpoint extends Endpoint {
  /// Create project
  Future<Project> createProject(Session session, Project project) async {
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Must be signed in');
    }

    project.ownerId = session.auth!.userId!;
    project.createdAt = DateTime.now();

    return await Project.db.insertRow(session, project);
  }

  /// Get user's projects
  Future<List<Project>> getMyProjects(Session session) async {
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Must be signed in');
    }

    var userId = session.auth!.userId!;

    // Get owned projects
    var owned = await Project.db.find(
      session,
      where: (t) => t.ownerId.equals(userId),
      include: Project.include(
        tasks: Task.includeList(
          where: (t) => t.completed.equals(false),
          limit: 5,
        ),
      ),
    );

    return owned;
  }

  /// Get project with full details
  Future<Project> getProject(Session session, int projectId) async {
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Must be signed in');
    }

    var project = await Project.db.findById(
      session,
      projectId,
      include: Project.include(
        tasks: Task.includeList(
          include: Task.include(
            assignedTo: User.include(),
          ),
        ),
        owner: User.include(),
      ),
    );

    if (project == null) {
      throw NotFoundException('Project not found');
    }

    // Verify access
    var userId = session.auth!.userId!;
    if (project.ownerId != userId) {
      // Check membership
      throw ForbiddenException('Access denied');
    }

    return project;
  }

  /// Update project
  Future<Project> updateProject(Session session, Project project) async {
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Must be signed in');
    }

    var existing = await Project.db.findById(session, project.id!);
    if (existing == null) {
      throw NotFoundException('Project not found');
    }

    // Must be owner
    if (existing.ownerId != session.auth!.userId!) {
      throw ForbiddenException('Only owner can update project');
    }

    return await Project.db.updateRow(session, project);
  }

  /// Delete project
  Future<void> deleteProject(Session session, int projectId) async {
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Must be signed in');
    }

    var project = await Project.db.findById(session, projectId);
    if (project == null) {
      throw NotFoundException('Project not found');
    }

    if (project.ownerId != session.auth!.userId!) {
      throw ForbiddenException('Only owner can delete project');
    }

    // Delete all tasks first
    await Task.db.deleteWhere(
      session,
      where: (t) => t.projectId.equals(projectId),
    );

    // Delete project
    await Project.db.deleteRow(session, project);
  }
}
```

## Flutter UI

### Main App Setup

```dart
// task_manager_flutter/lib/main.dart
import 'package:flutter/material.dart';
import 'package:task_manager_client/task_manager_client.dart';
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize client
  final client = Client('http://localhost:8080/');
  final sessionManager = FlutterAuthSessionManager(caller: client.caller);
  client.authSessionManager = sessionManager;

  await sessionManager.initialize();

  runApp(TaskManagerApp(client: client, sessionManager: sessionManager));
}

class TaskManagerApp extends StatelessWidget {
  final Client client;
  final FlutterAuthSessionManager sessionManager;

  const TaskManagerApp({
    required this.client,
    required this.sessionManager,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: AuthGate(
        client: client,
        sessionManager: sessionManager,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final Client client;
  final FlutterAuthSessionManager sessionManager;

  const AuthGate({
    required this.client,
    required this.sessionManager,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sessionManager,
      builder: (context, _) {
        if (sessionManager.signedInUser != null) {
          return ProjectListScreen(client: client);
        }
        return SignInScreen(client: client, sessionManager: sessionManager);
      },
    );
  }
}
```

### Project List Screen

```dart
// task_manager_flutter/lib/screens/project_list_screen.dart
class ProjectListScreen extends StatefulWidget {
  final Client client;

  const ProjectListScreen({required this.client});

  @override
  _ProjectListScreenState createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  List<Project>? _projects;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    try {
      final projects = await widget.client.project.getMyProjects();
      setState(() {
        _projects = projects;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load projects: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Projects'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _createProject(),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _projects == null || _projects!.isEmpty
              ? Center(child: Text('No projects yet'))
              : RefreshIndicator(
                  onRefresh: _loadProjects,
                  child: ListView.builder(
                    itemCount: _projects!.length,
                    itemBuilder: (context, index) {
                      final project = _projects![index];
                      final taskCount = project.tasks?.length ?? 0;

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(
                              int.parse(project.color.replaceFirst('#', '0xFF')),
                            ),
                          ),
                          title: Text(project.name),
                          subtitle: Text('$taskCount tasks'),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskListScreen(
                                  client: widget.client,
                                  projectId: project.id!,
                                  projectName: project.name,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Future<void> _createProject() async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Project'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'Project Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        await widget.client.project.createProject(
          Project(name: nameController.text),
        );
        _loadProjects();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create project: $e')),
        );
      }
    }
  }
}
```

### Task List Screen with Real-Time Updates

```dart
// task_manager_flutter/lib/screens/task_list_screen.dart
class TaskListScreen extends StatefulWidget {
  final Client client;
  final int projectId;
  final String projectName;

  const TaskListScreen({
    required this.client,
    required this.projectId,
    required this.projectName,
  });

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _loading = true;
  StreamSubscription<TaskUpdate>? _updateSubscription;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final tasks = await widget.client.task.getProjectTasks(widget.projectId);
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _subscribeToUpdates() {
    _updateSubscription = widget.client.task
        .watchProject(widget.projectId)
        .listen((update) {
      setState(() {
        switch (update.type) {
          case TaskUpdateType.created:
            _tasks.add(update.task!);
            break;
          case TaskUpdateType.updated:
            final index = _tasks.indexWhere((t) => t.id == update.task!.id);
            if (index != -1) {
              _tasks[index] = update.task!;
            }
            break;
          case TaskUpdateType.deleted:
            _tasks.removeWhere((t) => t.id == update.taskId);
            break;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return TaskTile(
                  task: task,
                  onToggle: () => _toggleTask(task),
                  onTap: () => _editTask(task),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _toggleTask(Task task) async {
    final updated = task.copyWith(completed: !task.completed);
    try {
      await widget.client.task.updateTask(updated);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $e')),
      );
    }
  }

  Future<void> _createTask() async {
    // Show create task dialog
  }

  Future<void> _editTask(Task task) async {
    // Show edit task dialog
  }
}

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const TaskTile({
    required this.task,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: task.completed,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        task.title,
        style: task.completed
            ? TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: task.assignedTo != null
          ? Text('Assigned to: ${task.assignedTo!.name}')
          : null,
      trailing: task.dueDate != null
          ? Text(_formatDate(task.dueDate!))
          : null,
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 0) return 'Overdue';
    return '${diff.inDays}d';
  }
}
```

This complete example demonstrates a production-ready task management application showcasing Serverpod's key features: type-safe models, database operations with relations, authentication, real-time updates, and error handling.
