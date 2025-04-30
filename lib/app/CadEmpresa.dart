import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CompanyFormPage extends StatefulWidget {
  final Map<String, dynamic>? empresa;

  const CompanyFormPage({super.key, this.empresa});

  @override
  State<CompanyFormPage> createState() => _CompanyFormPageState();
}

class _CompanyFormPageState extends State<CompanyFormPage> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  bool _isActive = true;
  int? _empresaId;

  @override
  void initState() {
    super.initState();

    if (widget.empresa != null) {
      _empresaId = widget.empresa!['id'];
      _companyNameController.text = widget.empresa!['nomeFantasia'] ?? '';
      _cnpjController.text = widget.empresa!['cnpj'] ?? '';
      _isActive = widget.empresa!['status'] ?? true;
    } else {
      _isActive = true;
    }
  }

  Future<void> _save() async {
    String nomeFantasia = _companyNameController.text;
    String cnpj = _cnpjController.text;
    bool status = _isActive;

    const String baseUrl = 'http://10.0.2.2:8080/api/v1/controllers';

    final uri = _empresaId == null
        ? Uri.parse(baseUrl)
        : Uri.parse('$baseUrl/$_empresaId');

    final method = _empresaId == null ? 'POST' : 'PUT';

    try {
      final response = await http.Request(method, uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'nomeFantasia': nomeFantasia,
          'cnpj': cnpj,
          'status': status,
        });

      final streamedResponse = await response.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sucesso'),
            content: Text(_empresaId == null
                ? 'Empresa cadastrada com sucesso!'
                : 'Empresa atualizada com sucesso!'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha o dialog
                  Navigator.of(context).pop(); // Volta para tela anterior
                },
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Erro ao salvar: ${streamedResponse.statusCode}\n$responseBody');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erro'),
          content: Text('Erro ao salvar: $e'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.empresa != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Empresa' : 'Cadastro de Empresa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            TextField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Empresa',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _cnpjController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CNPJ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Status Ativo',
                  style: TextStyle(fontSize: 16),
                ),
                Switch(
                  value: _isActive,
                  onChanged: widget.empresa == null ? null : (bool value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
