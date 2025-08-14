import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:studysync/core/services/test_service.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'question.dart';


class DarkAppColors {
  static const Color primaryColor = Color(0xFF26BDCF);
  static const Color secondaryColor = Color(0xFF1E1E1E);
  static const Color scaffoldBgLightColor = Color(0xFF121212);
  static const Color scaffoldWorkOutBgDarkColor = Color(0xFF2D2D2D);
  static const Color ThemeRedColor = Color(0xFFEE4443);
  static const Color ThemeGreenColor = Color(0xFF23C45E);
  static const Color ThemelightGreenColor = Color(0xFFA8CC12);
  static const Color tipsBgColor = Color(0xFF1A2B2E);
  static const Color tipsBorderColor = Color(0xFF26BDCF);
  static const Color titleColor = Color(0xFFE0E0E0);
  static const Color subTitleColor = Color(0xFF8D8D8D);
}

// --- Data Models ---
class TestResult {
  final TestCase testCase;
  final String? userOutput;
  final bool passed;
  final int index;
  final Duration? executionTime;

  TestResult({
    required this.testCase,
    required this.userOutput,
    required this.passed,
    required this.index,
    this.executionTime,
  });
}

class CodeEditorScreen extends StatefulWidget {
  final String studentId;
  final String difficulty;
  final int questionNumber;
  final String institutionName;
  final String teacherName;

  const CodeEditorScreen({
    super.key,
    required this.studentId,
    required this.difficulty,
    required this.questionNumber,
    required this.institutionName,
    required this.teacherName,
  });

  @override
  State<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends State<CodeEditorScreen> with TickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  String _output = '';
  bool _isLoading = false;
  bool _isSubmitting = false;
  late TabController _tabController;
  List<TestResult> _testResults = [];
  bool _isDarkMode = false;
  Question? _currentQuestion;
  bool _hasUnsavedChanges = false;
  late Stopwatch _stopwatch;

  // UPDATED: Use your deployed Render URL
  final String _backendUrl = 'https://python-interpreter-jwjx.onrender.com';

  // Theme Getters
  Color get primaryColor => _isDarkMode ? DarkAppColors.primaryColor : AppColors.primaryColor;
  Color get secondaryColor => _isDarkMode ? DarkAppColors.secondaryColor : AppColors.secondaryColor;
  Color get scaffoldBgColor => _isDarkMode ? DarkAppColors.scaffoldBgLightColor : AppColors.scaffoldBgLightColor;
  Color get titleColor => _isDarkMode ? DarkAppColors.titleColor : AppColors.titleColor;
  Color get subTitleColor => _isDarkMode ? DarkAppColors.subTitleColor : AppColors.subTitleColor;
  Color get tipsBgColor => _isDarkMode ? DarkAppColors.tipsBgColor : AppColors.tipsBgColor;
  Color get tipsBorderColor => _isDarkMode ? DarkAppColors.tipsBorderColor : AppColors.tipsBorderColor;
  Color get workoutBgColor => _isDarkMode ? DarkAppColors.scaffoldWorkOutBgDarkColor : AppColors.scaffoldWorkOutBgDarkColor;
  Color get greenColor => _isDarkMode ? DarkAppColors.ThemeGreenColor : AppColors.ThemeGreenColor;
  Color get lightGreenColor => _isDarkMode ? DarkAppColors.ThemelightGreenColor : AppColors.ThemelightGreenColor;
  Color get redColor => _isDarkMode ? DarkAppColors.ThemeRedColor : AppColors.ThemeRedColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _stopwatch = Stopwatch()..start(); // NEW: Start the timer when the screen loads
    _loadQuestion();
    _codeController.addListener(() {
      if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _stopwatch.stop(); // NEW: Stop the timer when the screen is disposed
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    setState(() => _isLoading = true);
    try {
      _currentQuestion = QuestionService.getQuestion(widget.difficulty, widget.questionNumber);
      if (_currentQuestion != null) {
        _codeController.text = _currentQuestion!.initialCode;
      }
    } catch (e) {
      _showErrorDialog('Failed to load question.');
    } finally {
      setState(() {
        _isLoading = false;
        _hasUnsavedChanges = false;
      });
    }
  }

  String _extractFunctionName(String signature) {
    final match = RegExp(r'def\s+(\w+)\s*\(').firstMatch(signature);
    return match?.group(1) ?? 'unknownFunction';
  }

  Future<String?> _executeCode(dynamic input, String functionName) async {
    // This function handles code execution via backend
    String param = input is List ? input.map((p) => p is String ? '"$p"' : '$p').join(', ') : (input is String ? '"$input"' : '$input');
    String codeWithCall = '${_codeController.text}\n\nresult = $functionName($param)\nif result is not None: print(result)';

    try {
        final response = await http.post(
            Uri.parse('$_backendUrl/execute'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'code': codeWithCall}),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
            final body = json.decode(response.body);
            return body['error']?.isNotEmpty == true ? null : (body['output'] ?? '').trim();
        }
    } catch (e) {
        debugPrint('Execution error: $e');
    }
    return null;
  }

  Future<void> _runTestCases() async {
    if (_currentQuestion == null) return;
    setState(() { _isLoading = true; _output = ''; _testResults.clear(); });

    final visibleTests = _currentQuestion!.testCases.where((tc) => !tc.isHidden).toList();
    final functionName = _extractFunctionName(_currentQuestion!.functionSignature);
    
    for (int i = 0; i < visibleTests.length; i++) {
        final tc = visibleTests[i];
        final result = await _executeCode(tc.input, functionName);
        _testResults.add(TestResult(testCase: tc, userOutput: result, passed: result == tc.expected, index: i + 1));
    }

    setState(() {
        _output = _testResults.map((r) => 'Test Case ${r.index}: ${r.passed ? "✅ PASSED" : "❌ FAILED"}\n  Expected: "${r.testCase.expected}"\n  Your output: "${r.userOutput ?? "Error"}"\n').join('\n');
        _isLoading = false;
    });
  }

