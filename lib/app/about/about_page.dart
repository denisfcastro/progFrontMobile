import 'package:flutter/material.dart';
import 'package:routefly/routefly.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre o Projeto'),
        actions: [
          IconButton(
            onPressed: () {
              Routefly.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar tela inicial',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exemplo de Contador com Signals',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Este projeto demonstra como utilizar o novo sistema de gestão de estado com Signals no Flutter. '
                  'A aplicação implementa um contador simples que utiliza Signals para refletir alterações de estado '
                  'de forma reativa e eficiente na interface do usuário.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tecnologias utilizadas:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const BulletPoint(text: 'Flutter SDK'),
            const BulletPoint(text: 'Dart Language'),
            const BulletPoint(text: 'Signals para reatividade'),
            const BulletPoint(text: 'Gerenciamento de estado reativo'),
            const SizedBox(height: 24),
            const Text(
              'Autor:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Desenvolvido por [Seu Nome]',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      )
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;
  const BulletPoint({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
