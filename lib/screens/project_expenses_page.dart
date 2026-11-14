import 'package:flutter/material.dart';
import '../models/mobile_models.dart';
import '../services/api_client.dart';
import '../services/worksite_api.dart';
import '../widgets/siba_widgets.dart';
import 'module_common.dart' show sibaMoney;
import 'worksite_forms.dart';

class ProjectExpensesPage extends StatefulWidget {
  final SibaProject project;
  const ProjectExpensesPage({super.key, required this.project});
  @override
  State<ProjectExpensesPage> createState() => _ProjectExpensesPageState();
}

class _ProjectExpensesPageState extends State<ProjectExpensesPage> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  String? _error;
  String get _base => '/projects/${widget.project.id}/operations';
  bool get _canCapture => WorksiteApi.map(_data['project'])['accepted'] == true && _data['canCaptureCosts'] == true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await WorksiteApi.request(_base);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (!_canCapture || _loading) return;
    final requests = WorksiteApi.rows(_data['requisitions']).where((r) => !['cancelada','rechazada'].contains(r['estado']));
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => SibaFormPage(
      title: 'Registrar gasto de obra', attachments: true,
      initial: {'fecha': WorksiteApi.day(DateTime.now().toIso8601String()), 'categoria': 'material', 'formaPago': 'Transferencia', 'requisicionId': ''},
      fields: [
        const SibaField('fecha','Fecha',kind:'date',isRequired:true),
        const SibaField('categoria','Rubro',kind:'select',isRequired:true,choices:{'gasolina':'Gasolina','material':'Material','sueldos':'Sueldos','subcontratos':'Subcontratos','otros':'Otros gastos'}),
        const SibaField('concepto','Concepto',isRequired:true),
        const SibaField('monto','Importe neto MXN',kind:'money',isRequired:true),
        const SibaField('proveedor','Proveedor / persona'),
        const SibaField('formaPago','Forma de pago',kind:'select',isRequired:true,choices:{'Transferencia':'Transferencia','Efectivo':'Efectivo','Tarjeta':'Tarjeta','Pendiente de pago':'Pendiente de pago','Otro':'Otro'}),
        const SibaField('referencia','Referencia (opcional)'),
        SibaField('requisicionId','Requisición (opcional)',kind:'select',choices:{'':'Sin requisición',for(final r in requests)'${r['id']}':'#${r['id']} · ${WorksiteApi.day(r['fecha'])}'}),
      ],
      onSave: (data,files,key) async {
        if (WorksiteApi.number(data['monto']) <= 0) throw const ApiException('El importe debe ser mayor a cero.');
        await WorksiteApi.upload('$_base/gastos', {...data,'solicitudKey':key}, files);
      },
    )));
    if (!mounted || result != true) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Gasto de obra registrado.')));
    await _load();
  }
  Future<void> _openFile(Map<String,dynamic> file) async {
    try { await WorksiteApi.open(kind:'expense-file',recordId:WorksiteApi.number(file['id']).toInt(),projectId:widget.project.id); }
    catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e'))); }
  }
  @override
  Widget build(BuildContext context) {
    final summary = WorksiteApi.map(_data['summary']);
    final expenses = WorksiteApi.rows(_data['expenses']).where((r) => r['estado'] != 'cancelado').toList();
    return Scaffold(
      appBar:AppBar(title:const Text('Gastos de obra')),
      bottomNavigationBar:_loading || _error != null || !_canCapture ? null : SafeArea(minimum:const EdgeInsets.all(16),child:FilledButton.icon(onPressed:_create,icon:const Icon(Icons.add),label:const Text('Registrar gasto de obra'))),
      body:RefreshIndicator(onRefresh:_load,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.all(20),children:[
        Text(widget.project.title,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:16),
        if(_loading)const LinearProgressIndicator(),
        if(_error!=null)SibaEmptyState(icon:Icons.cloud_off_outlined,title:'No se pudieron cargar los gastos',message:_error!,action:TextButton(onPressed:_load,child:const Text('Reintentar'))),
        if(!_loading&&_error==null)...[
          SibaSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Límite de gasto'),const SizedBox(height:6),Text(WorksiteApi.number(summary['limit'])>0?sibaMoney(summary['limit']):'Por definir',style:Theme.of(context).textTheme.headlineSmall)])),
          if(!_canCapture)const Padding(padding:EdgeInsets.symmetric(vertical:16),child:Text('La captura se habilita al confirmar la OC del proyecto.')),
          const SizedBox(height:20),SibaSectionTitle(title:_data['supervisorOnly']==true?'Mis gastos registrados':'Gastos registrados'),const SizedBox(height:12),
          if(expenses.isEmpty)const SibaEmptyState(icon:Icons.receipt_long_outlined,title:'Sin gastos registrados',message:'Agrega el gasto y sus tickets o facturas.'),
          for(final e in expenses)Padding(padding:const EdgeInsets.only(bottom:12),child:SibaSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('${e['concepto']??''}',style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:6),Text(sibaMoney(e['monto']),style:Theme.of(context).textTheme.titleLarge),Text('${WorksiteApi.day(e['fecha'])} · ${e['proveedor']??''}'),
            for(final file in WorksiteApi.rows(e['adjuntos']))TextButton.icon(onPressed:()=>_openFile(file),icon:const Icon(Icons.attach_file),label:Text('${file['nombre']??'Archivo'}')),
          ]))),
        ],
      ])),
    );
  }
}
