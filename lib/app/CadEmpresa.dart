import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class CompanyFormPage extends StatefulWidget {
  final Map<String, dynamic>? empresa;

  const CompanyFormPage({super.key, this.empresa});

  @override
  State<CompanyFormPage> createState() => _CompanyFormPageState();
}

class _CompanyFormPageState extends State<CompanyFormPage> {
  final AuthService _authService = AuthService();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  bool _isActive = true;
  int? _empresaId;
  bool _isSaving = false;

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
                  onChanged: (bool value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _save,
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final Map<String, dynamic> companyData = {
      if (_empresaId != null) 'id': _empresaId,
      'nomeFantasia': _companyNameController.text,
      'cnpj': _cnpjController.text,
      'status': _isActive,
    };

    try {
      http.Response response;
      if (_empresaId == null) {
        response = await _authService.post(
          'api/v1/controllers',
          body: companyData,
        );
      } else {
        response = await _authService.put(
          'api/v1/controllers/$_empresaId',
          body: companyData,
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Sucesso
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Sucesso'),
            content: Text(_empresaId == null
                ? 'Empresa cadastrada com sucesso!'
                : 'Empresa atualizada com sucesso!'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Falha ao salvar: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erro'),
          content: Text('Ocorreu um erro: $e'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
