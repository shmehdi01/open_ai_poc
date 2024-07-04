import 'dart:async';
import 'dart:math';
import 'dart:developer' as dev;
import 'dart:typed_data';

class SilenceDetector {
  static const double kSilenceThreshold = 0.1; // Adjust this threshold as needed
  static const int kSilenceDuration = 1000; // Minimum consecutive silent samples to detect silence

  late Stream<List<int>> _audioStream;
  late StreamSubscription<List<int>> _audioStreamSubscription;

  bool _isSilent = false;
  int _silenceCount = 0;



  SilenceDetector(this._audioStream) {
    _audioStreamSubscription = _audioStream.listen((samples) {
       detectSilence(samples);
    });
  }



 bool detectSilence(List<int> samples) {
    if (isNoise(samples)) {
      print("NOISE");
      return true; // Ignore samples considered as noise
    }

    double amplitude = calculateAmplitude(samples);
    //print("AMP $amplitude");
    if (amplitude < kSilenceThreshold) {
      _silenceCount++;
    } else {
      _silenceCount = 0;
    }

    if (_silenceCount >= kSilenceDuration) {
      if (!_isSilent) {
        _isSilent = true;
        // Trigger silence detected action here (e.g., pause recording)
        print('Silence detected');
      }
    } else {
      _isSilent = false;
    }

    return _isSilent;
  }

  static bool detectSilence2(Uint8List bytes) {
    // Assuming 16-bit PCM audio (adjust according to your audio format)
    int bytesPerSample = 2; // 16-bit = 2 bytes per sample
    int numSamples = bytes.length ~/ bytesPerSample;

    // Set thresholds for silence and sound (adjust based on your audio data)
    double silenceThreshold = 1000.0; // Example silence threshold
    double soundThreshold = 5000.0;   // Example sound threshold

    // Track max amplitude encountered
    double maxAmplitude = 0.0;

    // Calculate max amplitude
    for (int i = 0; i < numSamples; i++) {
      // Extract sample (assuming little-endian)
      int sample = bytes[i * bytesPerSample + 1] << 8 | bytes[i * bytesPerSample];

      // Convert to signed value (assuming signed 16-bit PCM)
      int signedSample = sample < 0x8000 ? sample : sample - 0x10000;

      // Calculate amplitude
      double amplitude = signedSample.abs().toDouble();

      print("APM $amplitude");
      // Update max amplitude
      if (amplitude > maxAmplitude) {
        maxAmplitude = amplitude;
      }
    }

    // Determine if audio is silence or sound based on max amplitude
    if (maxAmplitude < silenceThreshold) {
      return true; // Audio is considered silence
    } else if (maxAmplitude >= soundThreshold) {
      return false; // Audio is considered sound
    } else {
      // In between silence and sound thresholds, you can apply more sophisticated logic
      // or use RMS amplitude calculations for finer granularity.
      return false; // For simplicity, treat as sound
    }
  }


  static double calculateAmplitude(List<int> samples) {
    // Calculate Root Mean Square (RMS) amplitude of samples
    double rms = 0.0;
    for (int i = 0; i < samples.length; i++) {
      rms += pow(samples[i].toDouble(), 2);
    }
    rms = sqrt(rms / samples.length);
    return rms;
  }

  bool isNoise(List<int> samples) {
    // Example: Check if samples are below a certain noise threshold
    double noiseThreshold = 10.0; // Adjust this threshold as needed
    double amplitude = calculateAmplitude(samples);
    return amplitude < noiseThreshold;
  }

  void dispose() {
    _audioStreamSubscription.cancel();
  }
}