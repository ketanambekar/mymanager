import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000/api/v1');
const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

class Api extends GetxService {
  final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
  String? token;

  Future<Api> init() async {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401 || error.requestOptions.extra['retry'] == true) {
          handler.next(error);
          return;
        }
        try {
          await refresh();
          error.requestOptions.extra['retry'] = true;
          handler.resolve(await dio.fetch(error.requestOptions));
        } catch (_) {
          handler.next(error);
        }
      },
    ));
    return this;
  }

  Future<void> refresh() async {
    final response = await dio.post('/auth/refresh');
    token = response.data['data']['accessToken'];
  }

  Future<Map<String, dynamic>> session() async => Map<String, dynamic>.from((await dio.get('/auth/session')).data['data']);

  Future<void> logout() async {
    await dio.post('/auth/logout');
    token = null;
  }
}

class SessionController extends GetxController {
  final api = Get.find<Api>();
  final user = Rxn<Map<String, dynamic>>();
  final loading = true.obs;
  final error = ''.obs;

  @override
  void onReady() {
    bootstrap();
    super.onReady();
  }

  Future<void> bootstrap() async {
    try {
      await api.refresh();
      user.value = await api.session();
    } catch (_) {
      user.value = null;
    } finally {
      loading.value = false;
    }
  }

  Future<void> signIn() async {
    loading.value = true;
    error.value = '';
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        throw Exception('Google sign-in is not implemented for Windows. Run this app on Chrome, Android, or iOS.');
      }
      if (googleClientId.isEmpty) throw Exception('Set GOOGLE_CLIENT_ID for native Google sign-in.');
      await GoogleSignIn.instance.initialize(serverClientId: googleClientId);
      final account = await GoogleSignIn.instance.authenticate();
      final credential = account.authentication.idToken;
      if (credential == null) throw Exception('Google did not return an ID token.');
      final response = await api.dio.post('/auth/google', data: {'credential': credential});
      api.token = response.data['data']['accessToken'];
      user.value = await api.session();
    } catch (exception) {
      error.value = exception.toString().replaceFirst('Exception: ', '');
    } finally {
      loading.value = false;
    }
  }
}

class DashboardController extends GetxController {
  final api = Get.find<Api>();
  final dashboard = Rxn<Map<String, dynamic>>();
  final loading = true.obs;
  final error = ''.obs;
  final filter = 'open'.obs;
  final search = ''.obs;
  final projectId = RxnInt();

  List<dynamic> get projects => dashboard.value?['projects'] ?? const [];
  List<dynamic> get tasks => [...(dashboard.value?['recentTasks'] ?? const []), ...(dashboard.value?['upcomingTasks'] ?? const [])];
  String get today => dashboard.value?['asOfDate'] ?? '';

  List<dynamic> get visibleTasks {
    final query = search.value.trim().toLowerCase();
    return tasks.where((task) {
      final due = task['dueDate'] as String?;
      final completed = task['completed'] == true;
      final matchesDate = due == null || due.compareTo(today) <= 0;
      final matchesFilter = filter.value == 'all' || (filter.value == 'open' && !completed) || (filter.value == 'completed' && completed);
      final matchesSearch = query.isEmpty || '${task['title']}'.toLowerCase().contains(query);
      final matchesProject = projectId.value == null || task['projectId'] == projectId.value;
      return matchesDate && matchesFilter && matchesSearch && matchesProject;
    }).toList();
  }

