import 'package:flutter/material.dart';

import '../services/audio_recording.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AudioRecordingService _audioRecordingService = AudioRecordingService();
  String? _recordedFilePath;
  String _status = "Toque para Gravar";

  @override
  void dispose() {
    _audioRecordingService.dispose(); // Importante liberar recursos
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_audioRecordingService.isRecording) {
      final path = await _audioRecordingService.stopRecording();
      setState(() {
        _recordedFilePath = path;
        _status = path != null ? "Gravação Parada: $path" : "Falha ao parar";
      });
      if (path != null) {
        // Aqui você chamaria o seu SpeechToTextService
        print("Arquivo gravado em: $path. Pronto para transcrever.");
        // Exemplo:
        // final speechToTextService = SpeechToTextService();
        // final transcript = await speechToTextService.transcribeAudioFile(path);
        // print("Transcrição: $transcript");
      }
    } else {
      final started = await _audioRecordingService.startRecording();
      setState(() {
        _status = started ? "Gravando..." : "Falha ao iniciar";
        _recordedFilePath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_status),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleRecording,
              child: Text(_audioRecordingService.isRecording ? 'Parar Gravação' : 'Iniciar Gravação'),
            ),
            if (_recordedFilePath != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Caminho do Arquivo: $_recordedFilePath"),
              ),
          ],
        ),
      ),
    );
  }
}