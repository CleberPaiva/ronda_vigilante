// lib/services/local_db_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'ronda_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE pontos_pendentes(id INTEGER PRIMARY KEY, ronda_id INTEGER, latitude REAL, longitude REAL, data_hora TEXT)",
        );
      },
    );
  }

  Future<void> inserirPontoPendente(
      int rondaId, double latitude, double longitude, String dataHora) async {
    final db = await database;
    await db.insert(
      'pontos_pendentes',
      {
        'ronda_id': rondaId,
        'latitude': latitude,
        'longitude': longitude,
        'data_hora': dataHora
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPontosPendentes() async {
    final db = await database;
    return await db.query('pontos_pendentes');
  }

  Future<void> deletarPontoPendente(int id) async {
    final db = await database;
    await db.delete(
      'pontos_pendentes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
