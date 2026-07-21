/// A passive sliding buffer of activity sensor samples.
///
/// Holds at most [windowSize] samples, each a 4-feature vector
/// `[accX, accY, accZ, bpm]`. When a new sample pushes the buffer past
/// [windowSize], the oldest sample is trimmed from the front so the buffer
/// slides forward. This class owns no scheduling and triggers no inference —
/// callers decide when to read [isReady] and pull a window via [window].
class ActivitySampleBuffer {
  ActivitySampleBuffer({this.windowSize = 320});

  /// Number of samples that make up a full window (default 320, ~10s @ 32Hz).
  final int windowSize;

  final List<List<double>> _samples = [];

  /// Current number of buffered samples.
  int get length => _samples.length;

  /// Whether the buffer holds a full window of samples.
  bool get isReady => _samples.length >= windowSize;

  /// Appends [sample] to the buffer, trimming from the front when the buffer
  /// grows past [windowSize].
  ///
  /// Returns `false` and leaves the buffer unchanged when [sample] does not
  /// have exactly 4 features; returns `true` once the sample is stored.
  bool add(List<double> sample) {
    if (sample.length != 4) {
      return false;
    }

    _samples.add(sample);
    if (_samples.length > windowSize) {
      _samples.removeAt(0);
    }
    return true;
  }

  /// Returns a defensive copy of the buffered samples for inference.
  List<List<double>> window() => List<List<double>>.from(_samples);
}
