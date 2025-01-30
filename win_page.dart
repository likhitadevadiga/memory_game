import 'package:flutter/material.dart';
import 'firestore_service.dart';

class WinPage extends StatefulWidget {
  const WinPage({super.key});

  @override
  _WinPageState createState() => _WinPageState();
}

class _WinPageState extends State<WinPage> {
  late Map<String, dynamic> args;
  double? percentile;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateAndStorePercentile();
    });
  }

  void _calculateAndStorePercentile() async {
    try {
      await _firestoreService.calculateAndStorePercentile(args['playerName'], {
        'difficulty': args['difficulty']
      });

      var userData = await _firestoreService.fetchUserData(args['playerName']);
      if (userData != null) {
        setState(() {
          percentile = userData['currentSession']['gameData']['percentile'];
        });
      }
    } catch (e) {
      print('Error calculating percentile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final int timeTaken = args['timeTaken'];
    final int attempts = args['attempts'];
    final int successfulAttempts = args['successfulAttempts'];
    final String difficulty = args['difficulty'];
    final String playerName = args['playerName'];

    final double successRate = successfulAttempts / attempts;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCB8B8),
        title: const Text("You Win!"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉 You Win! 🎉', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('Player: $playerName', style: const TextStyle(fontSize: 24)),
            Text('Time Taken: $timeTaken seconds', style: const TextStyle(fontSize: 24)),
            Text('Success Rate: ${(successRate * 100).toStringAsFixed(2)}%', style: const TextStyle(fontSize: 24)),
            Text('Difficulty: ${difficulty.toUpperCase()}', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            percentile != null
                ? Text('Your Percentile: ${percentile!.toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green))
                : const CircularProgressIndicator(),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC6C6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text('Play Again', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9A9A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Exit', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}