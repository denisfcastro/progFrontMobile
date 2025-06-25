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
  final _formKey = GlobalKey<FormState>();
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
    }
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message'];
      }
      if (decoded is Map && decoded.containsKey('error')) {
        return decoded['error'];
      }
      return response.body;
    } catch (e) {
      return response.body;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final Map<String, dynamic> companyData = {
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

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSuccessDialog();
      } else {
        final errorMessage = _parseErrorMessage(response);
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Falha na comunicação com o servidor. Verifique sua conexão de rede e tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Sucesso!'),
          ],
        ),
        content: Text(_empresaId == null
            ? 'Empresa cadastrada com sucesso!'
            : 'Empresa atualizada com sucesso!'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o diálogo
              Navigator.of(context).pop(); // Retorna para a lista
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text('Ocorreu um Erro'),
          ],
        ),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.empresa != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Empresa' : 'Nova Empresa'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Fantasia',
                        prefixIcon: Icon(Icons.business_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'O nome da empresa é obrigatório.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _cnpjController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'CNPJ',
                        prefixIcon: Icon(Icons.pin_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'O CNPJ é obrigatório.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: const Text(
                        'Empresa Ativa',
                        style: TextStyle(fontSize: 16),
                      ),
                      value: _isActive,
                      onChanged: (bool value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      secondary: Icon(
                        _isActive ? Icons.check_circle_outline : Icons.highlight_off,
                        color: _isActive ? Colors.green : Colors.grey,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 30),
                    _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: _save,
                      child: const Text('Salvar', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}