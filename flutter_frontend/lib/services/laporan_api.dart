import 'api_client.dart';

class LaporanApi {
  static Future<dynamic> getLaporanHarian() async {
    return await ApiClient.get('/laporan/harian');
  }

  static Future<dynamic> getLaporanBulanan() async {
    return await ApiClient.get('/laporan/bulanan');
  }
}