  @override
  void onReady() {
    load();
    super.onReady();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      dashboard.value = Map<String, dynamic>.from((await api.dio.get('/dashboard')).data['data']);
      error.value = '';
    } catch (exception) {
      error.value = exception.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> mutate(Future<void> Function() action) async {
    try {
      await action();
      await load();
      Get.snackbar('Saved', 'Your workspace was updated', snackPosition: SnackPosition.BOTTOM);
    } catch (exception) {
      Get.snackbar('Could not save', exception.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> toggleTask(Map<String, dynamic> task) => mutate(() => api.dio.post('/tasks/${task['id']}/${task['completed'] == true ? 'reopen' : 'complete'}', data: {'version': task['version']}));
  Future<void> deleteTask(Map<String, dynamic> task) => mutate(() => api.dio.delete('/tasks/${task['id']}'));
  Future<void> deleteProject(Map<String, dynamic> project) => mutate(() => api.dio.delete('/projects/${project['id']}'));
  Future<void> addSubtask(Map<String, dynamic> task, String title) => mutate(() => api.dio.post('/tasks/${task['id']}/subtasks', data: {'title': title}));
}

const darkSurface = Color(0xFF111613);
const lightSurface = Color(0xFFF2EFE7);
const sage = Color(0xFF79C99B);
const ember = Color(0xFFFB765B);
const quiet = Color(0xFFA2A798);

ThemeData makeTheme(Brightness brightness) => ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: brightness == Brightness.dark ? darkSurface : lightSurface,
      colorScheme: ColorScheme.fromSeed(seedColor: sage, brightness: brightness),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      cardTheme: CardThemeData(color: brightness == Brightness.dark ? Color(0xFF1B221D) : Color(0xFFFFFDF8)),
    );

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(await Api().init(), permanent: true);
  Get.put(SessionController(), permanent: true);
  Get.put(DashboardController(), permanent: true);
  runApp(const MyMangerApp());
}

class MyMangerApp extends StatelessWidget {
  const MyMangerApp({super.key});
  @override
  Widget build(BuildContext context) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MyManger',
        theme: makeTheme(Brightness.light),
        darkTheme: makeTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        home: const Gate(),
      );
}

class Gate extends StatelessWidget {
  const Gate({super.key});
  @override
  Widget build(BuildContext context) => Obx(() {
        final session = Get.find<SessionController>();
        if (session.loading.value) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return session.user.value == null ? const LoginPage() : const DashboardPage();
      });
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Obx(() => Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('MyManger', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Make room for better work.', style: TextStyle(color: quiet)),
                  const SizedBox(height: 32),
                  SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: session.loading.value ? null : session.signIn, icon: const Icon(Icons.login), label: const Text('Continue with Google'))),
                  if (session.error.value.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 16), child: Text(session.error.value, style: const TextStyle(color: ember))),
                ])),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final session = Get.find<SessionController>();
    return Scaffold(
      appBar: AppBar(title: const Text('MyManger'), actions: [IconButton(onPressed: session.api.logout, icon: const Icon(Icons.logout))]),
      floatingActionButton: FloatingActionButton(onPressed: () => showTaskDialog(context), child: const Icon(Icons.add)),
      body: Obx(() {
        if (controller.loading.value && controller.dashboard.value == null) return const Center(child: CircularProgressIndicator());
        if (controller.error.value.isNotEmpty && controller.dashboard.value == null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(controller.error.value), OutlinedButton(onPressed: controller.load, child: const Text('Retry'))]));
        return RefreshIndicator(onRefresh: controller.load, child: ListView(padding: const EdgeInsets.all(16), children: [SummaryPanel(controller.dashboard.value!), const SizedBox(height: 16), ProjectPanel(controller), const SizedBox(height: 16), TaskPanel(controller), const SizedBox(height: 80)]));
      }),
    );
  }
}

class SummaryPanel extends StatelessWidget {
  const SummaryPanel(this.data, {super.key});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final summary = data['summary'] as Map<String, dynamic>;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Wrap(spacing: 24, runSpacing: 12, children: [Text(DateFormat('EEE, d MMM').format(DateTime.now()), style: Theme.of(context).textTheme.titleMedium), metric('Overdue', summary['overdueCount'], ember), metric('Due today', summary['dueTodayCount'], sage), metric('Pending', summary['pendingTodayCount'], quiet), metric('Done today', summary['completedTodayCount'], sage), metric('Complete', summary['completionRate'], ember, '%')])));
  }
  Widget metric(String label, dynamic value, Color color, [String suffix = '']) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$value$suffix', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)), Text(label, style: const TextStyle(fontSize: 11, color: quiet))]);
}

class ProjectPanel extends StatelessWidget {
  const ProjectPanel(this.controller, {super.key});
  final DashboardController controller;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Your projects', style: Theme.of(context).textTheme.titleLarge), IconButton(onPressed: () => showProjectDialog(context), icon: const Icon(Icons.create_new_folder_outlined))]), ...controller.projects.where((project) => project['parentProjectId'] == null).map((project) => ListTile(onTap: () => controller.projectId.value = controller.projectId.value == project['id'] ? null : project['id'], selected: controller.projectId.value == project['id'], leading: CircleAvatar(backgroundColor: sage, child: Text('${project['progress'] ?? 0}%')), title: Text(project['name']), subtitle: Text('${project['completedCount'] ?? 0}/${project['taskCount'] ?? 0} tasks'), trailing: IconButton(onPressed: () => confirmDeleteProject(context, project), icon: const Icon(Icons.delete_outline))))])));
}

