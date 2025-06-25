import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';
import 'package:signals/signals_flutter.dart';

import '../services/auth_service.dart';
import 'CadEmpresa.dart';
import 'about/about_page.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> with SignalsMixin {
  final AuthService _authService = AuthService();

  final Signal<int> counter = Signal<int>(0);
  final Completer<void> _preferencesReady = Completer<void>();
  final Future<SharedPreferencesWithCache> _prefs =
  SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: <String>{'counter'},
    ),
  );

  List<Map<String, dynamic>> empresas = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  bool _isLoading = true;

  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
    _initializeSearchListener();
    _consultarEmpresas();
  }


  Future<void> _initializePreferences() async {
    await _migratePreferences();
    _prefs.then((SharedPreferencesWithCache prefs) {
      counter.value = prefs.getInt('counter') ?? 0;
      _preferencesReady.complete();
      counter.subscribe((value) async {
        final SharedPreferencesWithCache prefs = await _prefs;
        prefs.setInt('counter', counter.value);
      });
    });
  }

  Future<void> _migratePreferences() async {
    const SharedPreferencesOptions sharedPreferencesOptions =
    SharedPreferencesOptions();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: prefs,
      sharedPreferencesAsyncOptions: sharedPreferencesOptions,
      migrationCompletedKey: 'migrationCompleted',
    );
  }

  void _initializeSearchListener() {
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
        _currentPage = 0;
      });
    });
  }

  Future<void> _consultarEmpresas() async {
    setState(() => _isLoading = true);
    try {
      final response = await _authService.get('api/v1/controllers');
      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          setState(() {
            empresas = data.map((e) => e as Map<String, dynamic>).toList();
          });
        } else {
          _showSnackBar('Erro ao carregar dados: ${response.statusCode}', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro de conexão ao carregar dados.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  void _navigateToAboutPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const AboutPage()));
  }

  void _navigateToCompanyFormPage({Map<String, dynamic>? empresa}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyFormPage(empresa: empresa),
      ),
    );
    _consultarEmpresas();
  }

  void _deleteCompany(int index) async {
    final empresa = _filteredEmpresas()[index];
    final bool? confirm = await _showDeleteConfirmationDialog(empresa);

    if (confirm == true) {
      final int empresaId = empresa['id'];
      try {
        final response =
        await _authService.delete('api/v1/controllers/$empresaId');
        if (mounted) {
          if (response.statusCode == 200) {
            _showSnackBar('Empresa excluída com sucesso!');
            _consultarEmpresas();
          } else {
            throw Exception('Erro ao excluir: ${response.statusCode}');
          }
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Erro ao excluir empresa: $e', isError: true);
        }
      }
    }
  }


  List<Map<String, dynamic>> _filteredEmpresas() {
    if (_searchText.isEmpty) {
      return empresas;
    }
    return empresas.where((empresa) {
      final nome = empresa['nomeFantasia']?.toLowerCase() ?? '';
      return nome.contains(_searchText);
    }).toList();
  }

  List<Map<String, dynamic>> _paginatedEmpresas() {
    final filtered = _filteredEmpresas();
    final start = _currentPage * _itemsPerPage;
    final end = start + _itemsPerPage;
    return filtered.sublist(
        start, end > filtered.length ? filtered.length : end);
  }

  Future<bool?> _showDeleteConfirmationDialog(Map<String, dynamic> empresa) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
            'Tem certeza que deseja excluir a empresa "${empresa['nomeFantasia']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ));
  }



  Widget _buildDrawerHeader() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 60),
            SizedBox(height: 16),
            Text(
              'Menu Principal',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          ListTile(
            leading: const Icon(Icons.business_center_outlined),
            title: const Text('Cadastrar Empresa'),
            onTap: () {
              Navigator.pop(context);
              _navigateToCompanyFormPage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre o Projeto'),
            onTap: () {
              Navigator.pop(context);
              _navigateToAboutPage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_filteredEmpresas().length / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
          ),
          Text(
            'Página ${_currentPage + 1} de $totalPages',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> empresa) {
    final bool isActive = empresa['status'] == true;
    final int globalIndex = empresas.indexOf(empresa);

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              empresa['nomeFantasia'] ?? 'Nome não informado',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              'CNPJ: ${empresa['cnpj'] ?? 'Não informado'}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8.0),
            Chip(
              label: Text(isActive ? 'Ativo' : 'Inativo'),
              backgroundColor: isActive ? Colors.green.shade100 : Colors.grey.shade300,
              labelStyle: TextStyle(color: isActive ? Colors.green.shade800 : Colors.grey.shade800),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
            const Divider(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
                  onPressed: () => _navigateToCompanyFormPage(empresa: empresa),
                  tooltip: 'Editar',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _deleteCompany(globalIndex),
                  tooltip: 'Excluir',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final empresasPaginadas = _paginatedEmpresas();

    if (empresasPaginadas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text("Nenhuma empresa encontrada.", style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: empresasPaginadas.length,
            itemBuilder: (context, index) {
              final empresa = empresasPaginadas[index];
              return _buildCompanyCard(empresa);
            },
          ),
        ),
        _buildPaginationControls(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Empresas'),
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
      drawer: _buildDrawer(),
      body: _WaitForInitialization(
        initialized: _preferencesReady.future,
        builder: (BuildContext context) => Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar por nome fantasia...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            Expanded(child: _buildCompanyList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCompanyFormPage,
        tooltip: 'Adicionar Empresa',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _WaitForInitialization extends StatelessWidget {
  const _WaitForInitialization({
    required this.initialized,
    required this.builder,
  });

  final Future<void> initialized;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: initialized,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return builder(context);
      },
    );
  }
}