// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronda_vigilante/main.dart';

void main() {
  // Atualize a descrição do teste para ser mais significativa
  testWidgets('App starts with a loading indicator on AuthCheckScreen', (WidgetTester tester) async {
    // Constrói nosso app e renderiza um frame.
    // Esta chamada agora está correta após consertar o construtor do MyApp
    await tester.pumpWidget(const MyApp());

    // Verifica se nosso app inicia exibindo o indicador de carregamento
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Você também pode aguardar o timer e a navegação terminarem
    await tester.pump(const Duration(seconds: 2));

    // e então verificar se o indicador desapareceu.
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Nota: Para um teste real, você usaria um mock do SharedPreferences para checar
    // se a navegação ocorreu para a tela correta (Login ou Home).
  });
}