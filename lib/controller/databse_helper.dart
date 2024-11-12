

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Table and columns for storing user data
const String tableUsers = 'users';
const String columnId = 'id';
const String columnName = 'name';
const String columnFaceData = 'face_data'; // Store the face embeddings or features

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'attendance.db');
    return openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableUsers (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnName TEXT,
            $columnFaceData TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  Future<int> registerUser(String name, String faceData) async {
    final db = await database;
    final user = {
      columnName: name,
      columnFaceData: faceData, // Store the face embeddings or features here
    };
    return await db.insert(tableUsers, user);
  }

  Future<Map<String, dynamic>?> getUserByName(String name) async {
    final db = await database;
    final result = await db.query(
      tableUsers,
      where: '$columnName = ?',
      whereArgs: [name],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      tableUsers,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }


  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query(tableUsers);
  }

  // Close the database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
