import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

enum ExerciseCategory { fullBody, therapist, stretching }

enum CompletionStatus { pending, completed, skipped }

class Exercise {
  final String id;
  final String name;
  final int targetSets;
  int currentSets;
  final bool isHoldBased;
  final int? holdDuration;
  String? difficultyRating;
  final ExerciseCategory category;
  CompletionStatus status;
  String? skipReason;
  final String? bodyPart;

  Exercise({
    required this.id,
    required this.name,
    required this.targetSets,
    this.currentSets = 0,
    this.isHoldBased = false,
    this.holdDuration,
    this.difficultyRating,
    required this.category,
    this.status = CompletionStatus.pending,
    this.skipReason,
    this.bodyPart,
  });

  factory Exercise.fromMap(
    Map<String, dynamic> map,
    ExerciseCategory category,
  ) {
    return Exercise(
      id: map['id']?.toString() ?? UniqueKey().toString(),
      name: map['exercise_name'] ?? 'Unknown Exercise',
      targetSets: map['target_sets'] ?? 3,
      currentSets: 0,
      isHoldBased: map['is_hold_based'] ?? false,
      holdDuration: map['hold_duration'],
      category: category,
      status: map['status'] == 'completed'
          ? CompletionStatus.completed
          : (map['status'] == 'skipped'
                ? CompletionStatus.skipped
                : CompletionStatus.pending),
      skipReason: map['skip_reason'],
      bodyPart: map['body_part'],
    );
  }
}

class ExerciseTrackerPage extends StatefulWidget {
  const ExerciseTrackerPage({super.key});

  @override
  State<ExerciseTrackerPage> createState() => _ExerciseTrackerPageState();
}

