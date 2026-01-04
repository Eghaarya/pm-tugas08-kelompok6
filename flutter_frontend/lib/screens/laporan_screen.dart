import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../services/auth_api.dart';
import '../helpers/token_helper.dart';
import '../services/backup_api.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({Key? key}) : super(key: key);

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  bool isAuthenticated = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool isLoadingData = false;

  // Statistics data
  Map<String, dynamic> todaySummary = {
    'total_sales': 0,
    'total_transactions': 0,
    'total_items': 0,
    'unique_customers': 0,
  };

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await TokenHelper.getToken();
    if (token != null) {
      setState(() {
        isAuthenticated = true;
      });
      _loadReportData();
    }
  }

  Future<void> _login() async {
    final token = await AuthApi.login(
      _emailController.text,
      _passwordController.text,
    );

    if (token != null) {
      await TokenHelper.saveToken(token);

      setState(() {
        isAuthenticated = true;
      });

      _loadReportData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login berhasil'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadReportData() async {
    setState(() => isLoadingData = true);
    try {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final summary = await DatabaseHelper.instance.getDailySummary(todayStr);

      if (mounted) {
        setState(() {
          todaySummary = summary;
          isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDateRangePicker(String reportType) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      _generateReport(reportType, picked.start, picked.end);
    }
  }

  Future<void> _generateReport(
    String type,
    DateTime start,
    DateTime end,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final startStr =
          '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final endStr =
          '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

      final transactions = await DatabaseHelper.instance.getTransactionsByDate(
        startStr,
        endStr,
      );

      int totalSales = 0;
      for (var trans in transactions) {
        totalSales += trans['total'] as int;
      }

      if (mounted) {
        Navigator.pop(context); // Close loading

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Laporan $type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Periode: $startStr s/d $endStr'),
                const Divider(),
                Text('Total Transaksi: ${transactions.length}'),
                Text('Total Penjualan: Rp $totalSales'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur export akan segera hadir'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1FA397),
                ),
                child: const Text(
                  'Export PDF',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _backupToServer() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Membackup data ke server...'),
          ],
        ),
      ),
    );

    try {
      final allData = await DatabaseHelper.instance.getAllDataForBackup();

      // Process transactions to include items
      final rawTransactions = List<Map<String, dynamic>>.from(
        allData['transactions'],
      );
      List<Map<String, dynamic>> processedTransactions = [];

      for (var trx in rawTransactions) {
        int trxId = trx['id'];
        List<Map<String, dynamic>> items = await DatabaseHelper.instance
            .getTransactionItems(trxId);

        Map<String, dynamic> processedTrx = {
          'date': trx['transaction_date'],
          'total': trx['total'],
          'items': items,
        };

        processedTransactions.add(processedTrx);
      }

      //server upload
      final success = await BackupApi.backup(processedTransactions);

      if (!success) {
        throw Exception('Backup gagal');
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Backup Berhasil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Produk: ${allData['products'].length}'),
                Text('Pelanggan: ${allData['customers'].length}'),
                Text('Transaksi: ${allData['transactions'].length}'),
                const Divider(),
                Text('Tanggal: ${allData['backup_date']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Laporan', style: TextStyle(color: Colors.white)),
        actions: isAuthenticated
            ? [
                IconButton(
                  icon: const Icon(Icons.cloud_upload, color: Colors.white),
                  onPressed: _backupToServer,
                  tooltip: 'Backup ke Server',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadReportData,
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    final token = await TokenHelper.getToken();
                    if (token != null) {
                      await AuthApi.logout(token);
                    }

                    await TokenHelper.clearToken();

                    setState(() {
                      isAuthenticated = false;
                      _emailController.clear();
                      _passwordController.clear();
                    });
                  },
                ),
              ]
            : null,
      ),
      body: isAuthenticated ? _buildLaporanContent() : _buildLoginForm(),
    );
  }

  Widget _buildLoginForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1FA397),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Login Diperlukan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan login untuk mengakses laporan',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1FA397),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaporanContent() {
    return isLoadingData
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadReportData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Hari Ini',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Penjualan',
                          'Rp ${todaySummary['total_sales']}',
                          Icons.attach_money,
                          const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Transaksi',
                          '${todaySummary['total_transactions']}',
                          Icons.receipt,
                          const Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Produk Terjual',
                          '${todaySummary['total_items']}',
                          Icons.inventory,
                          const Color(0xFFFF9800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Pelanggan',
                          '${todaySummary['unique_customers']}',
                          Icons.people,
                          const Color(0xFF9C27B0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const SizedBox(height: 24),
                  const Text(
                    'Laporan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  _buildReportCard(
                    'Backup Data',
                    'Backup semua data transaksi ke server',
                    Icons.cloud_upload,
                    _backupToServer,
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1FA397)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
