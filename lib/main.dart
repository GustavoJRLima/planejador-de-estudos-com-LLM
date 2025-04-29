import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
  runApp(const PlanejadorEstudosApp());
}

class PlanejadorEstudosApp extends StatelessWidget {
  const PlanejadorEstudosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planejador de Estudos',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const EstudoFormPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EstudoFormPage extends StatefulWidget {
  const EstudoFormPage({super.key});

  @override
  State<EstudoFormPage> createState() => _EstudoFormPageState();
}

class _EstudoFormPageState extends State<EstudoFormPage> {
  final _metasController = TextEditingController();
  final _disponibilidadeController = TextEditingController();

  String? _respostaIA;
  bool _carregando = false;

  String removerMarkdown(String texto) {
    return texto
        .replaceAllMapped(
          RegExp(r'(\*\*|__)(.*?)\1'),
          (match) => match.group(2)!,
        )
        .replaceAllMapped(RegExp(r'(\*|_)(.*?)\1'), (match) => match.group(2)!)
        .replaceAllMapped(RegExp(r'`([^`]*)`'), (match) => match.group(1)!)
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .replaceAllMapped(
          RegExp(r'\[(.*?)\]\((.*?)\)'),
          (match) => match.group(1)!,
        )
        .replaceAll(RegExp(r'^[-*+]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^>\s?', multiLine: true), '')
        .replaceAll(RegExp(r'\n{2,}'), '\n');
  }

  Future<void> _gerarPlano() async {
    setState(() {
      _carregando = true;
      _respostaIA = null;
    });

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyCx1GfgnES2TpROq-uEx_xDoZSbcHxpAN4',
    );

    final prompt =
        "Crie um plano de estudo personalizado com base nas seguintes metas: ${_metasController.text} e na disponibilidade: ${_disponibilidadeController.text}. O plano deve ser prático, dividido por dias e adaptado às metas.";

    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
      "generationConfig": {"temperature": 0.7, "topK": 40, "topP": 0.95},
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resposta = data['candidates'][0]['content']['parts'][0]['text'];

        setState(() {
          _respostaIA = resposta;
        });
      } else {
        setState(() {
          _respostaIA = "Erro ao obter resposta da IA.";
        });
      }
    } catch (e) {
      setState(() {
        _respostaIA = "Erro: $e";
      });
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planejador de Estudos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _metasController,
              decoration: const InputDecoration(
                labelText: 'Metas de estudo',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _disponibilidadeController,
              decoration: const InputDecoration(
                labelText: 'Disponibilidade semanal (ex: 2h por dia)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregando ? null : _gerarPlano,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              child: const Text('Gerar Plano com IA'),
            ),
            const SizedBox(height: 24),
            if (_carregando)
              const Center(child: CircularProgressIndicator())
            else if (_respostaIA != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Resultado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: removerMarkdown(_respostaIA!)),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Plano copiado para a área de transferência!',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar plano'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.42,
                    ),
                    child: Markdown(
                      data: _respostaIA!,
                      styleSheet: MarkdownStyleSheet(
                        h1: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        p: const TextStyle(fontSize: 16),
                        listBullet: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
