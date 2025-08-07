// import 'package:flutter/material.dart';
// import 'package:studysync/features/Student/presentation/widgets/question.dart'; // Assuming your Question model is here

// class TestQuestionScreen extends StatefulWidget {
//   final String studentId;
//   final String difficulty;
//   final int questionNumber;
//   final int totalQuestions;

//   const TestQuestionScreen({
//     super.key,
//     required this.studentId,
//     required this.difficulty,
//     required this.questionNumber,
//     required this.totalQuestions,
//   });

//   @override
//   State<TestQuestionScreen> createState() => _TestQuestionScreenState();
// }

// class _TestQuestionScreenState extends State<TestQuestionScreen>
//     with TickerProviderStateMixin {
//   Question? _currentQuestion;
//   int? _selectedAnswerIndex;
//   bool _isAnswered = false;
//   bool _isLoading = true;
//   bool _showNextButton = false;
//   late AnimationController _slideController;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(1.0, 0.0),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.easeInOut,
//     ));

//     _loadQuestion();
//   }

//   @override
//   void dispose() {
//     _slideController.dispose();
//     super.dispose();
//   }

//   void _loadQuestion() {
//     // Simulating a fetch delay
//     Future.delayed(const Duration(milliseconds: 200), () {
//       _currentQuestion = _getQuestionForDifficultyAndNumber(
//         widget.difficulty,
//         widget.questionNumber,
//       );
//       setState(() {
//         _isLoading = false;
//       });
//       _slideController.forward();
//     });
//   }

//   // --- Data Fetching Logic ---

//   Question _getQuestionForDifficultyAndNumber(String difficulty, int questionNumber) {
//     // This would typically come from a database or API.
//     // We use sample questions for this example.
//     if (difficulty == 'EASY') {
//       return _getEasyQuestion(questionNumber);
//     } else if (difficulty == 'MEDIUM') {
//       return _getMediumQuestion(questionNumber);
//     } else {
//       return _getHardQuestion(questionNumber);
//     }
//   }

//   Question _getEasyQuestion(int number) {
//     final easyQuestions = [
//       Question(
//         text: 'What is the output of `print(2 ** 3)`?',
//         options: ['6', '8', '9', '12'],
//         correctAnswerIndex: 1,
//         explanation: 'The `**` operator is used for exponentiation. `2 ** 3` means 2 raised to the power of 3, which is 2^3 = 8',
//       ),
//       Question(
//         text: 'Which of the following is a mutable data type in Python?',
//         options: ['Tuple', 'String', 'List', 'Integer'],
//         correctAnswerIndex: 2,
//         explanation: 'Lists are mutable, meaning their elements and size can be changed after creation. Tuples and Strings are immutable.',
//       ),
//       Question(
//         text: 'What keyword is used to define a function in Python?',
//         options: ['function', 'def', 'define', 'func'],
//         correctAnswerIndex: 1,
//         explanation: 'The `def` keyword is used to define functions in Python, followed by the function name and parentheses.',
//       ),
//       Question(
//         text: 'What is the correct file extension for Python files?',
//         options: ['.python', '.py', '.pt', '.pyt'],
//         correctAnswerIndex: 1,
//         explanation: 'Python script files are saved with the `.py` extension.',
//       ),
//       Question(
//         text: 'Which operator is used for floor division in Python?',
//         options: ['/', '//', '%', '**'],
//         correctAnswerIndex: 1,
//         explanation: 'The `//` operator performs floor division, which divides and rounds down to the nearest whole number.',
//       ),
//     ];
//     return easyQuestions[(number - 1) % easyQuestions.length];
//   }

