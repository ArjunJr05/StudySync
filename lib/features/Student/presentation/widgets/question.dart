import 'package:flutter/foundation.dart';

class TestCase {
  final dynamic input;
  final String expected;
  final bool isHidden;
  final String description;

  TestCase({
    required this.input,
    required this.expected,
    this.isHidden = false,
    required this.description,
  });
}

class Question {
  final String title;
  final String description;
  final String difficulty;
  final List<String> constraints;
  final List<Map<String, String>> examples;
  final String functionSignature;
  final String initialCode;
  final List<TestCase> testCases;
  final String hint;

  Question({
    required this.title,
    required this.description,
    required this.difficulty,
    required this.constraints,
    required this.examples,
    required this.functionSignature,
    required this.initialCode,
    required this.testCases,
    required this.hint,
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
      // Level 1: Print N Numbers
      Question(
        title: 'Print N Numbers',
        description:
            'Given a positive integer n, print all numbers from 1 to n separated by spaces.',
        difficulty: 'Easy',
        constraints: [
          '0 ≤ n ≤ 1000',
          'Numbers should be printed separated by single spaces',
          'No trailing spaces allowed',
          'If n ≤ 0, print nothing'
        ],
        examples: [
          {'input': 'n = 5', 'output': '1 2 3 4 5'},
          {'input': 'n = 3', 'output': '1 2 3'},
        ],
        functionSignature: 'def printNumbers(n):',
        initialCode: '''def printNumbers(n):
    # Write your solution here
    # Print numbers from 1 to n separated by space
    pass''',
        testCases: [
          TestCase(input: 5, expected: "1 2 3 4 5", description: "Basic test with n=5"),
          TestCase(input: 3, expected: "1 2 3", description: "Basic test with n=3"),
          TestCase(input: 1, expected: "1", description: "Edge case with n=1"),
          TestCase(input: 10, expected: "1 2 3 4 5 6 7 8 9 10", isHidden: true, description: "Hidden test with n=10"),
          TestCase(input: 0, expected: "", isHidden: true, description: "Edge case with n=0"),
        ],
        hint: 'Use a loop to iterate from 1 to n and print each number.',
      ),

      // Level 2: Sum of First N Numbers
      Question(
        title: 'Sum of First N Numbers',
        description: 'Given a positive integer n, calculate and print the sum of first n natural numbers.',
        difficulty: 'Easy',
        constraints: [
          '1 ≤ n ≤ 1000',
          'Return the sum as an integer',
        ],
        examples: [
          {'input': 'n = 5', 'output': '15'},
          {'input': 'n = 10', 'output': '55'},
        ],
        functionSignature: 'def sumFirstN(n):',
        initialCode: '''def sumFirstN(n):
    # Write your solution here
    # Calculate sum of first n natural numbers
    pass''',
        testCases: [
          TestCase(input: 5, expected: "15", description: "Sum of 1+2+3+4+5 = 15"),
          TestCase(input: 3, expected: "6", description: "Sum of 1+2+3 = 6"),
          TestCase(input: 10, expected: "55", isHidden: true, description: "Sum of 1 to 10"),
        ],
        hint: 'You can use a loop or the mathematical formula n*(n+1)/2.',
      ),

      // Level 3: Check Even or Odd
      Question(
        title: 'Check Even or Odd',
        description: 'Given an integer, print "Even" if the number is even, otherwise print "Odd".',
        difficulty: 'Easy',
        constraints: [
          '-1000 ≤ n ≤ 1000',
          'Print exactly "Even" or "Odd"',
        ],
        examples: [
          {'input': 'n = 4', 'output': 'Even'},
          {'input': 'n = 7', 'output': 'Odd'},
        ],
        functionSignature: 'def checkEvenOdd(n):',
        initialCode: '''def checkEvenOdd(n):
    # Write your solution here
    # Print "Even" if n is even, "Odd" if n is odd
    pass''',
        testCases: [
          TestCase(input: 4, expected: "Even", description: "4 is even"),
          TestCase(input: 7, expected: "Odd", description: "7 is odd"),
          TestCase(input: 0, expected: "Even", isHidden: true, description: "0 is even"),
          TestCase(input: -3, expected: "Odd", isHidden: true, description: "-3 is odd"),
        ],
        hint: 'Use the modulus operator (%) to check for divisibility by 2.',
      ),

      // Level 3: Check Even or Odd
      Question(
        title: 'Check Even or Odd',
        description: 'Given an integer, print "Even" if the number is even, otherwise print "Odd".',
        difficulty: 'Easy',
        constraints: [
          '-1000 ≤ n ≤ 1000',
          'Print exactly "Even" or "Odd"',
        ],
        examples: [
          {'input': 'n = 4', 'output': 'Even'},
          {'input': 'n = 7', 'output': 'Odd'},
        ],
        functionSignature: 'def checkEvenOdd(n):',
        initialCode: '''def checkEvenOdd(n):
    # Write your solution here
    # Print "Even" if n is even, "Odd" if n is odd
    pass''',
        testCases: [
          TestCase(input: 4, expected: "Even", description: "4 is even"),
          TestCase(input: 7, expected: "Odd", description: "7 is odd"),
          TestCase(input: 0, expected: "Even", isHidden: true, description: "0 is even"),
          TestCase(input: -3, expected: "Odd", isHidden: true, description: "-3 is odd"),
        ],
        hint: 'Use the modulus operator (%) to check for divisibility by 2.',
      ),
      // Add more easy questions here...
      // Level 3: Check Even or Odd
      Question(
        title: 'Check Even or Odd',
        description: 'Given an integer, print "Even" if the number is even, otherwise print "Odd".',
        difficulty: 'Easy',
        constraints: [
          '-1000 ≤ n ≤ 1000',
          'Print exactly "Even" or "Odd"',
        ],
        examples: [
          {'input': 'n = 4', 'output': 'Even'},
          {'input': 'n = 7', 'output': 'Odd'},
        ],
        functionSignature: 'def checkEvenOdd(n):',
        initialCode: '''def checkEvenOdd(n):
    # Write your solution here
    # Print "Even" if n is even, "Odd" if n is odd
    pass''',
        testCases: [
          TestCase(input: 4, expected: "Even", description: "4 is even"),
          TestCase(input: 7, expected: "Odd", description: "7 is odd"),
          TestCase(input: 0, expected: "Even", isHidden: true, description: "0 is even"),
          TestCase(input: -3, expected: "Odd", isHidden: true, description: "-3 is odd"),
        ],
        hint: 'Use the modulus operator (%) to check for divisibility by 2.',
      ),
      // Level 3: Check Even or Odd
      Question(
        title: 'Check Even or Odd',
        description: 'Given an integer, print "Even" if the number is even, otherwise print "Odd".',
        difficulty: 'Easy',
        constraints: [
          '-1000 ≤ n ≤ 1000',
          'Print exactly "Even" or "Odd"',
        ],
        examples: [
          {'input': 'n = 4', 'output': 'Even'},
          {'input': 'n = 7', 'output': 'Odd'},
        ],
        functionSignature: 'def checkEvenOdd(n):',
        initialCode: '''def checkEvenOdd(n):
    # Write your solution here
    # Print "Even" if n is even, "Odd" if n is odd
    pass''',
        testCases: [
          TestCase(input: 4, expected: "Even", description: "4 is even"),
          TestCase(input: 7, expected: "Odd", description: "7 is odd"),
          TestCase(input: 0, expected: "Even", isHidden: true, description: "0 is even"),
          TestCase(input: -3, expected: "Odd", isHidden: true, description: "-3 is odd"),
        ],
        hint: 'Use the modulus operator (%) to check for divisibility by 2.',
      ),
      // Level 3: Check Even or Odd
      Question(
        title: 'Check Even or Odd',
        description: 'Given an integer, print "Even" if the number is even, otherwise print "Odd".',
        difficulty: 'Easy',
        constraints: [
          '-1000 ≤ n ≤ 1000',
          'Print exactly "Even" or "Odd"',
        ],
        examples: [
          {'input': 'n = 4', 'output': 'Even'},
          {'input': 'n = 7', 'output': 'Odd'},
        ],
        functionSignature: 'def checkEvenOdd(n):',
        initialCode: '''def checkEvenOdd(n):
    # Write your solution here
    # Print "Even" if n is even, "Odd" if n is odd
    pass''',
        testCases: [
          TestCase(input: 4, expected: "Even", description: "4 is even"),
          TestCase(input: 7, expected: "Odd", description: "7 is odd"),
          TestCase(input: 0, expected: "Even", isHidden: true, description: "0 is even"),
          TestCase(input: -3, expected: "Odd", isHidden: true, description: "-3 is odd"),
        ],
        hint: 'Use the modulus operator (%) to check for divisibility by 2.',
      ),
      // Level 3: Check Even or Odd
      Question(
        title: 'Check Even or Odd',
        description: 'Given an integer, print "Even" if the number is even, otherwise print "Odd".',
        difficulty: 'Easy',
        constraints: [
          '-1000 ≤ n ≤ 1000',
          'Print exactly "Even" or "Odd"',
        ],
        examples: [
          {'input': 'n = 4', 'output': 'Even'},
          {'input': 'n = 7', 'output': 'Odd'},
        ],
        functionSignature: 'def checkEvenOdd(n):',
        initialCode: '''def checkEvenOdd(n):
    # Write your solution here
    # Print "Even" if n is even, "Odd" if n is odd
    pass''',
        testCases: [
          TestCase(input: 4, expected: "Even", description: "4 is even"),
          TestCase(input: 7, expected: "Odd", description: "7 is odd"),
          TestCase(input: 0, expected: "Even", isHidden: true, description: "0 is even"),
          TestCase(input: -3, expected: "Odd", isHidden: true, description: "-3 is odd"),
        ],
        hint: 'Use the modulus operator (%) to check for divisibility by 2.',
      ),
    ];
    return easyQuestions[(levelNumber - 1) % easyQuestions.length];
  }

