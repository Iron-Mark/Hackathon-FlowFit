import 'dart:async';

/// Service for managing workout timers
class TimerService {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  final StreamController<int> _timerController =
      StreamController<int>.broadcast();

  /// Stream of elapsed seconds
  Stream<int> get timerStream => _timerController.stream;

  /// Current elapsed seconds
  int get elapsedSeconds => _elapsedSeconds;

  /// Whether timer is currently running
  bool get isRunning => _isRunning;

  /// Whether timer is paused
  bool get isPaused => _isPaused;

  /// Formatted time string (MM:SS)
  String get formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Starts the timer from 0 or resumes from paused state
  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _isPaused = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      _timerController.add(_elapsedSeconds);
    });
  }

  /// Pauses the timer
  void pause() {
    if (!_isRunning || _isPaused) return;

    _timer?.cancel();
    _isRunning = false;
    _isPaused = true;
  }

  /// Resumes the timer from paused state
  void resume() {
    if (!_isPaused) return;

    _isPaused = false;
    start();
  }

  /// Stops the timer and resets to 0
  void stop() {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    _elapsedSeconds = 0;
    _timerController.add(_elapsedSeconds);
  }

  /// Resets the timer to 0 without stopping
  void reset() {
    _elapsedSeconds = 0;
    _timerController.add(_elapsedSeconds);
  }

  /// Sets the elapsed time (for restoring state)
  void setElapsedSeconds(int seconds) {
    _elapsedSeconds = seconds;
    _timerController.add(_elapsedSeconds);
  }

  /// Disposes resources
  void dispose() {
    _timer?.cancel();
    _timerController.close();
  }
}

/// Service for countdown timers (rest periods)
class CountdownTimerService {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;

  final StreamController<int> _timerController =
      StreamController<int>.broadcast();

  /// Stream of remaining seconds
  Stream<int> get timerStream => _timerController.stream;

  /// Current remaining seconds
  int get remainingSeconds => _remainingSeconds;

  /// Whether timer is currently running
  bool get isRunning => _isRunning;

  /// Formatted time string (MM:SS)
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Starts countdown from specified seconds
  void start(int seconds) {
    if (_isRunning) return;

    _remainingSeconds = seconds;
    _isRunning = true;
    _timerController.add(_remainingSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      _timerController.add(_remainingSeconds);

      if (_remainingSeconds <= 0) {
        stop();
      }
    });
  }

  /// Stops the countdown timer
  void stop() {
    _timer?.cancel();
    _isRunning = false;
    _remainingSeconds = 0;
  }

  /// Skips the countdown (sets to 0)
  void skip() {
    _remainingSeconds = 0;
    _timerController.add(_remainingSeconds);
    stop();
  }

  /// Disposes resources
  void dispose() {
    _timer?.cancel();
    _timerController.close();
  }
}