class _ExerciseTrackerPageState extends State<ExerciseTrackerPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _reasonController = TextEditingController();
  String _selectedBodyPart = 'All';

  final List<String> _bodyParts = [
    'All',
    'Legs',
    'Chest',
    'Abs',
    'Arms',
    'Forearms',
    'Shoulder',
  ];

  List<Exercise> _exercises = [];
  final _supabase = Supabase.instance.client;
  StreamSubscription? _subscription;

  void _setupExercises() {
    _exercises = [];

    // Fetch and listen to therapist assignments
    final patientId = _supabase.auth.currentUser?.id;
    if (patientId != null) {
      _subscription = _supabase
          .from('prescribed_exercises')
          .stream(primaryKey: ['id'])
          .eq('patient_id', patientId)
          .listen((data) {
            if (mounted) {
              setState(() {
                // Map all prescribed exercises from Supabase
                _exercises = data
                    .map(
                      (map) =>
                          Exercise.fromMap(map, ExerciseCategory.therapist),
                    )
                    .toList();
              });
            }
          });
    }
  }

  @override
  void initState() {
    super.initState();
    _setupExercises();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  double get _totalProgress {
    int totalSets = _exercises.fold(0, (sum, e) => sum + e.targetSets);
    int completedSets = _exercises.fold(0, (sum, e) => sum + e.currentSets);
    return totalSets == 0 ? 0 : completedSets / totalSets;
  }

  @override
  Widget build(BuildContext context) {
    const Color crowColor = Color(0xFF0D0907);
    const Color darkSlate = Color(0xFF0F172A);
    const Color softSlate = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: crowColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Exercise Tracker',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          // Fixed Progress Section
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Color(0xFF0D0907)),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(
                  'Daily Progress',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(_totalProgress * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: _buildExerciseList(
              ExerciseCategory.therapist,
              crowColor,
              darkSlate,
              softSlate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(
    ExerciseCategory category,
    Color themeColor,
    Color darkSlate,
    Color softSlate,
  ) {
    var filteredExercises = _exercises
        .where((e) => e.category == category)
        .where((e) => e.status == CompletionStatus.pending)
        .toList();

    if (category == ExerciseCategory.fullBody && _selectedBodyPart != 'All') {
      filteredExercises = filteredExercises
          .where((e) => e.bodyPart == _selectedBodyPart)
          .toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            'MY WORKOUTS',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: darkSlate,
              letterSpacing: 1,
            ),
          ),
        ),
        if (category == ExerciseCategory.fullBody)
          _buildBodyPartFilter(themeColor, darkSlate, softSlate),
        Expanded(
          child: filteredExercises.isEmpty
              ? _buildEmptyState(softSlate)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) {
                    return _buildExerciseCard(
                      filteredExercises[index],
                      themeColor,
                      darkSlate,
                      softSlate,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBodyPartFilter(
    Color themeColor,
    Color darkSlate,
    Color softSlate,
  ) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _bodyParts.length,
        itemBuilder: (context, index) {
          final part = _bodyParts[index];
          final isSelected = _selectedBodyPart == part;
          return GestureDetector(
            onTap: () => setState(() => _selectedBodyPart = part),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? themeColor : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: themeColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  part,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : softSlate,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(Color softSlate) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedBodyPartMuscle,
            size: 64,
            color: softSlate,
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises assigned yet',
            style: GoogleFonts.outfit(
              color: softSlate,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    Exercise exercise,
    Color themeColor,
    Color darkSlate,
    Color softSlate,
  ) {
    bool isFinished =
        exercise.currentSets >= exercise.targetSets ||
        exercise.status != CompletionStatus.pending;
    bool isTherapist = exercise.category == ExerciseCategory.therapist;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: exercise.status == CompletionStatus.completed
                        ? const Color(0xFFD1FAE5)
                        : (exercise.status == CompletionStatus.skipped
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    exercise.isHoldBased
                        ? Icons.timer_outlined
                        : Icons.fitness_center_rounded,
                    color: exercise.status == CompletionStatus.completed
                        ? const Color(0xFF059669)
                        : (exercise.status == CompletionStatus.skipped
                              ? Colors.red
                              : themeColor),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: darkSlate,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${exercise.targetSets} Sets • ${exercise.isHoldBased ? '${exercise.holdDuration}s Hold' : '12 Reps'}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: softSlate,
                        ),
                      ),
                    ],
                  ),
                ),
                if (exercise.status == CompletionStatus.completed)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                if (exercise.status == CompletionStatus.skipped)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),

          // Progress Track
          if (exercise.status == CompletionStatus.pending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(exercise.targetSets, (i) {
                  bool isDone = i < exercise.currentSets;
                  bool isLast = i == exercise.targetSets - 1;
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(right: isLast ? 0 : 6),
                      decoration: BoxDecoration(
                        color: isDone ? themeColor : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
              ),
            ),

          const SizedBox(height: 16),

          // Interaction Area
          if (exercise.status == CompletionStatus.pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: isTherapist
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    exercise.status =
                                        CompletionStatus.completed;
                                    exercise.currentSets = exercise.targetSets;
                                  });
                                  // Update Supabase if it's a prescribed exercise
                                  if (exercise.category ==
                                      ExerciseCategory.therapist) {
                                    await _supabase
                                        .from('prescribed_exercises')
                                        .update({'status': 'completed'})
                                        .eq('id', exercise.id);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    111,
                                    195,
                                    112,
                                  ), // Medium Green
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'COMPLETED',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _showSkipReasonDialog(exercise),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    223,
                                    97,
                                    78,
                                  ), // Medium Red
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'NOT COMPLETED',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Center(
                      child: ElevatedButton(
                        onPressed: exercise.isHoldBased
                            ? () => _showTimerDialog(exercise)
                            : () => setState(() {
                                exercise.currentSets++;
                                if (exercise.currentSets >=
                                    exercise.targetSets) {
                                  exercise.status = CompletionStatus.completed;
                                }
                              }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 48,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          exercise.isHoldBased
                              ? 'START HOLD TIMER'
                              : 'COMPLETE SET ${exercise.currentSets + 1}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
            )
          else if (exercise.status == CompletionStatus.completed)
            // Rating Section
            _buildRatingSection(exercise, themeColor, darkSlate, softSlate)
          else if (exercise.status == CompletionStatus.skipped)
            // Skip Reason Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REASON FOR NOT COMPLETING:',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.red,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    exercise.skipReason ?? 'No reason provided',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(
    Exercise exercise,
    Color themeColor,
    Color darkSlate,
    Color softSlate,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW WAS THE INTENSITY?',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: softSlate,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: ['Easy', 'Medium', 'Hard'].map((rating) {
              bool isSelected = exercise.difficultyRating == rating;
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => exercise.difficultyRating = rating),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? themeColor : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        rating,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : darkSlate,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showSkipReasonDialog(Exercise exercise) {
    _reasonController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Reason for skipping',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: TextField(
          controller: _reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Too much pain, Lack of time...',
            hintStyle: GoogleFonts.outfit(color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_reasonController.text.isNotEmpty) {
                setState(() {
                  exercise.status = CompletionStatus.skipped;
                  exercise.skipReason = _reasonController.text;
                });

                // Update Supabase if it's a prescribed exercise
                if (exercise.category == ExerciseCategory.therapist) {
                  await _supabase
                      .from('prescribed_exercises')
                      .update({
                        'status': 'skipped',
                        'skip_reason': _reasonController.text,
                      })
                      .eq('id', exercise.id);
                }

                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'SUBMIT',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimerDialog(Exercise exercise) {
    int timeLeft = exercise.holdDuration!;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (timeLeft > 0) {
              setDialogState(() => timeLeft--);
            } else {
              t.cancel();
              Navigator.pop(context);
              setState(() {
                exercise.currentSets++;
                if (exercise.currentSets >= exercise.targetSets) {
                  exercise.status = CompletionStatus.completed;
                }
              });
            }
          });

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 140,
                      width: 140,
                      child: CircularProgressIndicator(
                        value: timeLeft / exercise.holdDuration!,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0D0907),
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '$timeLeft',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Maintain Position',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep breathing steadily',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'STOP',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      color: Colors.red,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
