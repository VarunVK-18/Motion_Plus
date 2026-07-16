import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReminderTask {
  final String id;
  final String title;
  final String category;
  bool isCompleted;

  ReminderTask({
    required this.id,
    required this.title,
    required this.category,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'isCompleted': isCompleted,
  };

  factory ReminderTask.fromJson(Map<String, dynamic> json) => ReminderTask(
    id: json['id'],
    title: json['title'],
    category: json['category'],
    isCompleted: json['isCompleted'],
  );
}

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<ReminderTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('saved_tasks_list');
    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      setState(() {
        _tasks = decoded.map((item) => ReminderTask.fromJson(item)).toList();
      });
    } else {
      // Default tasks for first time
      setState(() {
        _tasks = [
          ReminderTask(
            id: '1',
            title: 'Morning Pain Meds',
            category: 'Medication',
          ),
          ReminderTask(
            id: '2',
            title: 'Shoulder Rotations (10 reps)',
            category: 'Exercise',
          ),
          ReminderTask(
            id: '3',
            title: 'Drink 500ml Water',
            category: 'General',
          ),
        ];
      });
      _saveTasks();
    }
    _updateDashboardCount();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString('saved_tasks_list', encoded);
    _updateDashboardCount();
  }

  Future<void> _updateDashboardCount() async {
    final prefs = await SharedPreferences.getInstance();
    int pendingCount = _tasks.where((t) => !t.isCompleted).length;
    await prefs.setInt('pending_reminders', pendingCount);
  }

  String _selectedCategory = 'All';

  double get _completionRate {
    if (_tasks.isEmpty) return 0;
    return _tasks.where((t) => t.isCompleted).length / _tasks.length;
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    String selectedCategory = 'General';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'New Reminder',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Category',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['Medication', 'Exercise', 'General'].map((cat) {
                  bool isCatSelected = selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isCatSelected
                            ? const Color(0xFF0D9488)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isCatSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    _tasks.add(
                      ReminderTask(
                        id: DateTime.now().toString(),
                        title: titleController.text,
                        category: selectedCategory,
                      ),
                    );
                  });
                  _saveTasks();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Add Task',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color teal = Color(0xFF0D9488);
    const Color darkSlate = Color(0xFF0F172A);
    const Color softSlate = Color(0xFF64748B);

    List<ReminderTask> filteredTasks = _selectedCategory == 'All'
        ? _tasks
        : _tasks.where((t) => t.category == _selectedCategory).toList();

    // Smart Sorting: Incomplete first, then completed
    filteredTasks.sort((a, b) {
      if (a.isCompleted == b.isCompleted) return 0;
      return a.isCompleted ? 1 : -1;
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: darkSlate,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reminders',
          style: GoogleFonts.outfit(
            color: darkSlate,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator(
                        value: _completionRate,
                        strokeWidth: 10,
                        backgroundColor: teal.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(teal),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${(_completionRate * 100).toInt()}%',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: darkSlate,
                          ),
                        ),
                        Text(
                          'Done',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: softSlate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Daily Progress',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: darkSlate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_tasks.where((t) => t.isCompleted).length} of ${_tasks.length} tasks completed',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: softSlate,
                  ),
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Medication'),
                  _buildFilterChip('Exercise'),
                  _buildFilterChip('General'),
                ],
              ),
            ),
          ),

          // Timeline List
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 64,
                          color: teal.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All tasks completed!',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: softSlate,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return _buildTaskCard(task, teal);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: teal,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildFilterChip(String category) {
    bool isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFF1F5F9),
          ),
        ),
        child: Text(
          category,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(ReminderTask task, Color themeColor) {
    return GestureDetector(
      onLongPress: () => _showDeleteConfirm(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.category.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: themeColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Checkbox
              GestureDetector(
                onTap: () {
                  setState(() => task.isCompleted = !task.isCompleted);
                  _saveTasks();
                },
                child: Container(
                  width: 60,
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: task.isCompleted ? themeColor : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.isCompleted
                              ? Colors.transparent
                              : const Color(0xFFE2E8F0),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: task.isCompleted
                            ? Colors.white
                            : Colors.transparent,
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

  Future<void> _showDeleteConfirm(ReminderTask task) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Task?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to remove "${task.title}"?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _tasks.removeWhere((t) => t.id == task.id);
              });
              _saveTasks();
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
