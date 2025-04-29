import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projeto_modelo_20251/main.dart';
import 'package:routefly/routefly.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';
import 'package:signals/signals_flutter.dart';
import 'CadEmpresa.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> with SignalsMixin {
  final Signal<int> counter = Signal<int>(0);
  final Completer<void> _preferencesReady = Completer<void>();

  final Future<SharedPreferencesWithCache> _prefs = SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: <String>{'counter'},
    ),
  );

  // Lista de empresas
  List<Map<String, dynamic>> empresas = [];

  // Filtro
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  void _incrementCounter() {
    counter.value++;
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

  Future<void> _fetchEmpresas() async {
    const String url = 'http://10.0.2.2:8080/api/v1/controllers';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('Empresas recebidas: $data');  // Verificando o que veio da API
        setState(() {
          empresas = data.map((e) => e as Map<String, dynamic>).toList();
        });
      } else {
        debugPrint('Erro ao buscar empresas: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro de conexão: $e');
    }
  }



  @override
  void initState() {
    super.initState();

    _migratePreferences().then((_) {
      _prefs.then((SharedPreferencesWithCache prefs) {
        counter.value = prefs.getInt('counter') ?? 0;
        _preferencesReady.complete();
        counter.subscribe((value) async {
          final SharedPreferencesWithCache prefs = await _prefs;
          prefs.setInt('counter', counter.value);
        });
      });
    });

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });

    _fetchEmpresas();
  }

  void _navigateToAboutPage() {
    Routefly.push(routePaths.about);
  }

  _openTypeEditPage() {
    Routefly.push('${routePaths.type.path}/${counter.value}');
  }

  void _navigateToCompanyFormPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CompanyFormPage()),
    );
  }

  void _editCompany(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CompanyFormPage()),
    );
  }

  void _deleteCompany(int index) {
    setState(() {
      empresas.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lista filtrada por nome
    final filteredEmpresas = empresas.where((empresa) {
      final nome = empresa['nomeFantasia']?.toLowerCase() ?? '';
      return nome.contains(_searchText);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Empresas')),
      body: Center(
        child: _WaitForInitialization(
          initialized: _preferencesReady.future,
          builder: (BuildContext context) => Column(
            children: <Widget>[
              // Campo de busca
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar empresa',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // Lista de empresas
              Expanded(
                child: ListView.builder(
                  itemCount: filteredEmpresas.length,
                  itemBuilder: (context, index) {
                    final empresa = filteredEmpresas[index];
                    return ListTile(
                      title: Text(empresa['nomeFantasia'] ?? 'Empresa'),
                      subtitle: Text(
                        'CNPJ: ${empresa['cnpj'] ?? ''}\nStatus: ${empresa['status'] == true ? 'Ativo' : 'Inativo'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _editCompany(index);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteCompany(index);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCompanyFormPage,
        tooltip: 'Adicionar Empresa',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          BackButton(
            onPressed: () {},
          ),
          TextButton(
            onPressed: _navigateToAboutPage,
            child: const Text("Sobre"),
          ),
        ],
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
