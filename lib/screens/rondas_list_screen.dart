import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ronda_vigilante/services/api_service.dart';

class RondasListScreen extends StatefulWidget {
  // ✅ 1. Adicionado construtor const com chave (key)
  const RondasListScreen({super.key});

  @override
  // ✅ Corrigido o tipo de retorno para o linter
  State<RondasListScreen> createState() => _RondasListScreenState();
}

class _RondasListScreenState extends State<RondasListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _rondasFuture;

  @override
  void initState() {
    super.initState();
    _rondasFuture = _apiService.getRondas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ 2. Adicionado 'const' para performance
      appBar: AppBar(title: const Text('Rondas Realizadas')),
      body: FutureBuilder<List<dynamic>>(
        future: _rondasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // ✅ 2. Adicionado 'const'
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                // ✅ 2. Adicionado 'const'
                padding: const EdgeInsets.all(16.0),
                child: Text('Erro ao carregar dados: ${snapshot.error}',
                    textAlign: TextAlign.center),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // ✅ 2. Adicionado 'const'
            return const Center(child: Text('Nenhuma ronda encontrada.'));
          }
          final rondas = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _rondasFuture = _apiService.getRondas();
              });
            },
            child: ListView.builder(
              itemCount: rondas.length,
              itemBuilder: (context, index) {
                final ronda = rondas[index];
                final dataInicio = DateTime.parse(ronda['data_inicio']);
                final formattedDate =
                    DateFormat('dd/MM/yyyy HH:mm').format(dataInicio.toLocal());
                return Card(
                  // ✅ 2. Adicionado 'const'
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    // ✅ 2. Adicionado 'const'
                    leading: const Icon(Icons.route, color: Colors.blue),
                    // Os Text widgets abaixo não podem ser const, pois usam dados variáveis
                    title: Text('Ronda #${ronda['id']}'),
                    subtitle: Text(
                        'Iniciada em: $formattedDate\nPor: ${ronda['vigilante_username']}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}