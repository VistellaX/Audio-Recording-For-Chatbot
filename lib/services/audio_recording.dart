import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart'; // Para obter o diretório de armazenamento
import 'dart:io'; // Para operações de File

class AudioRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentFilePath; // Para armazenar o caminho do arquivo da gravação atual
  bool _isRecording = false;

  AudioRecordingService() {
    // Você pode adicionar ouvintes de estado aqui se precisar
    // _audioRecorder.onStateChanged().listen((recordState) {
    //   print("Estado da gravação: $recordState");
    // });
  }

  bool get isRecording => _isRecording;

  /// Inicia a gravação de áudio.
  /// Retorna true se a gravação foi iniciada com sucesso, false caso contrário.
  Future<bool> startRecording() async {
    if (_isRecording) {
      print("A gravação já está em andamento.");
      return false;
    }

    try {
      // Verifica e solicita permissão
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
        // Você pode usar getTemporaryDirectory() se preferir arquivos temporários
        // final Directory tempDir = await getTemporaryDirectory();

        // Define o caminho do arquivo. Use um nome de arquivo único, por exemplo, com timestamp.
        final String fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        _currentFilePath = '${appDocumentsDir.path}/$fileName';

        // Configuração da gravação
        // Para a API do Google Speech-to-Text, PCM (LINEAR16) é uma boa escolha.
        // O pacote 'record' usa 'pcm16bit' para isso quando o formato é .wav.
        const recordConfig = RecordConfig(
          encoder: AudioEncoder.pcm16bits, // Equivalente a LINEAR16 para WAV
          sampleRate: 16000, // Taxa de amostragem recomendada para Speech-to-Text
          numChannels: 1,    // Mono
          // autoGain: true, // Opcional
          // echoCancel: true, // Opcional
        );

        print("Iniciando gravação para: $_currentFilePath");
        await _audioRecorder.start(recordConfig, path: _currentFilePath!);
        _isRecording = true;
        print("Gravação iniciada.");
        return true;
      } else {
        print("Permissão de gravação negada.");
        // Aqui você pode querer mostrar uma mensagem ao usuário ou solicitar a permissão novamente.
        return false;
      }
    } catch (e) {
      print("Erro ao iniciar a gravação: $e");
      _isRecording = false;
      _currentFilePath = null;
      return false;
    }
  }

  /// Para a gravação de áudio.
  /// Retorna o caminho do arquivo de áudio gravado, ou null se a gravação não
  /// foi parada corretamente ou não estava em andamento.
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      print("Nenhuma gravação em andamento para parar.");
      return null;
    }

    try {
      final String? path = await _audioRecorder.stop();
      _isRecording = false;
      print("Gravação parada. Arquivo salvo em: $path");

      // O caminho retornado por _audioRecorder.stop() deve ser o mesmo que _currentFilePath
      // mas é bom usar o valor retornado diretamente.
      // Se _currentFilePath foi usado, você pode retorná-lo aqui também,
      // mas o 'path' de stop() é mais direto.
      final String? resultPath = _currentFilePath;
      _currentFilePath = null; // Limpa o caminho para a próxima gravação
      return resultPath; // Ou path, se preferir

    } catch (e) {
      print("Erro ao parar a gravação: $e");
      _isRecording = false; // Garante que o estado seja resetado
      _currentFilePath = null;
      return null;
    }
  }

  /// Cancela uma gravação em andamento, se houver, e descarta o arquivo.
  Future<void> cancelRecording() async {
    if (!_isRecording) {
      print("Nenhuma gravação em andamento para cancelar.");
      return;
    }
    try {
      await _audioRecorder.stop(); // Para a gravação
      print("Gravação cancelada.");
      if (_currentFilePath != null) {
        final file = File(_currentFilePath!);
        if (await file.exists()) {
          await file.delete();
          print("Arquivo de gravação cancelada excluído: $_currentFilePath");
        }
      }
    } catch (e) {
      print("Erro ao cancelar/parar gravação: $e");
    } finally {
      _isRecording = false;
      _currentFilePath = null;
    }
  }


  /// Libera os recursos do gravador. Chame isso quando o serviço não for mais necessário.
  void dispose() {
    _audioRecorder.dispose();
    print("AudioRecordingService disposed.");
  }
}