  static Question _getMediumQuestion(int levelNumber) {
    final mediumQuestions = [
        // Level 1: Find Maximum in Array
      Question(
        title: 'Find Maximum in Array',
        description: 'Given a list of integers, find and print the maximum value.',
        difficulty: 'Medium',
        constraints: [
          'Array length: 1 ≤ len ≤ 1000',
          'Array contains at least one element'
        ],
        examples: [
          {'input': 'arr = [3, 1, 4, 1, 5]', 'output': '5'},
          {'input': 'arr = [-2, -1, -5]', 'output': '-1'},
        ],
        functionSignature: 'def findMax(arr):',
        initialCode: '''def findMax(arr):
    # Write your solution here
    # Find and print the maximum value in the array
    pass''',
        testCases: [
          TestCase(input: [3, 1, 4, 1, 5], expected: "5", description: "Max in positive numbers"),
          TestCase(input: [-2, -1, -5], expected: "-1", description: "Max in negative numbers"),
          TestCase(input: [100, 50, 200], expected: "200", isHidden: true, description: "Larger array"),
        ],
        hint: 'You can use the built-in max() function or iterate through the array.',
      ),
      // Add more medium questions here...
    ];
    return mediumQuestions[(levelNumber - 1) % mediumQuestions.length];
  }

