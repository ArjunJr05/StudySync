import 'package:flutter/material.dart';
import 'package:studysync/core/services/test_service.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

class Question {
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final String? codeSnippet;

  Question({
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    this.codeSnippet,
  });
}

class QuestionService {
  static Question getQuestion(String difficulty, int levelNumber) {
    if (difficulty.toUpperCase() == 'EASY') {
      return _getEasyQuestion(levelNumber);
    } else if (difficulty.toUpperCase() == 'MEDIUM') {
      return _getMediumQuestion(levelNumber);
    } else {
      return _getHardQuestion(levelNumber);
    }
  }

  static Question _getEasyQuestion(int levelNumber) {
    final easyQuestions = [
      // Level 1
      Question(
        text: 'What is the output of `print(2 ** 3)`?',
        options: ['6', '8', '9', '12'],
        correctAnswerIndex: 1,
        explanation:
            'The `**` operator is for exponentiation. `2 ** 3` means 2 to the power of 3, which is 8.',
      ),
      // Level 2
      Question(
        text: 'Which of the following is a valid variable name in Python?',
        options: ['2variable', 'my_variable', 'class', 'my-variable'],
        correctAnswerIndex: 1,
        explanation:
            'Variable names must start with a letter or underscore and cannot be keywords.',
      ),
      // ... (rest of the questions are omitted for brevity)
    ];
    return easyQuestions[(levelNumber - 1) % easyQuestions.length];
  }

  static Question _getMediumQuestion(int levelNumber) {
    final mediumQuestions = [
      Question(
          text: 'What does list slicing `my_list[1:4]` do?',
          options: [
            'Returns elements at index 1 and 4',
            'Returns elements from index 1 up to (but not including) index 4',
            'Returns elements from index 1 to index 4 inclusive',
            'Returns an error'
          ],
          correctAnswerIndex: 1,
          explanation:
              'Slicing `[start:end]` extracts a portion of the list from the start index up to the end index.'),
      // ...
    ];
    return mediumQuestions[(levelNumber - 1) % mediumQuestions.length];
  }

  static Question _getHardQuestion(int levelNumber) {
    final hardQuestions = [
      Question(
          text: 'What is a decorator in Python?',
          options: [
            'A function that styles other functions',
            'A design pattern to add new functionality to an object without altering its structure',
            'A function that takes another function and extends its behavior without explicitly modifying it',
            'A class method for decoration'
          ],
          correctAnswerIndex: 2,
          explanation:
              'Decorators are a powerful feature that allow programmers to modify the behavior of a function or class.'),
      // ...
    ];
    return hardQuestions[(levelNumber - 1) % hardQuestions.length];
  }
}

class TestQuestionScreen extends StatefulWidget {
  final String studentId;
  final String difficulty;
  final int questionNumber;
  final int totalQuestions;
  final Question question;
  // NEW: Added required fields
  final String institutionName;
  final String teacherName;

  const TestQuestionScreen({
    super.key,
    required this.studentId,
    required this.difficulty,
    required this.questionNumber,
    required this.totalQuestions,
    required this.question,
    // NEW: Added to constructor
    required this.institutionName,
    required this.teacherName,
  });

  @override
  State<TestQuestionScreen> createState() => _TestQuestionScreenState();
}

class _TestQuestionScreenState extends State<TestQuestionScreen> {
  int? _selectedOptionIndex;
  bool _isSubmitted = false;
  bool _isCorrect = false;

  void _handleSubmit() async {
    if (_selectedOptionIndex == null) return;

    setState(() {
      _isSubmitted = true;
      _isCorrect = _selectedOptionIndex == widget.question.correctAnswerIndex;
    });

    // UPDATED: Pass the required parameters
    await TestProgressExtension.saveAnsweredQuestion(
      studentId: widget.studentId,
      subject: 'python',
      difficulty: widget.difficulty.toLowerCase(),
      questionNumber: widget.questionNumber,
      isCorrect: _isCorrect,
      institutionName: widget.institutionName,
      teacherName: widget.teacherName,
    );

    _showFeedbackDialog();
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        title: Row(
          children: [
            Icon(
              _isCorrect ? Icons.check_circle : Icons.cancel,
              color: _isCorrect ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            KText(
              text: _isCorrect ? 'Correct!' : 'Incorrect',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              textColor:
                  _isCorrect ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ],
        ),
        content: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            KText(
              text: widget.question.explanation,
              textColor: AppColors.subTitleColor,
            ),
          ],
        )),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: KText(
              text: 'Continue',
              fontWeight: FontWeight.bold,
              textColor:
                  _isCorrect ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (widget.difficulty) {
      case 'EASY':
        return Colors.green;
      case 'MEDIUM':
        return AppColors.primaryColor;
      case 'HARD':
        return AppColors.ThemeRedColor;
      default:
        return AppColors.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: KText(
          text: 'Level ${widget.questionNumber}',
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KText(
              text: widget.question.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 16),
            if (widget.question.codeSnippet != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: atomOneDarkTheme['root']?.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HighlightView(
                  widget.question.codeSnippet!,
                  language: 'python',
                  theme: atomOneDarkTheme,
                  textStyle:
                      const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            const SizedBox(height: 24),
            const KText(
              text: 'Choose an option:',
              textColor: AppColors.subTitleColor,
              fontWeight: FontWeight.w500,
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.question.options.length,
              itemBuilder: (context, index) {
                return _buildOptionTile(index);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildOptionTile(int index) {
    Color borderColor = Colors.grey.shade300;
    Color tileColor = Colors.white;
    Icon? trailingIcon;

    if (_isSubmitted) {
      if (index == widget.question.correctAnswerIndex) {
        borderColor = Colors.green;
        tileColor = Colors.green.shade50;
        trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
      } else if (index == _selectedOptionIndex) {
        borderColor = Colors.red;
        tileColor = Colors.red.shade50;
        trailingIcon = const Icon(Icons.cancel, color: Colors.red);
      }
    } else if (index == _selectedOptionIndex) {
      borderColor = _getDifficultyColor();
      tileColor = _getDifficultyColor().withOpacity(0.1);
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: borderColor, width: _selectedOptionIndex == index ? 2 : 1.5),
      ),
      child: ListTile(
        onTap: _isSubmitted
            ? null
            : () {
                setState(() {
                  _selectedOptionIndex = index;
                });
              },
        tileColor: tileColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: KText(
          text: widget.question.options[index],
          textColor: AppColors.titleColor,
        ),
        trailing: trailingIcon,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -3),
            )
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          )),
      child: ElevatedButton(
        onPressed:
            (_selectedOptionIndex != null && !_isSubmitted) ? _handleSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getDifficultyColor(),
          disabledBackgroundColor: Colors.grey.shade400,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const KText(
          text: 'Submit',
          textColor: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}