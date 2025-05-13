import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LevelManager extends ChangeNotifier {
  int currentLevel = 1;
  int highestUnlockedLevel = 1;
  final int maxLevels = 5;

  LevelManager() {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    currentLevel = prefs.getInt('currentLevel') ?? 1;
    highestUnlockedLevel = prefs.getInt('highestUnlockedLevel') ?? 1;
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentLevel', currentLevel);
    await prefs.setInt('highestUnlockedLevel', highestUnlockedLevel);
  }

  void setCurrentLevel(int level) {
    if (level <= highestUnlockedLevel && level <= maxLevels && level > 0) {
      currentLevel = level;
      _saveProgress();
      notifyListeners();
    }
  }

  void completeCurrentLevel() {
    if (currentLevel == highestUnlockedLevel && currentLevel < maxLevels) {
      highestUnlockedLevel++;
      currentLevel++;
      _saveProgress();
      notifyListeners();
    }
  }

  String getLevelName() {
    switch (currentLevel) {
      case 1:
        return 'Basic Movement';
      case 2:
        return 'Sequences';
      case 3:
        return 'Sensors';
      case 4:
        return 'Auto Mode';
      case 5:
        return 'Advanced Navigation';
      default:
        return 'Unknown Level';
    }
  }

  String getLevelDescription() {
    switch (currentLevel) {
      case 1:
        return 'Learn to control your robot with basic movement commands: forward, backward, left, right, and stop.';
      case 2:
        return 'Create a sequence of moves to navigate a path or maze.';
      case 3:
        return 'Use the ultrasonic sensor to detect obstacles and make decisions based on sensor readings.';
      case 4:
        return 'Activate auto mode for continuous navigation with obstacle avoidance.';
      case 5:
        return 'Combine all skills to create complex navigation programs.';
      default:
        return 'Description not available.';
    }
  }

  List<String> getAvailableBlocks() {
    List<String> blocks = [];

    // Basic blocks available at all levels
    blocks.addAll(
        ['move_forward', 'move_backward', 'turn_left', 'turn_right', 'wait']);

    // Add blocks based on level
    if (currentLevel >= 2) {
      blocks.add('repeat');
    }

    if (currentLevel >= 3) {
      blocks.addAll(['distance_sensor', 'if_then']);
    }

    if (currentLevel >= 5) {
      blocks.add('auto_mode');
    }

    return blocks;
  }
}
