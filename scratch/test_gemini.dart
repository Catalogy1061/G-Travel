import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyAgu27CSYQ_wsAI2Gg59wJnEZjYbDYikiA';
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  
  try {
    print('Testando gemini-1.5-flash...');
    final response = await model.generateContent([Content.text('Olá, você está funcionando?')]);
    print('Resposta: ${response.text}');
  } catch (e) {
    print('Erro gemini-1.5-flash: $e');
  }

  final modelPro = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  try {
    print('\nTestando gemini-pro...');
    final response = await modelPro.generateContent([Content.text('Olá, você está funcionando?')]);
    print('Resposta: ${response.text}');
  } catch (e) {
    print('Erro gemini-pro: $e');
  }
}
