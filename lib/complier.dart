import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class AppColors {
  static const Color primaryColor = Color(0xFF26BDCF);
  static const Color primaryLightColor = Color(0xFFECF8EE);
  static const Color secondaryColor = Colors.white;
  static const Color scaffoldBgLightColor = Color(0xFFF9FAFB);
  static const Color scaffoldWorkOutBgDarkColor = Color(0xFF101D23);
  static const Color primaryGold = Colors.amber;

  // title Color
  static const Color titleColor = Colors.black87;
  static const Color subTitleColor = Color(0xFF8D8D8D);
  static const Color smoothPageIndicatorUnSelectedColor = Color(0xFFB4B4B4);

  // morning macros
  static const Color ThemeRedColor = Color(0xFFEE4443);
  static const Color ThemeGreenColor = Color(0xFF23C45E);
  static const Color ThemeBlueColor = Color(0xFF0FA2E7);
  static const Color ThemelightGreenColor = Color(0xFFA8CC12);

  // tips bg Color
  static const Color tipsBgColor = Color(0xFFE6F4EE);
  static const Color tipsBorderColor = Color(0xFFC3E4EA);
  static const Color tipsPrimaryColor = Color(0xFF5BB8EC);
  static const Color tipsPrimaryLightColor = Color(0xFFC3E3F4);

  // breakfast card bg color
  static const Color breakfastCardBgColor = Color(0xFFF9FDF5);

  // place holder bg color
  static const Color placeholderErrorBgColor = Color(0xFFE0E0E0);
  static const Color placeholderErrorIconColor = Color(0xFF757575);

  // snack bar color
  static const Color checkInColor = Color(0xFF009F00);
  static const Color checkOutColor = Colors.red;
}

class DarkAppColors {
  static const Color primaryColor = Color(0xFF26BDCF);
  static const Color primaryLightColor = Color(0xFF1A2B2E);
  static const Color secondaryColor = Color(0xFF1E1E1E);
  static const Color scaffoldBgLightColor = Color(0xFF121212);
  static const Color scaffoldWorkOutBgDarkColor = Color(0xFF2D2D2D);
  static const Color primaryGold = Colors.amber;

  // title Color
  static const Color titleColor = Color(0xFFE0E0E0);
  static const Color subTitleColor = Color(0xFF8D8D8D);
  static const Color smoothPageIndicatorUnSelectedColor = Color(0xFFB4B4B4);

  // morning macros
  static const Color ThemeRedColor = Color(0xFFEE4443);
  static const Color ThemeGreenColor = Color(0xFF23C45E);
  static const Color ThemeBlueColor = Color(0xFF0FA2E7);
  static const Color ThemelightGreenColor = Color(0xFFA8CC12);

  // tips bg Color
  static const Color tipsBgColor = Color(0xFF1A2B2E);
  static const Color tipsBorderColor = Color(0xFF26BDCF);
  static const Color tipsPrimaryColor = Color(0xFF5BB8EC);
  static const Color tipsPrimaryLightColor = Color(0xFF1A2B2E);

  // breakfast card bg color
  static const Color breakfastCardBgColor = Color(0xFF1A2B2E);

  // place holder bg color
  static const Color placeholderErrorBgColor = Color(0xFF2D2D2D);
  static const Color placeholderErrorIconColor = Color(0xFF757575);

  // snack bar color
  static const Color checkInColor = Color(0xFF009F00);
  static const Color checkOutColor = Colors.red;
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

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
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Python Code Editor',
          theme: _themeProvider.isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
          home: CodeEditorScreen(themeProvider: _themeProvider),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      primaryColor: AppColors.primaryColor,
      scaffoldBackgroundColor: AppColors.scaffoldBgLightColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.secondaryColor,
        elevation: 0,
      ),
      fontFamily: 'monospace',
      brightness: Brightness.light,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      primaryColor: DarkAppColors.primaryColor,
      scaffoldBackgroundColor: DarkAppColors.scaffoldBgLightColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: DarkAppColors.primaryColor,
        foregroundColor: DarkAppColors.secondaryColor,
        elevation: 0,
      ),
      fontFamily: 'monospace',
      brightness: Brightness.dark,
    );
  }
}

class TestCase {
  final int n;
  final String expected;
  final bool isHidden;

  TestCase({
    required this.n,
    required this.expected,
    this.isHidden = false,
  });
}

class CodeEditorScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  
  const CodeEditorScreen({super.key, required this.themeProvider});

  @override
  State<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends State<CodeEditorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  String _output = '';
  bool _isLoading = false;
  late TabController _tabController;
  List<TestResult> _testResults = [];

  final String _backendUrl = Platform.isAndroid
      ? 'http://192.168.137.166:5000'
      : 'http://192.168.137.166:5000';

  final List<TestCase> _testCases = [
    TestCase(n: 5, expected: "1 2 3 4 5"),
    TestCase(n: 3, expected: "1 2 3"),
    TestCase(n: 1, expected: "1"),
    // Hidden test cases
    TestCase(n: 10, expected: "1 2 3 4 5 6 7 8 9 10", isHidden: true),
    TestCase(n: 0, expected: "", isHidden: true),
    TestCase(n: 7, expected: "1 2 3 4 5 6 7", isHidden: true),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _codeController.text = '''def printNumbers(n):
    # Write your solution here
    # Print numbers from 1 to n separated by space
    pass''';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> _executePrintNumbers(int n) async {
    try {
      final codeWithCall = '''
${_codeController.text}

# Test execution
n = $n
printNumbers(n)
''';

      final response = await http.post(
        Uri.parse('$_backendUrl/execute'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'code': codeWithCall}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        String output = responseBody['output'] ?? '';
        
        if (output.isNotEmpty && !output.contains('Error') && !output.contains('Traceback')) {
          return output.trim();
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> _runTestCases() async {
    if (_codeController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _output = '';
      _testResults.clear();
    });

    List<String> outputLines = [];
    bool hasError = false;

    // Only run visible test cases for "Run"
    for (int i = 0; i < _testCases.length; i++) {
      if (_testCases[i].isHidden) continue;
      
      final testCase = _testCases[i];
      final result = await _executePrintNumbers(testCase.n);
      
      bool passed = false;
      if (result != null) {
        passed = result == testCase.expected;
      }

      _testResults.add(TestResult(
        testCase: testCase,
        userOutput: result,
        passed: passed,
        index: i + 1,
      ));

      if (!passed) {
        hasError = true;
      }

      outputLines.add('Test Case ${i + 1}: ${passed ? "✓ PASSED" : "✗ FAILED"}');
      outputLines.add('  Input: n = ${testCase.n}');
      outputLines.add('  Expected: "${testCase.expected}"');
      outputLines.add('  Your output: "${result ?? "Error/No output"}"');
      outputLines.add('');
    }

    setState(() {
      _output = outputLines.join('\n');
      _isLoading = false;
    });
  }

  Future<void> _submitSolution() async {
    if (_codeController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _output = '';
      _testResults.clear();
    });

    List<String> outputLines = [];
    bool allPassed = true;
    int passedCount = 0;

    // Run all test cases including hidden ones for "Submit"
    for (int i = 0; i < _testCases.length; i++) {
      final testCase = _testCases[i];
      final result = await _executePrintNumbers(testCase.n);
      
      bool passed = false;
      if (result != null) {
        passed = result == testCase.expected;
      }

      _testResults.add(TestResult(
        testCase: testCase,
        userOutput: result,
        passed: passed,
        index: i + 1,
      ));

      if (passed) {
        passedCount++;
      } else {
        allPassed = false;
      }

      if (!testCase.isHidden) {
        outputLines.add('Test Case ${i + 1}: ${passed ? "✓ PASSED" : "✗ FAILED"}');
        outputLines.add('  Input: n = ${testCase.n}');
        outputLines.add('  Expected: "${testCase.expected}"');
        outputLines.add('  Your output: "${result ?? "Error/No output"}"');
        outputLines.add('');
      }
    }

    outputLines.add('------- SUBMISSION RESULTS -------');
    outputLines.add('Total Test Cases: ${_testCases.length}');
    outputLines.add('Passed: $passedCount');
    outputLines.add('Failed: ${_testCases.length - passedCount}');
    
    if (allPassed) {
      outputLines.add('\n🎉 All test cases passed!');
    } else {
      outputLines.add('\n❌ Some test cases failed.');
    }

    setState(() {
      _output = outputLines.join('\n');
      _isLoading = false;
    });

    if (allPassed) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.themeProvider.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: widget.themeProvider.greenColor,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.themeProvider.titleColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have successfully completed the Print N Numbers problem!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: widget.themeProvider.subTitleColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.themeProvider.tipsBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.themeProvider.tipsBorderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      '✓ All ${_testCases.length} test cases passed',
                      style: TextStyle(
                        color: widget.themeProvider.greenColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '✓ Including ${_testCases.where((tc) => tc.isHidden).length} hidden test cases',
                      style: TextStyle(
                        color: widget.themeProvider.greenColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Continue',
                style: TextStyle(
                  color: widget.themeProvider.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeProvider,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: widget.themeProvider.scaffoldBgColor,
          appBar: AppBar(
            title: const Text('Print N Numbers - Easy'),
            centerTitle: true,
            backgroundColor: widget.themeProvider.primaryColor,
            foregroundColor: widget.themeProvider.secondaryColor,
            actions: [
              IconButton(
                onPressed: widget.themeProvider.toggleTheme,
                icon: Icon(
                  widget.themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: widget.themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
              ),
            ],
          ),
          body: Column(
            children: [
              // Tab bar for Description and Solutions
              Container(
                color: widget.themeProvider.secondaryColor,
                child: TabBar(
                  controller: _tabController,
                  labelColor: widget.themeProvider.primaryColor,
                  unselectedLabelColor: widget.themeProvider.subTitleColor,
                  indicatorColor: widget.themeProvider.primaryColor,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Description'),
                    Tab(text: 'Code'),
                  ],
                ),
              ),
              
              // Content area
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDescriptionTab(),
                    _buildCodeEditorTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescriptionTab() {
    return Container(
      color: widget.themeProvider.secondaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Problem title and difficulty
            Row(
              children: [
                Text(
                  '1. Print N Numbers',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.themeProvider.titleColor,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.themeProvider.lightGreenColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: widget.themeProvider.lightGreenColor),
                  ),
                  child: Text(
                    'Easy',
                    style: TextStyle(
                      color: widget.themeProvider.lightGreenColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Problem description
            Text(
              'Given a positive integer n, print all numbers from 1 to n separated by spaces.',
              style: TextStyle(
                fontSize: 16,
                color: widget.themeProvider.titleColor,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'If n is 0 or negative, print nothing.',
              style: TextStyle(
                fontSize: 16,
                color: widget.themeProvider.titleColor,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'The output should be printed on a single line with numbers separated by single spaces.',
              style: TextStyle(
                fontSize: 16,
                color: widget.themeProvider.titleColor,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Examples
            _buildExample(
              'Example 1:',
              'Input: n = 5\nOutput: 1 2 3 4 5',
            ),
            
            const SizedBox(height: 16),
            
            _buildExample(
              'Example 2:',
              'Input: n = 3\nOutput: 1 2 3',
            ),
            
            const SizedBox(height: 16),
            
            _buildExample(
              'Example 3:',
              'Input: n = 1\nOutput: 1',
            ),
            
            const SizedBox(height: 24),
            
            // Constraints
            Text(
              'Constraints:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.themeProvider.titleColor,
              ),
            ),
            
            const SizedBox(height: 8),
            
            _buildConstraint('0 ≤ n ≤ 1000'),
            _buildConstraint('Numbers should be printed separated by single spaces'),
            _buildConstraint('No trailing spaces allowed'),
            _buildConstraint('If n ≤ 0, print nothing'),
            
            const SizedBox(height: 20),
            
            // Follow-up
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.themeProvider.tipsBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.themeProvider.tipsBorderColor),
              ),
              child: Text(
                'Follow-up: Can you solve this using different approaches like loops, recursion, or list comprehension?',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.themeProvider.titleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            
          ],
        ),
      ),
    );
  }

  Widget _buildCodeEditorTab() {
    return Container(
      color: widget.themeProvider.scaffoldBgColor,
      child: Column(
        children: [
          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: widget.themeProvider.secondaryColor,
            child: Row(
              children: [
                Text(
                  'Python',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.themeProvider.titleColor,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runTestCases,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Run'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeProvider.primaryColor,
                    foregroundColor: widget.themeProvider.secondaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitSolution,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeProvider.greenColor,
                    foregroundColor: widget.themeProvider.secondaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
          
          // Code Editor
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.themeProvider.primaryColor.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _codeController,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                  hintText: 'def printNumbers(n):\n    # Write your solution here\n    # Print numbers from 1 to n separated by space\n    pass',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
          
          // Output Section
          if (_output.isNotEmpty)
            Container(
              height: 200,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.themeProvider.secondaryColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.themeProvider.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.terminal,
                        color: widget.themeProvider.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Output',
                        style: TextStyle(
                          color: widget.themeProvider.titleColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: widget.themeProvider.primaryColor.withOpacity(0.2),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1419),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _output,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: widget.themeProvider.greenColor,
                            height: 1.4,
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

  Widget _buildExample(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.themeProvider.titleColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.themeProvider.workoutBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConstraint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: widget.themeProvider.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: widget.themeProvider.titleColor,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }


}

class TestResult {
  final TestCase testCase;
  final String? userOutput;
  final bool passed;
  final int index;

  TestResult({
    required this.testCase,
    required this.userOutput,
    required this.passed,
    required this.index,
  });
}