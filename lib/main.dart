import 'package:flutter/material.dart';
import 'dart:math';
import 'quiz_data.dart'; // Import your QuizData utility
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Programming Quiz',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const QuizPage(),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Map<String, Object>> _questions = [];
  int _currentQuestionIndex = 0;
  bool _isAnswered = false;
  int _score = 0;
  static const int _maxScore = 500;
  static final List<int> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _loadLeaderboard();
  }

  Future<void> _loadQuestions() async {
    final questions = await QuizData.loadQuestions();
    setState(() {
      _questions = questions..shuffle(Random());
      _currentQuestionIndex = 0;
      _score = 0;
      _isAnswered = false;
    });
  }

  Future<void> _loadLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final scores = prefs.getStringList('leaderboard') ?? [];
    setState(() {
      _leaderboard.clear();
      _leaderboard.addAll(scores.map((s) => int.parse(s)).toList());
    });
  }

  Future<void> _saveLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'leaderboard', _leaderboard.map((s) => s.toString()).toList());
  }

  void _answerQuestion(bool isCorrect) {
    if (!_isAnswered) {
      setState(() {
        _isAnswered = true;
        if (isCorrect) {
          _score += 10;
          Future.delayed(const Duration(seconds: 1), () {
            setState(() {
              _currentQuestionIndex++;
              _isAnswered = false;
            });
          });
        } else {
          _leaderboard.add(_score);
          _leaderboard.sort((a, b) => b.compareTo(a));
          _saveLeaderboard();
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LostPage(onRetry: _loadQuestions),
              ),
            );
          });
        }
      });
    }
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: (_currentQuestionIndex + 1) / _questions.length,
      backgroundColor: Colors.grey[300],
      color: Colors.blue,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final int highestScore = _leaderboard.isNotEmpty ? _leaderboard.first : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programming Quiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: _loadQuestions,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Highest Score: $highestScore',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
            Text(
              'Maximum Score: $_maxScore',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 10),
            _buildProgressBar(),
            const SizedBox(height: 20),
            Text(
              _questions[_currentQuestionIndex]['question'] as String,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...( _questions[_currentQuestionIndex]['answers'] as List).map((answer) {
              final Map<String, Object> answerMap = answer as Map<String, Object>;
              return ElevatedButton(
                onPressed: () {
                  _answerQuestion(answerMap['isCorrect'] as bool);
                },
                child: Text(answerMap['text'] as String),
              );
            }).toList(),
            const Spacer(),
            Text(
              'Your Score: $_score',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class LostPage extends StatelessWidget {
  final VoidCallback onRetry;

  const LostPage({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const QuizPage()),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('You Lost'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Sorry, You Lost!\nTry Again',
              style: TextStyle(fontSize: 24, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
