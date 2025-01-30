import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOrUpdateUser(Map<String, dynamic> userData) async {
    try {
      final String playerName = userData['name'];
      final docRef = _firestore.collection('users2').doc(playerName);

     
      DocumentSnapshot snapshot = await docRef.get();

      if (!snapshot.exists) {
        await docRef.set({
          'playerInfo': {
            'name': userData['name'],
            'age': userData['age'],
            'gender': userData['gender'],
          },
          'gameSessions': [
            {
              'sessionNumber': 1,
              'createdAt': DateTime.now().toIso8601String(),
              'gameData': {
                'quitCount': 0,
                'attempts': 0,
                'successfulAttempts': 0,
                'timeTaken': 0,
                'difficulty': '',
                'completedAt': null,
              }
            }
          ]
        });

        print('Created new player document for: $playerName');
        return;
      }

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      List<dynamic> sessions = data['gameSessions'] ?? [];
      int nextSessionNumber = sessions.length + 1;

      sessions.add({
        'sessionNumber': nextSessionNumber,
        'createdAt': DateTime.now().toIso8601String(),
        'gameData': {
          'quitCount': 0,
          'attempts': 0,
          'successfulAttempts': 0,
          'timeTaken': 0,
          'difficulty': '',
          'completedAt': null,
        }
      });

      await docRef.update({
        'gameSessions': sessions
      });

      print('Added new session #$nextSessionNumber for player: $playerName');

    } catch (e) {
      print('Error creating/updating user: $e');
      rethrow;
    }
  }

  Future<void> updateGameData(String playerName, Map<String, dynamic> gameData, {bool isQuitting = false}) async {
    try {
      final docRef = _firestore.collection('users2').doc(playerName);

      DocumentSnapshot snapshot = await docRef.get();
      if (!snapshot.exists) {
        throw Exception('Player document not found');
      }

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      List<dynamic> sessions = List.from(data['gameSessions']);
      
      int currentSessionIndex = sessions.length - 1;
      Map<String, dynamic> currentSession = Map.from(sessions[currentSessionIndex]);


      if (isQuitting) {
        currentSession['gameData']['quitCount'] = (currentSession['gameData']['quitCount'] ?? 0) + 1;
      } else {
        currentSession['gameData'] = {
          ...currentSession['gameData'],
          ...gameData['gameData'] as Map<String, dynamic>,
        };
      }

      sessions[currentSessionIndex] = currentSession;

      await docRef.update({
        'gameSessions': sessions
      });

      print('Game data updated successfully for player: $playerName, session #${currentSession['sessionNumber']}');

    } catch (e) {
      print('Error updating game data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchUserData(String playerName) async {
    try {
      print('Fetching data for player: $playerName');
      DocumentSnapshot snapshot = await _firestore.collection('users2').doc(playerName).get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<dynamic> sessions = data['gameSessions'];
        Map<String, dynamic> latestSession = sessions.last;

        print('Successfully fetched player data: $data');
        return {
          'playerInfo': data['playerInfo'],
          'currentSession': latestSession,
          'totalSessions': sessions.length
        };
      }
      return null;
    } catch (e) {
      print('Error fetching player data: $e');
      rethrow;
    }
  }

  Future<void> calculateAndStorePercentile(String playerName, Map<String, dynamic> gameData) async {
    try {
      final docRef = _firestore.collection('users2').doc(playerName);
      DocumentSnapshot snapshot = await docRef.get();

      if (!snapshot.exists) {
        throw Exception('Player document not found');
      }

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      List<dynamic> sessions = List.from(data['gameSessions']);
      int currentSessionIndex = sessions.length - 1;
      Map<String, dynamic> currentSession = Map.from(sessions[currentSessionIndex]);

      QuerySnapshot allPlayerSnapshots = await _firestore
          .collection('users2')
          .where('gameSessions.gameData.difficulty', isEqualTo: gameData['difficulty'])
          .get();

      List<double> successRates = [];
      for (var playerDoc in allPlayerSnapshots.docs) {
        Map<String, dynamic> playerData = playerDoc.data() as Map<String, dynamic>;
        List<dynamic> playerSessions = playerData['gameSessions'];

        if (playerSessions.isNotEmpty) {
          Map<String, dynamic> lastSession = playerSessions.last;
          double successRate = lastSession['gameData']['successfulAttempts'] / lastSession['gameData']['attempts'];
          successRates.add(successRate);
        }
      }

      successRates.sort();
      double playerSuccessRate = currentSession['gameData']['successfulAttempts'] / currentSession['gameData']['attempts'];
      int lowerRatesCount = successRates.where((rate) => rate < playerSuccessRate).length;
      double percentile = (lowerRatesCount / successRates.length) * 100;


      currentSession['gameData']['percentile'] = percentile.roundToDouble();

      sessions[currentSessionIndex] = currentSession;

      await docRef.update({
        'gameSessions': sessions
      });

      print('Percentile calculated and stored: $percentile for player: $playerName');
    } catch (e) {
      print('Error calculating percentile: $e');
      rethrow;
    }
  }
}
