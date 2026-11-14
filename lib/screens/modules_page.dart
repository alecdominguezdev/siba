import 'package:flutter/material.dart';

import '../models/mobile_models.dart';
import '../services/api_client.dart';
import '../theme/siba_theme.dart';
import '../widgets/siba_widgets.dart';
import 'budgets_page.dart';
import 'payroll_page.dart';
import '../services/siba_access.dart';
import 'inventory_page.dart';
import 'business_modules_pages.dart';
import 'company_locations_page.dart';
import 'attendance_page.dart';
import 'module_common.dart';
import 'projects_page.dart';
import 'reports_overview_page.dart';

class ModulesPage extends StatelessWidget {
  const ModulesPage({super.key});

  bool _allowed(String key) {
    final access = ApiClient.instance.currentAccess;
    for (final module in access?.modules ?? const <SibaModuleAccess>[]) {
      if (module.key == key) return module.allowed && module.mobileAvailable;
    }
    return false;
  }

  bool get _isAdmin => SibaAccess.canManage;

  @override
  Widget build(BuildContext context) {
    final modules = <_ModuleEntry>[
      if (_allowed('presupuesto')) const _ModuleEntry('Proyectos', 'Control de obra, gastos y archivos', Icons.business_center_outlined, ProjectsPage(embedded: true)),
      if (_allowed('presupuesto'))
        const _ModuleEntry(
          'Cotizaciones',
          'Cotizaciones, costos y aprobación',
          Icons.request_quote_outlined,
          BudgetsPage(),
        ),
      if (_allowed('nomina') && SibaAccess.canManage) const _ModuleEntry('Nómina', 'Personal y pagos por obra', Icons.payments_outlined, PayrollPage()),
      if (_allowed('inventario'))
        const _ModuleEntry(
          'Inventario',
          'Fotografías, herramientas y existencias',
          Icons.inventory_2_outlined,
          InventoryPage(),
        ),
      if (_allowed('compras'))
        const _ModuleEntry(
          'Compras',
          'Órdenes, proveedores y archivos',
          Icons.inventory_2_outlined,
          PurchasesPage(),
        ),
      if (_allowed('cuentas-pagar'))
        const _ModuleEntry(
          'Cuentas por pagar',
          'Facturas y pagos a proveedores',
          Icons.payments_outlined,
          FinanceAccountsPage(receivable: false),
        ),
      if (_allowed('cuentas-cobrar'))
        const _ModuleEntry(
          'Cuentas por cobrar',
          'Facturación, saldos y cobros',
          Icons.request_page_outlined,
          FinanceAccountsPage(receivable: true),
        ),
      if (_allowed('tareas'))
        const _ModuleEntry(
          'Tareas',
          'Pendientes y seguimiento',
          Icons.task_alt_outlined,
          TasksPage(),
        ),
      if (_isAdmin)
        const _ModuleEntry(
          'Empresas',
          'Ubicaciones y perímetros de asistencia',
          Icons.location_city_outlined,
          CompanyLocationsPage(),
        ),
      if (_allowed('asistencias'))
        const _ModuleEntry(
          'Asistencia',
          'Entrada y salida con ubicación',
          Icons.fingerprint_rounded,
          AttendancePage(),
        ),
      if (_allowed('reportes') || _allowed('informes'))
        const _ModuleEntry(
          'Informes',
          'Informes de supervisión',
          Icons.description_outlined,
          ReportsOverviewPage(),
        ),
      if (_allowed('exportaciones'))
        const _ModuleEntry(
          'Exportaciones',
          'Descargar información autorizada',
          Icons.file_download_outlined,
          ExportsPage(),
        ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
      children: [
        const ModuleHeader(
          eyebrow: 'SIBA',
          title: 'Módulos',
          subtitle: '',
          icon: Icons.grid_view_rounded,
        ),
        const SizedBox(height: 18),
        if (modules.isEmpty)
          const SibaEmptyState(
            icon: Icons.lock_outline,
            title: 'Sin módulos disponibles',
            message: 'Tu usuario no tiene módulos móviles habilitados.',
          )
        else
          ...modules.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SibaSurface(onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => item.page is InventoryPage || item.page is PayrollPage
                  ? item.page : Scaffold(appBar: AppBar(title: Text(item.title)), body: item.page),
            )), child: Row(children: [SibaIconTile(icon: item.icon), const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 4),
                Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
              ])), const Icon(Icons.chevron_right, color: SibaColors.muted),
            ])),
          )),
      ],
    );
  }
}

class _ModuleEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;
  const _ModuleEntry(this.title, this.subtitle, this.icon, this.page);
}
