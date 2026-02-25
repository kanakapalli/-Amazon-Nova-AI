import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:record/record.dart'; // Added for audio recording
import 'package:just_audio/just_audio.dart'; // Replaced audioplayers for better Web base64 support
import '../../core/api/api_client.dart';

class NovaSonicScreen extends StatefulWidget {
  const NovaSonicScreen({super.key});

  @override
  State<NovaSonicScreen> createState() => _NovaSonicScreenState();
}

class _NovaSonicScreenState extends State<NovaSonicScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late AnimationController _animationController;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer(); // This is now from just_audio

  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusMessage = 'Tap the microphone and speak...';
  String? _responseAudioBase64; // Will hold the response audio if needed
  String? _responseText;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleMockRecording() async {
    if (_isProcessing) return;

    if (_isRecording) {
      // Stop recording
      await _stopRecording();
    } else {
      // Start recording
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        setState(() {
          _isRecording = true;
          _responseText = null;
          _responseAudioBase64 = null;
          _statusMessage = 'Listening...';
        });
        await _audioRecorder.start(
          const RecordConfig(),
          path: '',
        ); // In-memory/stream configuration could go here, or record to temp file.
        // For simplicity in web/cross-platform without saving to file, stream is better. Let's record to a temporary file or stream.
        // Or simple: start stream.
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
      setState(() {
        _isRecording = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final String? path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _isProcessing = true;
          _statusMessage = 'Processing audio...';
        });

        // In a real scenario, you would read the file from 'path'
        // and convert it to base64. For this example, we'll simulate.
        // For web, `path` might be a blob URL or similar, requiring different handling.
        // For simplicity, let's assume we get a byte array or similar.
        // Here, we'll just use a placeholder base64 string.
        final String audioBase64 = base64Encode(
          utf8.encode('mock audio data'),
        ); // Replace with actual audio data

        final response = await _apiClient.askNovaSonic(audioBase64);

        setState(() {
          _isProcessing = false;
          _statusMessage = 'Tap to speak again';
          _responseText =
              response['text_reply'] ?? 'Voice interaction complete.';
          _responseAudioBase64 = response['audio_reply_base64'];
        });

        if (_responseAudioBase64 != null && _responseAudioBase64!.isNotEmpty) {
          // Play the response audio using a Data URI, which is supported on Web by just_audio
          // We need just_audio to parse the setUrl with the base64 prefix
          final dataUri = 'data:audio/mp3;base64,\${_responseAudioBase64}';
          try {
            await _audioPlayer.setUrl(dataUri);
            await _audioPlayer.play();
          } catch (e) {
            debugPrint('Audio playback error: $e');
          }
        }
      } else {
        setState(() {
          _isRecording = false;
          _statusMessage = 'Recording stopped, but no audio path found.';
        });
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
      setState(() {
        _isRecording = false;
        _isProcessing = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova 2 Sonic')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Amazon Nova 2 Sonic is a state-of-the-art multimodal model supporting near real-time voice and audio processing.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            if (_responseText != null && _responseText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  _responseText!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            const Spacer(),
            Text(
              _statusMessage,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _isProcessing ? null : _toggleMockRecording,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? Colors.red.withOpacity(
                              0.5 + (_animationController.value * 0.5),
                            )
                          : _isProcessing
                          ? Theme.of(context).primaryColor.withOpacity(
                              0.5 + (_animationController.value * 0.5),
                            )
                          : Theme.of(context).primaryColor,
                      boxShadow: [
                        if (_isRecording || _isProcessing)
                          BoxShadow(
                            color:
                                (_isRecording
                                        ? Colors.red
                                        : Theme.of(context).primaryColor)
                                    .withOpacity(0.6),
                            blurRadius: 30 * _animationController.value,
                            spreadRadius: 10 * _animationController.value,
                          ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      size: 64,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}
