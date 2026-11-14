import 'api_client.dart';

class PayrollBankData {
  static Map<String, dynamic> normalize(Map<String, dynamic> values, {String fallbackHolder = ''}) {
    final bank = '${values['banco'] ?? ''}'.trim();
    final holder = '${values['titular'] ?? ''}'.trim();
    final account = '${values['cuenta'] ?? ''}'.trim();
    final clabe = '${values['clabe'] ?? ''}'.replaceAll(RegExp(r'\s'), '');
    if (bank.length > 100) throw const ApiException('El banco admite hasta 100 caracteres.');
    if (holder.length > 255) throw const ApiException('El titular admite hasta 255 caracteres.');
    if (account.length > 40) throw const ApiException('El número de cuenta admite hasta 40 caracteres.');
    if (clabe.isNotEmpty && !RegExp(r'^\d{18}$').hasMatch(clabe)) {
      throw const ApiException('La CLABE debe contener 18 dígitos.');
    }
    return {
      'banco': bank,
      'titular': holder.isEmpty ? fallbackHolder.trim() : holder,
      'cuenta': account,
      'clabe': clabe,
    };
  }
}
