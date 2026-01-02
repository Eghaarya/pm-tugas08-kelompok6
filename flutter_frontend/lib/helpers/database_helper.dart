import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('apotek_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    print('📁 Database path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) {
        print('✅ Database opened successfully');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    print('🔨 Creating database tables...');

    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // Table Products
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        product_id $textType,
        name $textType,
        price $intType,
        stock $intType,
        unit $textType,
        category $textType,
        batch TEXT,
        exp_date TEXT,
        is_prescription INTEGER DEFAULT 0,
        created_at $textType,
        updated_at $textType
      )
    ''');
    print('✅ Table products created');

    // Table Customers
    await db.execute('''
      CREATE TABLE customers (
        id $idType,
        name $textType,
        phone TEXT,
        email TEXT,
        address TEXT,
        created_at $textType,
        updated_at $textType
      )
    ''');
    print('✅ Table customers created');

    // Table Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        invoice_number $textType,
        transaction_date $textType,
        transaction_time $textType,
        customer_id INTEGER,
        customer_name TEXT,
        kasir_name $textType,
        subtotal $intType,
        discount $intType,
        total $intType,
        payment_method $textType,
        payment_amount $intType,
        change_amount $intType,
        notes TEXT,
        created_at $textType
      )
    ''');
    print('✅ Table transactions created');

    // Table Transaction Items
    await db.execute('''
      CREATE TABLE transaction_items (
        id $idType,
        transaction_id $intType,
        product_id $textType,
        product_name $textType,
        quantity $intType,
        price $intType,
        total $intType,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
      )
    ''');
    print('✅ Table transaction_items created');

    // Insert dummy data
    await _insertDummyData(db);
    print('✅ Dummy data inserted');
  }

  Future _insertDummyData(Database db) async {
    final now = DateTime.now().toIso8601String();

    print('📦 Inserting dummy products...');

    // Insert dummy products
    await db.insert('products', {
      'product_id': 'OB001',
      'name': 'Paracetamol 500mg',
      'price': 500,
      'stock': 100,
      'unit': 'Tablet',
      'category': 'Obat Bebas',
      'batch': 'BTHOB001002',
      'exp_date': '2026-12-26',
      'is_prescription': 0,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('products', {
      'product_id': 'OB002',
      'name': 'Antangin JRG',
      'price': 2500,
      'stock': 50,
      'unit': 'Sachet',
      'category': 'Obat Bebas',
      'batch': 'BTHOB002002',
      'exp_date': '2026-12-26',
      'is_prescription': 0,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('products', {
      'product_id': 'OB003',
      'name': 'Promag Tablet',
      'price': 600,
      'stock': 75,
      'unit': 'Tablet',
      'category': 'Obat Bebas',
      'batch': 'BTHOB003001',
      'exp_date': '2026-12-26',
      'is_prescription': 0,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('products', {
      'product_id': 'OBT001',
      'name': 'Decolgen Tablet',
      'price': 800,
      'stock': 60,
      'unit': 'Tablet',
      'category': 'Obat Bebas Terbatas',
      'batch': 'BTHOB004001',
      'exp_date': '2026-12-26',
      'is_prescription': 0,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('products', {
      'product_id': 'OK001',
      'name': 'Amoxicillin 500mg',
      'price': 1000,
      'stock': 80,
      'unit': 'Kaplet',
      'category': 'Obat Keras',
      'batch': 'BTHOB005001',
      'exp_date': '2026-12-26',
      'is_prescription': 1,
      'created_at': now,
      'updated_at': now,
    });

    print('📦 Inserting dummy customers...');

    // Insert dummy customers
    await db.insert('customers', {
      'name': 'Budi Hartono',
      'phone': '081234567890',
      'email': 'budi@example.com',
      'address': 'Jl. Merdeka No. 123, Jakarta',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('customers', {
      'name': 'Siti Aminah',
      'phone': '081234567891',
      'email': 'siti@example.com',
      'address': 'Jl. Sudirman No. 456, Jakarta',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('customers', {
      'name': 'Ahmad Fauzi',
      'phone': '081234567892',
      'email': 'ahmad@example.com',
      'address': 'Jl. Gatot Subroto No. 789, Jakarta',
      'created_at': now,
      'updated_at': now,
    });

    print('✅ All dummy data inserted successfully');
  }

  // ========== PRODUCTS CRUD ==========
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final db = await database;
      final result = await db.query('products', orderBy: 'name ASC');
      print('📋 Loaded ${result.length} products');
      return result;
    } catch (e) {
      print('❌ Error getting products: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProduct(int id) async {
    try {
      final db = await database;
      final results = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('❌ Error getting product: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProductByProductId(String productId) async {
    try {
      final db = await database;
      final results = await db.query(
        'products',
        where: 'product_id = ?',
        whereArgs: [productId],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('❌ Error getting product by product_id: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchProducts(String keyword) async {
    try {
      final db = await database;
      final result = await db.query(
        'products',
        where: 'name LIKE ? OR product_id LIKE ?',
        whereArgs: ['%$keyword%', '%$keyword%'],
      );
      print('🔍 Found ${result.length} products for keyword: $keyword');
      return result;
    } catch (e) {
      print('❌ Error searching products: $e');
      rethrow;
    }
  }

  Future<int> insertProduct(Map<String, dynamic> product) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      product['created_at'] = now;
      product['updated_at'] = now;
      
      final id = await db.insert('products', product);
      print('✅ Product inserted with ID: $id');
      return id;
    } catch (e) {
      print('❌ Error inserting product: $e');
      rethrow;
    }
  }

  Future<int> updateProduct(int id, Map<String, dynamic> product) async {
    try {
      final db = await database;
      product['updated_at'] = DateTime.now().toIso8601String();
      
      final result = await db.update(
        'products',
        product,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Product updated: $result rows affected');
      return result;
    } catch (e) {
      print('❌ Error updating product: $e');
      rethrow;
    }
  }

  Future<int> deleteProduct(int id) async {
    try {
      final db = await database;
      final result = await db.delete('products', where: 'id = ?', whereArgs: [id]);
      print('✅ Product deleted: $result rows affected');
      return result;
    } catch (e) {
      print('❌ Error deleting product: $e');
      rethrow;
    }
  }

  Future<int> updateProductStock(String productId, int quantitySold) async {
    try {
      final db = await database;
      
      // Get current stock
      final product = await getProductByProductId(productId);
      if (product == null) {
        throw Exception('Product not found: $productId');
      }
      
      final currentStock = product['stock'] as int;
      final newStock = currentStock - quantitySold;
      
      if (newStock < 0) {
        throw Exception('Insufficient stock for product: $productId');
      }
      
      final result = await db.update(
        'products',
        {
          'stock': newStock,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'product_id = ?',
        whereArgs: [productId],
      );
      
      print('✅ Stock updated for $productId: $currentStock -> $newStock');
      return result;
    } catch (e) {
      print('❌ Error updating stock: $e');
      rethrow;
    }
  }

  // ========== CUSTOMERS CRUD ==========
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    try {
      final db = await database;
      final result = await db.query('customers', orderBy: 'name ASC');
      print('📋 Loaded ${result.length} customers');
      return result;
    } catch (e) {
      print('❌ Error getting customers: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCustomer(int id) async {
    try {
      final db = await database;
      final results = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('❌ Error getting customer: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchCustomers(String keyword) async {
    try {
      final db = await database;
      final result = await db.query(
        'customers',
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: ['%$keyword%', '%$keyword%'],
      );
      print('🔍 Found ${result.length} customers for keyword: $keyword');
      return result;
    } catch (e) {
      print('❌ Error searching customers: $e');
      rethrow;
    }
  }

  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      customer['created_at'] = now;
      customer['updated_at'] = now;
      
      final id = await db.insert('customers', customer);
      print('✅ Customer inserted with ID: $id');
      return id;
    } catch (e) {
      print('❌ Error inserting customer: $e');
      rethrow;
    }
  }

  Future<int> updateCustomer(int id, Map<String, dynamic> customer) async {
    try {
      final db = await database;
      customer['updated_at'] = DateTime.now().toIso8601String();
      
      final result = await db.update(
        'customers',
        customer,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Customer updated: $result rows affected');
      return result;
    } catch (e) {
      print('❌ Error updating customer: $e');
      rethrow;
    }
  }

  Future<int> deleteCustomer(int id) async {
    try {
      final db = await database;
      final result = await db.delete('customers', where: 'id = ?', whereArgs: [id]);
      print('✅ Customer deleted: $result rows affected');
      return result;
    } catch (e) {
      print('❌ Error deleting customer: $e');
      rethrow;
    }
  }

  // ========== TRANSACTIONS CRUD ==========
  Future<int> insertTransaction(
    Map<String, dynamic> transaction,
    List<Map<String, dynamic>> items,
  ) async {
    final db = await database;
    int? transactionId;
    
    try {
      // Start transaction
      await db.transaction((txn) async {
        print('💳 Starting transaction insert...');
        
        final now = DateTime.now().toIso8601String();
        transaction['created_at'] = now;

        // Insert transaction
        transactionId = await txn.insert('transactions', transaction);
        print('✅ Transaction inserted with ID: $transactionId');

        // Insert transaction items and update stock
        for (var item in items) {
          item['transaction_id'] = transactionId;
          await txn.insert('transaction_items', item);
          print('✅ Item inserted: ${item['product_name']} x ${item['quantity']}');

          // Update product stock
          final product = await txn.query(
            'products',
            where: 'product_id = ?',
            whereArgs: [item['product_id']],
          );

          if (product.isNotEmpty) {
            final currentStock = product.first['stock'] as int;
            final newStock = currentStock - (item['quantity'] as int);
            
            if (newStock < 0) {
              throw Exception('Insufficient stock for ${item['product_name']}');
            }
            
            await txn.update(
              'products',
              {
                'stock': newStock,
                'updated_at': now,
              },
              where: 'product_id = ?',
              whereArgs: [item['product_id']],
            );
            print('✅ Stock updated: ${item['product_name']} ($currentStock -> $newStock)');
          }
        }
      });

      print('✅ Transaction completed successfully!');
      return transactionId!;
    } catch (e) {
      print('❌ Error in transaction: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    try {
      final db = await database;
      final result = await db.query(
        'transactions',
        orderBy: 'created_at DESC',
      );
      print('📋 Loaded ${result.length} transactions');
      return result;
    } catch (e) {
      print('❌ Error getting transactions: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTransaction(int id) async {
    try {
      final db = await database;
      final results = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('❌ Error getting transaction: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionItems(
      int transactionId) async {
    try {
      final db = await database;
      final result = await db.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );
      print('📋 Loaded ${result.length} items for transaction $transactionId');
      return result;
    } catch (e) {
      print('❌ Error getting transaction items: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionsByDate(
      String startDate, String endDate) async {
    try {
      final db = await database;
      final result = await db.query(
        'transactions',
        where: 'transaction_date BETWEEN ? AND ?',
        whereArgs: [startDate, endDate],
        orderBy: 'created_at DESC',
      );
      print('📋 Found ${result.length} transactions between $startDate and $endDate');
      return result;
    } catch (e) {
      print('❌ Error getting transactions by date: $e');
      rethrow;
    }
  }

  // ========== REPORTS & STATISTICS ==========
  Future<Map<String, dynamic>> getDailySummary(String date) async {
    try {
      final db = await database;

      final transactions = await db.query(
        'transactions',
        where: 'transaction_date = ?',
        whereArgs: [date],
      );

      int totalSales = 0;
      int totalTransactions = transactions.length;

      for (var trans in transactions) {
        totalSales += trans['total'] as int;
      }

      // Get total items sold
      final itemsResult = await db.rawQuery('''
        SELECT SUM(ti.quantity) as total_items
        FROM transaction_items ti
        INNER JOIN transactions t ON ti.transaction_id = t.id
        WHERE t.transaction_date = ?
      ''', [date]);

      int totalItems = itemsResult.first['total_items'] as int? ?? 0;

      // Get unique customers
      final customersResult = await db.rawQuery('''
        SELECT COUNT(DISTINCT customer_id) as unique_customers
        FROM transactions
        WHERE transaction_date = ? AND customer_id IS NOT NULL
      ''', [date]);

      int uniqueCustomers =
          customersResult.first['unique_customers'] as int? ?? 0;

      print('📊 Daily summary for $date: $totalTransactions transactions, Rp $totalSales');

      return {
        'total_sales': totalSales,
        'total_transactions': totalTransactions,
        'total_items': totalItems,
        'unique_customers': uniqueCustomers,
      };
    } catch (e) {
      print('❌ Error getting daily summary: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts(
      String startDate, String endDate, int limit) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT 
          ti.product_id,
          ti.product_name,
          SUM(ti.quantity) as total_quantity,
          SUM(ti.total) as total_sales
        FROM transaction_items ti
        INNER JOIN transactions t ON ti.transaction_id = t.id
        WHERE t.transaction_date BETWEEN ? AND ?
        GROUP BY ti.product_id, ti.product_name
        ORDER BY total_quantity DESC
        LIMIT ?
      ''', [startDate, endDate, limit]);
      
      print('📊 Top $limit selling products loaded');
      return result;
    } catch (e) {
      print('❌ Error getting top selling products: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts(
      int threshold) async {
    try {
      final db = await database;
      final result = await db.query(
        'products',
        where: 'stock <= ?',
        whereArgs: [threshold],
        orderBy: 'stock ASC',
      );
      print('📊 Found ${result.length} low stock products');
      return result;
    } catch (e) {
      print('❌ Error getting low stock products: $e');
      rethrow;
    }
  }

  // ========== BACKUP & SYNC ==========
  Future<Map<String, dynamic>> getAllDataForBackup() async {
    try {
      final db = await database;

      final products = await db.query('products');
      final customers = await db.query('customers');
      final transactions = await db.query('transactions');
      final transactionItems = await db.query('transaction_items');

      print('📦 Backup data prepared: ${products.length} products, ${transactions.length} transactions');

      return {
        'products': products,
        'customers': customers,
        'transactions': transactions,
        'transaction_items': transactionItems,
        'backup_date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error preparing backup: $e');
      rethrow;
    }
  }

  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('transaction_items');
      await db.delete('transactions');
      await db.delete('customers');
      await db.delete('products');
      print('✅ All data cleared');
    } catch (e) {
      print('❌ Error clearing data: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    print('✅ Database closed');
  }
}