class TaskPanel extends StatelessWidget {
  const TaskPanel(this.controller, {super.key});
  final DashboardController controller;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [Row(children: [Expanded(child: Text('Task List', style: Theme.of(context).textTheme.titleLarge)), IconButton(onPressed: () => showTaskDialog(context), icon: const Icon(Icons.add_task))]), TextField(onChanged: (value) => controller.search.value = value, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search tasks')), const SizedBox(height: 10), Obx(() => SegmentedButton<String>(segments: const [ButtonSegment(value: 'all', label: Text('All')), ButtonSegment(value: 'open', label: Text('To do')), ButtonSegment(value: 'completed', label: Text('Done'))], selected: {controller.filter.value}, onSelectionChanged: (value) => controller.filter.value = value.first)), const SizedBox(height: 8), Obx(() => Column(children: controller.visibleTasks.map((task) => ExpansionTile(leading: IconButton(onPressed: () => controller.toggleTask(task), icon: Icon(task['completed'] == true ? Icons.check_circle : Icons.radio_button_unchecked, color: sage)), title: Text('${task['title']}', style: TextStyle(decoration: task['completed'] == true ? TextDecoration.lineThrough : null)), subtitle: Text('${task['dueDate'] ?? 'No due date'}  •  ${task['projectId'] == null ? 'General' : 'Project'}', style: const TextStyle(color: quiet, fontSize: 11)), trailing: IconButton(onPressed: () => confirmDeleteTask(context, task), icon: const Icon(Icons.delete_outline)), children: [TextButton.icon(onPressed: () => showSubtaskDialog(context, task), icon: const Icon(Icons.add, size: 16), label: const Text('Add subtask'))])).toList()))])));
}

Future<void> showTaskDialog(BuildContext context) async { final title = TextEditingController(); final controller = Get.find<DashboardController>(); await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Add a task'), content: TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'Task name')), actions: [TextButton(onPressed: Get.back, child: const Text('Cancel')), FilledButton(onPressed: () { Get.back(); controller.mutate(() => controller.api.dio.post('/tasks', data: {'title': title.text.trim(), 'projectId': controller.projectId.value, 'dueDate': controller.today, 'recurrence': {'frequency': 'one_time'}})); }, child: const Text('Create task'))])); }
Future<void> showProjectDialog(BuildContext context) async { final name = TextEditingController(); final controller = Get.find<DashboardController>(); await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Create a project'), content: TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Project name')), actions: [TextButton(onPressed: Get.back, child: const Text('Cancel')), FilledButton(onPressed: () { Get.back(); controller.mutate(() => controller.api.dio.post('/projects', data: {'name': name.text.trim(), 'color': '#C95B49', 'parentProjectId': null})); }, child: const Text('Create project'))])); }
Future<void> showSubtaskDialog(BuildContext context, Map<String, dynamic> task) async { final title = TextEditingController(); final controller = Get.find<DashboardController>(); await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Add a subtask'), content: TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'Subtask name')), actions: [TextButton(onPressed: Get.back, child: const Text('Cancel')), FilledButton(onPressed: () { Get.back(); controller.addSubtask(task, title.text.trim()); }, child: const Text('Add'))])); }
Future<void> confirmDeleteTask(BuildContext context, Map<String, dynamic> task) async { final controller = Get.find<DashboardController>(); final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Delete task?'), content: Text('${task['title']} will be permanently removed.'), actions: [TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')), FilledButton(onPressed: () => Get.back(result: true), child: const Text('Delete'))])); if (confirm == true) controller.deleteTask(task); }
Future<void> confirmDeleteProject(BuildContext context, Map<String, dynamic> project) async { final controller = Get.find<DashboardController>(); final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text('Delete ${project['name']}?'), content: const Text('Tasks move to the parent or General.'), actions: [TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')), FilledButton(onPressed: () => Get.back(result: true), child: const Text('Delete'))])); if (confirm == true) controller.deleteProject(project); }