  static Question _getHardQuestion(int levelNumber) {
    final hardQuestions = [
      // Level 1: Two Sum Problem
      Question(
        title: 'Two Sum',
        description: 'Given an array of integers and a target sum, find two numbers that add up to the target. Print their indices (0-based).',
        difficulty: 'Hard',
        constraints: [
          'Array length: 2 ≤ len ≤ 1000',
          'Exactly one solution exists',
          'Cannot use same element twice',
        ],
        examples: [
          {'input': 'arr = [2, 7, 11, 15], target = 9', 'output': '0 1'},
          {'input': 'arr = [3, 2, 4], target = 6', 'output': '1 2'},
        ],
        functionSignature: 'def twoSum(arr, target):',
        initialCode: '''def twoSum(arr, target):
    # Write your solution here
    # Find indices of two numbers that add up to target
    pass''',
        testCases: [
          TestCase(input: [[2, 7, 11, 15], 9], expected: "0 1", description: "2 + 7 = 9"),
          TestCase(input: [[3, 2, 4], 6], expected: "1 2", description: "2 + 4 = 6"),
          TestCase(input: [[-1, 0, 1, 2], 1], expected: "2 3", isHidden: true, description: "-1 + 2 = 1"),
        ],
        hint: 'Use a hash map to store values and their indices for an O(n) solution.',
      ),
      // Add more hard questions here...
    ];
    return hardQuestions[(levelNumber - 1) % hardQuestions.length];
  }
}