  Future<void> _submitSolution() async {
    if (_currentQuestion == null) return;

    setState(() {
      _isSubmitting = true;
      _output = 'Submitting your solution...';
      _testResults.clear();
    });
    
    _stopwatch.stop(); // Stop the timer to get the final duration
    final timeTakenSeconds = _stopwatch.elapsed.inSeconds;

    final functionName = _extractFunctionName(_currentQuestion!.functionSignature);
    int passedCount = 0;
    List<bool> testCaseResults = []; // NEW: To store results for all test cases

    // Evaluate against ALL test cases (visible and hidden)
    for (int i = 0; i < _currentQuestion!.testCases.length; i++) {
      final tc = _currentQuestion!.testCases[i];
      final result = await _executeCode(tc.input, functionName);
      final passed = result == tc.expected;
      if (passed) passedCount++;
      testCaseResults.add(passed);
    }

    final allPassed = passedCount == _currentQuestion!.testCases.length;

    // **CORE CHANGE**: Save the results to Firestore using the service extension.
    // This is the part that updates your database.
    final bool didSave = await TestProgressExtension.saveAnsweredQuestion(
      studentId: widget.studentId,
      subject: 'python', // As defined in your service
      difficulty: widget.difficulty.toLowerCase(),
      questionNumber: widget.questionNumber,
      isCorrect: allPassed, // The question is "correct" only if ALL test cases pass
      testCaseResults: testCaseResults,
      userCode: _codeController.text,
      timeTakenSeconds: timeTakenSeconds,
      institutionName: widget.institutionName,
      teacherName: widget.teacherName,
    );
    
    // Handle cases where the database update might fail (e.g., no internet)
    if (!didSave) {
      _showErrorDialog("A problem occurred while saving your progress. Please check your connection and try again.");
      setState(() => _isSubmitting = false);
      return; // Stop execution if saving failed
    }

    // Update the UI with the results
    setState(() {
      _output = '------- SUBMISSION RESULTS -------\nPassed: $passedCount/${_currentQuestion!.testCases.length}\n${allPassed ? "🎉 All test cases passed!" : "❌ Some test cases failed."}';
      _isSubmitting = false;
      _hasUnsavedChanges = false;
    });

    // Show the appropriate dialog to the user
    if (allPassed) {
      _showSuccessDialog();
    } else {
      _showPartialSuccessDialog(passedCount, _currentQuestion!.testCases.length);
    }
  }

  void _toggleTheme() => setState(() => _isDarkMode = !_isDarkMode);

  void _showSuccessDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Congratulations!'),
      content: Text('You have successfully completed ${_currentQuestion?.title ?? "this problem"}!'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop(); // Close dialog
            Navigator.of(context).pop(true); // Return true to video screen
          },
          child: const Text('Continue')
        )
      ],
    )
  );
}
  


  void _showPartialSuccessDialog(int passed, int total) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Partial Success'),
          content: Text('You passed $passed out of $total test cases. Keep trying!'),
          actions: [ TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Try Again')) ],
      ));
  }
  
  void _showErrorDialog(String message) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [ TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')) ],
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        title: Text(_currentQuestion?.title ?? 'Loading...'),
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: _toggleTheme,
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: secondaryColor,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: primaryColor,
                    unselectedLabelColor: subTitleColor,
                    indicatorColor: primaryColor,
                    tabs: const [ Tab(text: 'Problem'), Tab(text: 'Code') ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [ _buildProblemTab(), _buildCodeEditorTab() ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProblemTab() {
    if (_currentQuestion == null) return const Center(child: Text('No question loaded'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_currentQuestion!.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: titleColor)),
          const SizedBox(height: 20),
          Text(_currentQuestion!.description, style: TextStyle(fontSize: 16, color: titleColor, height: 1.5)),
          const SizedBox(height: 24),
          Text('Examples:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
          const SizedBox(height: 12),
          ..._currentQuestion!.examples.map((e) => _buildExample(e['input']!, e['output']!)).toList(),
          const SizedBox(height: 24),
          Text('Constraints:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
          ..._currentQuestion!.constraints.map((c) => Text('• $c', style: TextStyle(fontSize: 14, color: titleColor))).toList(),
        ],
      ),
    );
  }

  Widget _buildExample(String input, String output) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: workoutBgColor, borderRadius: BorderRadius.circular(8)),
      child: Text('Input: $input\nOutput: $output', style: const TextStyle(fontFamily: 'monospace', color: Colors.white)),
    );
  }

  Widget _buildCodeEditorTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: secondaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: (_isLoading || _isSubmitting) ? null : _runTestCases,
                icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow),
                label: const Text('Run'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: (_isLoading || _isSubmitting) ? null : _submitSolution,
                style: ElevatedButton.styleFrom(backgroundColor: greenColor),
                child: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : const Text('Submit', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8)),
            child: TextField(
              controller: _codeController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
              decoration: const InputDecoration(contentPadding: EdgeInsets.all(16), border: InputBorder.none),
            ),
          ),
        ),
        if (_output.isNotEmpty)
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: primaryColor.withOpacity(0.3))),
              child: SingleChildScrollView(child: Text(_output, style: const TextStyle(fontFamily: 'monospace'))),
            ),
          ),
      ],
    );
  }
}