//   Question _getMediumQuestion(int number) {
//     final mediumQuestions = [
//       Question(
//         text: 'What is the output?\n`list1 = [1, 2, 3]`\n`list2 = list1`\n`list2.append(4)`\n`print(list1)`',
//         options: ['[1, 2, 3]', '[1, 2, 3, 4]', '[4]', 'Error'],
//         correctAnswerIndex: 1,
//         explanation: '`list2 = list1` makes both variables point to the same list in memory. Modifying `list2` also modifies `list1`.',
//       ),
//       Question(
//         text: 'What does the `pass` statement do in Python?',
//         options: ['Skips the rest of the loop', 'Acts as a placeholder', 'Exits the program', 'Raises an exception'],
//         correctAnswerIndex: 1,
//         explanation: 'The `pass` statement is a null operation. It acts as a placeholder where code is syntactically required but you have nothing to write.',
//       ),
//       Question(
//         text: 'Which of these is NOT a core data type in Python?',
//         options: ['Dictionary', 'Class', 'Array', 'Tuple'],
//         correctAnswerIndex: 2,
//         explanation: 'While Python has list-like functionality, the core `array` type must be imported from the `array` module and is not a built-in data type like lists or tuples.',
//       ),
//       Question(
//         text: 'What is the output of `print("hello"[::-1])`?',
//         options: ['hello', 'olleh', 'h', 'o'],
//         correctAnswerIndex: 1,
//         explanation: 'The slice notation `[::-1]` is a common idiom for reversing a sequence, including strings, in Python.',
//       ),
//       Question(
//         text: 'How do you start a block of code in Python?',
//         options: ['Using curly braces {}', 'Using the `begin` keyword', 'Using indentation', 'Using parentheses ()'],
//         correctAnswerIndex: 2,
//         explanation: 'Python uses indentation (whitespace at the beginning of a line) to define the scope of code blocks, such as in functions, loops, and classes.',
//       ),
//     ];
//     return mediumQuestions[(number - 1) % mediumQuestions.length];
//   }

//   Question _getHardQuestion(int number) {
//     final hardQuestions = [
//       Question(
//         text: 'What is the purpose of the `__init__` method in a Python class?',
//         options: ['To initialize the class instance', 'To destroy the class instance', 'To create a static method', 'To return a string representation'],
//         correctAnswerIndex: 0,
//         explanation: '`__init__` is the constructor for a class. It is called when a new object (instance) is created and is used to initialize its attributes.',
//       ),
//       Question(
//         text: 'What is a decorator in Python?',
//         options: ['A design pattern for database connections', 'A function that modifies other functions or classes', 'A variable that cannot be changed', 'A special type of comment'],
//         correctAnswerIndex: 1,
//         explanation: 'Decorators are a powerful feature that allow you to wrap a function in another function to extend its behavior without permanently modifying it.',
//       ),
//       Question(
//         text: 'What is the difference between a shallow copy and a deep copy?',
//         options: ['There is no difference', 'Deep copy creates a new object and recursively copies nested objects', 'Shallow copy is faster', 'Deep copy only works on lists'],
//         correctAnswerIndex: 1,
//         explanation: 'A shallow copy creates a new object but inserts references to the original nested objects. A deep copy creates a new object and recursively creates new copies of all nested objects.',
//       ),
//       Question(
//         text: 'What does the GIL (Global Interpreter Lock) do in CPython?',
//         options: ['Speeds up multi-threaded code', 'Prevents multiple native threads from executing Python bytecodes at once', 'Manages global variables', 'Secures the interpreter from attacks'],
//         correctAnswerIndex: 1,
//         explanation: 'The GIL is a mutex that protects access to Python objects, preventing multiple threads from executing Python bytecode at the same time within a single process, which can limit parallelism.',
//       ),
//       Question(
//         text: 'What will be the output?\n`my_set = {1, 2}`\n`my_set.update({3, 4, 1})`\n`print(my_set)`',
//         options: ['{1, 2}', '{1, 2, 3, 4, 1}', '{3, 4}', '{1, 2, 3, 4}'],
//         correctAnswerIndex: 3,
//         explanation: 'Sets are unordered collections of unique elements. `update()` adds all elements from an iterable. Since sets only store unique values, the duplicate `1` is ignored.',
//       ),
//     ];
//     return hardQuestions[(number - 1) % hardQuestions.length];
//   }

//   // --- UI Logic and Handlers ---

//   void _handleAnswer(int selectedIndex) {
//     setState(() {
//       _isAnswered = true;
//       _selectedAnswerIndex = selectedIndex;
//     });
    
//     // Show the Next button after a short delay to let user see the result
//     Future.delayed(const Duration(milliseconds: 1000), () {
//       if (mounted) {
//         setState(() {
//           _showNextButton = true;
//         });
//       }
//     });
    
//     // In a real app, you would send the answer result to your backend here.
//   }

