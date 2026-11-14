import 'api_client.dart';

class SibaAccess {
  static bool allowed(String key) => ApiClient.instance.currentAccess?.modules
      .any((m) => m.key == key && m.allowed && m.mobileAvailable) == true;
  static bool get attendanceOnly {
    final access = ApiClient.instance.currentAccess;
    if (access?.attendanceOnly == true) return true;
    final modules = access?.modules.where((m) => m.allowed && m.mobileAvailable).toList() ?? [];
    return modules.isNotEmpty && modules.every((m) => m.key == 'asistencias');
  }
  static String normalize(String value) => value.toLowerCase().replaceAll('ó', 'o').replaceAll('í', 'i').replaceAll('é', 'e').replaceAll('á', 'a').replaceAll('ú', 'u').trim();
  static bool get canManage {
    if (attendanceOnly) return false;
    final access = ApiClient.instance.currentAccess;
    final roles = [ApiClient.instance.currentUser?.role ?? '',access?.companyRole ?? '',...(access?.companyRoles ?? <String>[])].map(normalize);
    return roles.any((r) => ['direccion','gerente de obra','gerencia de proyectos','superadmin','superadmin de empresa','administracion','administrador'].contains(r));
  }
  static String get roleLabel => ApiClient.instance.currentAccess?.companyRole.isNotEmpty == true
      ? ApiClient.instance.currentAccess!.companyRole : ApiClient.instance.currentUser?.role ?? '';
}
