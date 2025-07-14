
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ronda_vigilante/services/api_service.dart';

class RondasListScreen extends StatefulWidget {
  const RondasListScreen({super.key});

  @override
  State<RondasListScreen> createState() => _RondasListScreenState();
}

class _RondasListScreenState extends State<RondasListScreen> {
  final ApiService _apiService = ApiService();
  Future<List<dynamic>>? _rondasFuture;
  bool _carregado = false;

  @override
  void initState() {
    super.initState();
    // Aguarda a primeira renderização antes de carregar as rondas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarRondas();
    });
  }

  void _carregarRondas() {
    setState(() {
      _rondasFuture = _apiService.getRondas();
      _carregado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_carregado || _rondasFuture == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rondas Realizadas'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rondas Realizadas'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _rondasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erro ao carregar dados: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma ronda encontrada.'));
          }

          final rondas = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _carregarRondas();
            },
            child: ListView.builder(
              itemCount: rondas.length,
              itemBuilder: (context, index) {
                final ronda = rondas[index];
                final dataInicio = DateTime.parse(ronda['data_inicio']);
                final formattedDate = DateFormat('dd/MM/yyyy HH:mm')
                    .format(dataInicio.toLocal());

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.route, color: Colors.blue),
                    title: Text('Ronda #${ronda['id']}'),
                    subtitle: Text(
                      'Iniciada em: $formattedDate\nPor: ${ronda['vigilante_username']}',
                    ),
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
