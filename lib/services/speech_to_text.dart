import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SpeechToTextService {
  final String? _apiKey = dotenv.env['GOOGLE_SPEECH_TO_TEXT_API_KEY'];


  final String _googleApiUrl =
      "https://speech.googleapis.com/v1/speech:recognize";

  SpeechToTextService() {
    // Verificação inicial da API Key (opcional, mas bom para debug)
    if (_apiKey == "SUA_GOOGLE_CLOUD_SPEECH_TO_TEXT_API_KEY" || _apiKey!.isEmpty) {
      print(
          "AVISO: A chave da API do Google Speech-to-Text não está configurada corretamente.");
    }
  }

  /// Transcreve um arquivo de áudio usando a API Google Cloud Speech-to-Text.
  ///
  /// [audioFilePath] é o caminho para o arquivo de áudio local.
  /// Retorna a transcrição como uma String, ou null se ocorrer um erro.
  Future<String?> transcribeAudioFile(String audioFilePath) async {
    if (_apiKey!.isEmpty) {
      print("Erro: API Key não configurada para SpeechToTextService.");
      return null;
    }

    try {
      final File audioFile = File(audioFilePath);
      if (!await audioFile.exists()) {
        print("Erro: Arquivo de áudio não encontrado em $audioFilePath");
        return null;
      }

      // Lê os bytes do arquivo de áudio e codifica em Base64
      final List<int> audioBytes = await audioFile.readAsBytes();
      final String base64Audio = base64Encode(audioBytes);

      // Constrói o corpo da requisição JSON
      // Consulte a documentação para todas as opções de configuração:
      // https://cloud.google.com/speech-to-text/docs/reference/rest/v1/speech/recognize#request-body
      final Map<String, dynamic> requestBody = {
        'config': {
          // 'encoding': 'LINEAR16', // Obrigatório se não for FLAC ou WAV com header explícito
          // 'sampleRateHertz': 16000, // Obrigatório se encoding for LINEAR16 ou FLAC
          'languageCode': 'pt-BR', // Exemplo: Português do Brasil. Mude conforme necessário.
          // 'audioChannelCount': 1, // Se for mono
          // 'enableAutomaticPunctuation': true, // Opcional
          // Você pode precisar especificar 'encoding' e 'sampleRateHertz'
          // explicitamente se o seu arquivo WAV não tiver um header que a API
          // possa inferir ou se estiver enviando áudio bruto (como LINEAR16).
          // Para arquivos WAV bem formados, a API muitas vezes consegue inferir.
          // Se tiver problemas, especifique-os:
          'encoding': 'LINEAR16',
          'sampleRateHertz': 16000, // Ajuste para a taxa de amostragem do seu áudio
        },
        'audio': {
          'content': base64Audio,
        }
      };

      final Uri requestUri = Uri.parse("$_googleApiUrl?key=$_apiKey");

      print("Enviando requisição para Speech-to-Text API...");
      final http.Response response = await http.post(
        requestUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        print("Resposta da API Speech-to-Text: $responseBody");

        // Extrai a transcrição
        // A estrutura da resposta pode variar um pouco, verifique a documentação
        // e o que sua API retorna.
        if (responseBody['results'] != null &&
            (responseBody['results'] as List).isNotEmpty) {
          final List<dynamic> results = responseBody['results'];
          if (results[0]['alternatives'] != null &&
              (results[0]['alternatives'] as List).isNotEmpty) {
            final String transcript =
            results[0]['alternatives'][0]['transcript'] as String;
            return transcript.trim();
          }
        }
        print(
            "Nenhuma transcrição encontrada na resposta da API, embora o status seja 200.");
        return ""; // Ou null, dependendo de como você quer tratar isso
      } else {
        print(
            "Erro ao chamar a API Speech-to-Text: ${response.statusCode}");
        print("Corpo da resposta: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exceção no SpeechToTextService: $e");
      return null;
    }
  }
}