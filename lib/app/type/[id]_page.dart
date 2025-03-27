import 'package:flutter/material.dart';
import 'package:routefly/routefly.dart';

class TypeEditPage extends StatefulWidget {
  const TypeEditPage({super.key});

  @override
  State<TypeEditPage> createState() => _TypeEditPageState();
}

class _TypeEditPageState extends State<TypeEditPage> {
  late final String tipoId;
  final TextEditingController _nameController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = Routefly.query['id'];
    if (args != null && !(args is String)) {
      tipoId = args.toString();
      // Aqui você pode buscar os dados do type usando o ID
      // Exemplo fictício:
      _nameController.text = 'Tipo $tipoId';
    } else {
      tipoId = 'unknown';
    }
  }

  void _salvar() {
    final nomeEditado = _nameController.text;
    // Salvar as alterações do type usando o tipoId e nomeEditado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tipo $tipoId salvo como "$nomeEditado"')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Tipo $tipoId'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Tipo',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvar,
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