//   void _goToNextQuestion() {
//     if (widget.questionNumber < widget.totalQuestions) {
//       // Navigate to next question
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(
//           builder: (context) => TestQuestionScreen(
//             studentId: widget.studentId,
//             difficulty: widget.difficulty,
//             questionNumber: widget.questionNumber + 1,
//             totalQuestions: widget.totalQuestions,
//           ),
//         ),
//       );
//     } else {
//       // Test completed - navigate back or to results screen
//       Navigator.of(context).pop();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("🎉 Test Completed! Great job!"),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 3),
//         ),
//       );
//     }
//   }

//   Color _getOptionColor(int index) {
//     if (!_isAnswered) return Colors.grey.shade200;
//     if (index == _currentQuestion!.correctAnswerIndex) return Colors.green.shade400;
//     if (index == _selectedAnswerIndex && index != _currentQuestion!.correctAnswerIndex) {
//       return Colors.red.shade400;
//     }
//     return Colors.grey.shade200;
//   }

//   Color _getOptionTextColor(int index) {
//     if (!_isAnswered) return Colors.black87;
//     if (index == _currentQuestion!.correctAnswerIndex || 
//         (index == _selectedAnswerIndex && index != _currentQuestion!.correctAnswerIndex)) {
//       return Colors.white;
//     }
//     return Colors.grey.shade500;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${widget.difficulty} Test'),
//         centerTitle: true,
//         automaticallyImplyLeading: false, // Prevents a back button
//         backgroundColor: Theme.of(context).primaryColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SlideTransition(
//               position: _slideAnimation,
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     // Progress Section
//                     Text(
//                       'Question ${widget.questionNumber} of ${widget.totalQuestions}',
//                       textAlign: TextAlign.center,
//                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         color: Colors.grey.shade600,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     LinearProgressIndicator(
//                       value: widget.questionNumber / widget.totalQuestions,
//                       minHeight: 8,
//                       borderRadius: BorderRadius.circular(4),
//                       backgroundColor: Colors.grey.shade300,
//                       valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
//                     ),
//                     const SizedBox(height: 32),
                    
//                     // Question Section
//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.grey.withOpacity(0.15),
//                             spreadRadius: 2,
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Text(
//                         _currentQuestion!.text,
//                         style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                           fontWeight: FontWeight.w600,
//                           height: 1.4,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                     const SizedBox(height: 32),
                    
//                     // Options Section
//                     ..._buildOptions(),
//                     const SizedBox(height: 24),
                    
//                     // Explanation Section (shown after answering)
//                     if (_isAnswered) ...[
//                       Container(
//                         padding: const EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.shade50,
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: Colors.blue.shade200),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Icon(
//                                   Icons.lightbulb_outline,
//                                   color: Colors.blue.shade700,
//                                   size: 24,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   'Explanation',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.blue.shade700,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 12),
//                             Text(
//                               _currentQuestion!.explanation,
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.black87,
//                                 height: 1.5,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                     ],
                    
//                     // Next Button (shown only after showing explanation)
//                     if (_showNextButton) ...[
//                       ElevatedButton(
//                         onPressed: _goToNextQuestion,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Theme.of(context).primaryColor,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           textStyle: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 4,
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               widget.questionNumber < widget.totalQuestions 
//                                   ? 'Next Question' 
//                                   : 'Finish Test',
//                             ),
//                             const SizedBox(width: 12),
//                             Icon(
//                               widget.questionNumber < widget.totalQuestions 
//                                   ? Icons.arrow_forward_ios 
//                                   : Icons.check_circle,
//                               size: 20,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   List<Widget> _buildOptions() {
//     return _currentQuestion!.options.asMap().entries.map((entry) {
//       int idx = entry.key;
//       String text = entry.value;
//       bool isCorrect = idx == _currentQuestion!.correctAnswerIndex;
//       bool isSelected = idx == _selectedAnswerIndex;
      
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8.0),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 300),
//           child: ElevatedButton(
//             onPressed: _isAnswered ? null : () => _handleAnswer(idx),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _getOptionColor(idx),
//               foregroundColor: _getOptionTextColor(idx),
//               disabledBackgroundColor: _getOptionColor(idx),
//               disabledForegroundColor: _getOptionTextColor(idx),
//               padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
//               textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 side: BorderSide(
//                   color: _isAnswered && isCorrect 
//                       ? Colors.green.shade600 
//                       : _isAnswered && isSelected && !isCorrect
//                           ? Colors.red.shade600
//                           : Colors.transparent,
//                   width: 2,
//                 ),
//               ),
//               elevation: _isAnswered ? 0 : 2,
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 24,
//                   height: 24,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: _isAnswered 
//                         ? Colors.transparent 
//                         : Colors.grey.shade400,
//                     border: Border.all(
//                       color: _isAnswered 
//                           ? Colors.white 
//                           : Colors.grey.shade600,
//                       width: 2,
//                     ),
//                   ),
//                   child: _isAnswered && isCorrect
//                       ? const Icon(Icons.check, color: Colors.white, size: 16)
//                       : _isAnswered && isSelected && !isCorrect
//                           ? const Icon(Icons.close, color: Colors.white, size: 16)
//                           : null,
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Text(
//                     text,
//                     textAlign: TextAlign.left,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }).toList();
//   }
// }