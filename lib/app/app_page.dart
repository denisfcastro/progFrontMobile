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
  final Future<SharedPreferencesWithCache> _prefs = SharedPreferencesWithCache.create(
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
    const SharedPreferencesOptions sharedPreferencesOptions = SharedPreferencesOptions();
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

  void _navigateToAboutPage() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage()));
  }

  void _navigateToCompanyFormPage() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyFormPage()),);
    _consultarEmpresas();
  }

  void _editCompany(int index) async {
    final empresa = _filteredEmpresas()[index];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyFormPage(empresa: empresa),
      ),
    );
    _consultarEmpresas();
  }

  Future<void> _consultarEmpresas() async {
    setState(() => _isLoading = true);
    try {
      final response = await _authService.get('api/v1/controllers');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          empresas = data.map((e) => e as Map<String, dynamic>).toList();
        });
      } else {
        _showSnackBar('Erro ao carregar dados: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Erro de conexão ao carregar dados.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _deleteCompany(int index) async {
    final empresa = _filteredEmpresas()[index];
    final bool? confirm = await _showDeleteConfirmationDialog(empresa);

    if (confirm == true) {
      final int empresaId = empresa['id'];
      try {
        final response = await _authService.delete('api/v1/controllers/$empresaId');
        if (response.statusCode == 200) {
          _showSnackBar('Empresa excluída com sucesso!');
          _consultarEmpresas(); // Recarrega a lista
        } else {
          throw Exception('Erro ao excluir: ${response.statusCode}');
        }
      } catch (e) {
        _showSnackBar('Erro ao excluir empresa: $e');
      }
    }
  }

  List<Map<String, dynamic>> _filteredEmpresas() {
    return empresas.where((empresa) {
      final nome = empresa['nomeFantasia']?.toLowerCase() ?? '';
      return nome.contains(_searchText);
    }).toList();
  }

  List<Map<String, dynamic>> _paginatedEmpresas() {
    final filtered = _filteredEmpresas();
    final start = _currentPage * _itemsPerPage;
    final end = start + _itemsPerPage;
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  Future<bool?> _showDeleteConfirmationDialog(Map<String, dynamic> empresa) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir a empresa "${empresa['nomeFantasia']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Incluir Empresa'),
            onTap: () {
              Navigator.pop(context);
              _navigateToCompanyFormPage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
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
    if(totalPages == 0) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentPage > 0
              ? () => setState(() => _currentPage--)
              : null,
        ),
        Text('Página ${_currentPage + 1} de $totalPages'),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: _currentPage < totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );
  }

  Widget _buildCompanyList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final empresasPaginadas = _paginatedEmpresas();

    if(empresasPaginadas.isEmpty){
      return const Center(child: Text("Nenhuma empresa encontrada."));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: empresasPaginadas.length,
            itemBuilder: (context, index) {
              final empresa = empresasPaginadas[index];
              return ListTile(
                title: Text(empresa['nomeFantasia'] ?? 'Empresa',
                    style: const TextStyle(fontSize: 20)),
                subtitle: Text(
                  'CNPJ: ${empresa['cnpj'] ?? ''}\nStatus: ${empresa['status'] == true ? 'Ativo' : 'Inativo'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editCompany(index + _currentPage * _itemsPerPage),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCompany(index + _currentPage * _itemsPerPage),
                    ),
                  ],
                ),
              );
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
      appBar: AppBar(title: const Text('Lista de Empresas')),
      drawer: _buildDrawer(),
      body: Center(
        child: _WaitForInitialization(
          initialized: _preferencesReady.future,
          builder: (BuildContext context) => Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar empresa',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              Expanded(child: _buildCompanyList()),
            ],
          ),
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
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return const CircularProgressIndicator();
        }
        return builder(context);
      },
    );
  }
}
