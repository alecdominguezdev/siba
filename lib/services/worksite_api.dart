import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class SibaUpload {
  final String path;
  final String name;
  final int size;
  const SibaUpload(this.path, this.name, this.size);
}
class WorksiteApi {
  static String requestKey() => List.generate(24, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  static Map<String, dynamic> map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : {};
  static List<Map<String, dynamic>> rows(dynamic value) => value is List ? value.whereType<Map>().map((v) => Map<String, dynamic>.from(v)).toList() : [];
  static double number(dynamic value) => double.tryParse('$value') ?? 0;
  static String day(dynamic value) => '$value'.length >= 10 ? '$value'.substring(0, 10) : '';
  static String amount(String value) {
    final clean = value.trim().replaceFirst(RegExp(r'^(MX\$|\$)\s*'), '').replaceAll(',', '');
    if (!RegExp(r'^\d{1,12}(\.\d{1,2})?$').hasMatch(clean)) throw const ApiException('Revisa el importe en pesos.');
    return clean;
  }
  static Map<String, String> get headers => {'Accept':'application/json','Authorization':'Bearer ${ApiClient.instance.bearerToken}'};
  static Map<String, dynamic> decode(http.Response response) {
    Map<String, dynamic> data = {};
    try { data = map(jsonDecode(utf8.decode(response.bodyBytes))); } catch (_) {}
    if (response.statusCode < 200 || response.statusCode >= 300 || data['ok'] == false) {
      throw ApiException('${data['message'] ?? 'No se pudo completar la operación.'}', statusCode: response.statusCode);
    }
    return data;
  }
  static Future<Map<String, dynamic>> request(String path, {String method = 'GET',Map<String, dynamic>? data,Map<String, dynamic>? query}) async {
    final request = http.Request(method, ApiConfig.uri(path, query));
    request.headers.addAll({...headers,'Content-Type':'application/json'});
    if (data != null) request.body = jsonEncode(data);
    final response = await request.send().timeout(const Duration(seconds: 40));
    return decode(await http.Response.fromStream(response).timeout(const Duration(seconds: 60)));
  }
  static Future<Map<String, dynamic>> upload(String path, Map<String, dynamic> fields,List<SibaUpload> files,{String fileField = 'archivos',bool document = false}) async {
    if (files.isEmpty) return request(path,method:'POST',data:fields);
    if (!document && (files.length > 8 || files.any((f) => f.size > 10*1024*1024) || files.fold<int>(0, (n,f) => n+f.size) > 32*1024*1024)) throw const ApiException('Máximo 8 comprobantes, 10 MB cada uno y 32 MB en total.');
    if (document && (files.length != 1 || files.first.size > 100*1024*1024)) throw const ApiException('Selecciona un archivo de hasta 100 MB.');
    final request = http.MultipartRequest('POST',ApiConfig.uri(path));request.headers.addAll(headers);
    fields.forEach((key,value) => request.fields[key] = value is List || value is Map ? jsonEncode(value) : '$value');
    for (final file in files) {
      if (!await File(file.path).exists()) throw const ApiException('El archivo ya no está disponible. Selecciónalo otra vez.');
      request.files.add(await http.MultipartFile.fromPath(fileField,file.path,filename:file.name));
    }
    final response = await request.send().timeout(const Duration(minutes: 3));
    return decode(await http.Response.fromStream(response).timeout(const Duration(minutes: 2)));
  }
  static Future<void> open({required String kind,required int recordId,int? projectId}) async {
    final data = await request('/worksite/files/open',method:'POST',data:{'kind':kind,'recordId':recordId,if(projectId != null)'projectId':projectId});
    final url = Uri.tryParse('${data['url'] ?? ''}');
    if (url == null || url.scheme != 'https' || url.host != ApiConfig.uri('/').host) throw const ApiException('No se pudo preparar la descarga.');
    if (!await launchUrl(url,mode:LaunchMode.externalApplication)) throw const ApiException('No hay una aplicación disponible para abrir el archivo.');
  }
}
