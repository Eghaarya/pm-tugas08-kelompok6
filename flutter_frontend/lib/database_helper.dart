import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_database.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        stock INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total INTEGER NOT NULL,
        items TEXT NOT NULL
      )
    ''');

    // Insert initial products
    await db.insert('products', {
      'name': 'Kopi Hitam',
      'price': 15000,
      'stock': 50,
    });
    await db.insert('products', {
      'name': 'Cappuccino',
      'price': 25000,
      'stock': 35,
    });
    await db.insert('products', {'name': 'Latte', 'price': 28000, 'stock': 40});
    await db.insert('products', {
      'name': 'Teh Tarik',
      'price': 12000,
      'stock': 60,
    });
    await db.insert('products', {
      'name': 'Jus Jeruk',
      'price': 18000,
      'stock': 25,
    });
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    Database db = await database;
    return await db.query('products');
  }

  Future<int> insertProduct(String name, int price, int stock) async {
    Database db = await database;
    return await db.insert('products', {
      'name': name,
      'price': price,
      'stock': stock,
    });
  }

  Future<int> updateProduct(int id, String name, int price, int stock) async {
    Database db = await database;
    return await db.update(
      'products',
      {'name': name, 'price': price, 'stock': stock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(int id) async {
    Database db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertTransaction(int total, String items) async {
    Database db = await database;
    await db.insert('transactions', {
      'date': DateTime.now().toIso8601String(),
      'total': total,
      'items': items,
    });
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    Database db = await database;
    return await db.query('transactions', orderBy: 'date DESC');
  }
}
