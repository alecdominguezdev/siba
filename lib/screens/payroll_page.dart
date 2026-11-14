import 'package:flutter/material.dart';
import '../services/siba_access.dart';
import '../services/worksite_api.dart';
import '../services/payroll_bank_data.dart';
import '../theme/siba_theme.dart';
import '../widgets/siba_widgets.dart';
import 'module_common.dart';
import 'project_page.dart' show paymentMethods;
import 'worksite_forms.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key});
  @override State<PayrollPage> createState() => _PayrollPageState();
}
class _PayrollPageState extends State<PayrollPage> {
  Map<String, dynamic> _data = {}, _weekly = {};
  String _project = 'all';
  String? _error;
  bool _loading = true, _sending = false, _people = false;
  final _search = TextEditingController();
  late DateTime _start;
  String _day(DateTime date) => WorksiteApi.day(date.toIso8601String());
  @override void initState() { super.initState(); final now=DateTime.now();_start=DateTime(now.year,now.month,now.day).subtract(Duration(days:now.weekday-1));_load(); }
  @override void dispose() { _search.dispose();super.dispose(); }
  Future<void> _load() async {
    if(!SibaAccess.allowed('nomina')||!SibaAccess.canManage){setState((){_loading=false;_error='Tu perfil no tiene acceso a Nómina.';});return;}
    setState((){_loading=true;_error=null;});
    try{final values=await Future.wait([WorksiteApi.request('/payroll'),WorksiteApi.request('/payroll/weekly',query:{'proyectoId':_project,'inicio':_day(_start)})]);if(mounted)setState((){_data=values[0];_weekly=values[1];});}
    catch(e){if(mounted)setState(()=>_error='$e');}finally{if(mounted)setState(()=>_loading=false);}
  }
  String _projectName(dynamic id) {for(final p in WorksiteApi.rows(_data['projects'])){if('${p['id']}'=='$id')return '${p['titulo_proyecto']}';}return 'Sin proyecto';}
  String _employeeProjects(Map<String,dynamic> employee) {
    final assignments=WorksiteApi.rows(employee['asignaciones']).where((a)=>a['estado']=='activo').map((a)=>_projectName(a['proyecto_id'])).toSet();
    return assignments.isEmpty?_projectName(employee['proyecto_id']):assignments.join(', ');
  }
  List<Map<String,dynamic>> get _rows => WorksiteApi.rows(_weekly['rows']).where((r)=>'${r['nombre']} ${r['puesto']} ${r['obra']}'.toLowerCase().contains(_search.text.toLowerCase())).toList();
  Future<void> _form(SibaFormPage page) async {if(await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>page))==true)await _load();}
  Future<void> _person() async => _form(SibaFormPage(title:'Agregar empleado en Nómina',initial:{'inicio':_day(DateTime.now()),'empresa':'SIBA','sueldoSemanal':'0.00','tarifaExtra':'0.00'},fields:const [
    SibaField('nombre','Nombre completo',isRequired:true),SibaField('puesto','Puesto',isRequired:true),SibaField('sueldoSemanal','Sueldo base semanal neto',kind:'money',isRequired:true),SibaField('tarifaExtra','Importe por hora extra',kind:'money',isRequired:true),SibaField('inicio','Fecha de alta',kind:'date',isRequired:true),SibaField('empresa','Empresa'),
    SibaField('banco','Banco (opcional)'),SibaField('titular','Titular de la cuenta (opcional)'),SibaField('cuenta','Número de cuenta (opcional)'),SibaField('clabe','CLABE de 18 dígitos (opcional)'),
  ],onSave:(data,files,key)async{await WorksiteApi.request('/payroll/employees',method:'POST',data:{...data,...PayrollBankData.normalize(data,fallbackHolder:'${data['nombre']??''}'),'solicitudKey':key});}));
  Future<void> _adjust(Map<String,dynamic> row) async => _form(SibaFormPage(title:'Sueldo y ajustes',initial:row,fields:const [
    SibaField('semanal','Sueldo base semanal neto',kind:'money',isRequired:true),SibaField('tarifa','Importe por hora extra',kind:'money',isRequired:true),SibaField('bonos','Bonos',kind:'money',isRequired:true),SibaField('gastos','Gastos / reembolsos',kind:'money',isRequired:true),SibaField('descuentos','Otros descuentos',kind:'money',isRequired:true),SibaField('notas','Notas',kind:'notes'),
  ],onSave:(data,files,key)async{await WorksiteApi.request('/payroll/weekly/employees/${row['empleadoId']}',method:'PUT',data:{...data,'inicio':_day(_start),'revision':row['revision'],'salaryRevision':row['salaryRevision']});}));
  Future<void> _send() async {
    if(_sending)return;setState((){_sending=true;_error=null;});
    try{final ids=_rows.where((r)=>r['enviada']!=true&&r['elegible']!=false).map((r)=>r['empleadoId']).toList();if(ids.isEmpty)return;final result=await WorksiteApi.request('/payroll/weekly/send',method:'POST',data:{'proyectoId':_project,'inicio':_day(_start),'version':_weekly['version'],'empleadoIds':ids});if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${result['sent']} nóminas enviadas a pagos.')));await _load();}
    catch(e){if(mounted)setState(()=>_error='$e');}finally{if(mounted)setState(()=>_sending=false);}
  }
  Map<String,dynamic>? _period(Map<String,dynamic> row) {
    for(final p in WorksiteApi.rows(_data['periods'])){if('${p['empleado_id']}'=='${row['empleadoId']}'&&WorksiteApi.day(p['inicio'])==_day(_start)&&WorksiteApi.day(p['fin'])==_day(_start.add(const Duration(days:5))))return p;}return null;
  }
  Future<void> _pay(Map<String,dynamic> row,Map<String,dynamic> period) async {
    final employee=WorksiteApi.rows(_data['employees']).firstWhere((e)=>'${e['id']}'=='${row['empleadoId']}',orElse:()=>{}),bank=WorksiteApi.map(employee['datosBancarios']);
    await _form(SibaFormPage(title:'Registrar pago · ${row['nombre']}',attachments:true,initial:{'monto':period['pendiente'],'fecha':_day(DateTime.now()),'metodo':'Transferencia','banco':bank['banco']??''},fields:const [SibaField('monto','Importe neto a pagar',kind:'money',isRequired:true),SibaField('fecha','Fecha de pago',kind:'date',isRequired:true),SibaField('metodo','Forma de pago',kind:'select',choices:paymentMethods,isRequired:true),SibaField('banco','Banco'),SibaField('referencia','Referencia')],onSave:(data,files,key)async{await WorksiteApi.upload('/payroll/periods/${period['id']}/payments',{...data,'bankRevision':bank['revision']??0,'solicitudKey':key},files);}));
  }
  Map<String,dynamic> _employee(Map<String,dynamic> row) {
    final employeeId=row['empleadoId']??row['id'];
    return WorksiteApi.rows(_data['employees']).firstWhere((e)=>'${e['id']}'=='$employeeId',orElse:()=>row);
  }
  Future<void> _bank(Map<String,dynamic> row) async {
    final employee=_employee(row),bank=WorksiteApi.map(employee['datosBancarios']);
    final employeeId=employee['id']??row['empleadoId'];
    final holder='${bank['titular']??''}'.trim();
    await _form(SibaFormPage(title:'Datos bancarios · ${employee['nombre']??row['nombre']}',initial:{...bank,'titular':holder.isEmpty?employee['nombre']:holder},fields:const [
      SibaField('banco','Banco'),SibaField('titular','Titular de la cuenta'),SibaField('cuenta','Número de cuenta'),SibaField('clabe','CLABE de 18 dígitos'),
    ],onSave:(data,files,key)async{await WorksiteApi.request('/payroll/employees/$employeeId/bank',method:'PUT',data:{...PayrollBankData.normalize(data,fallbackHolder:'${employee['nombre']??''}'),'revision':bank['revision']??0});}));
  }
  Widget _bankDetails(Map<String,dynamic> row) {
    final employee=_employee(row),bank=WorksiteApi.map(employee['datosBancarios']);
    final saved=['banco','cuenta','clabe'].any((key)=>'${bank[key]??''}'.trim().isNotEmpty);
    return ExpansionTile(tilePadding:EdgeInsets.zero,childrenPadding:const EdgeInsets.only(bottom:8),title:const Text('Datos bancarios'),subtitle:Text(saved?'${bank['banco']??''}'.trim().isEmpty?'Registrados':'${bank['banco']}':'Sin registrar'),children:[
      if(saved)Align(alignment:Alignment.centerLeft,child:SelectableText('Banco: ${bank['banco']??'—'}\nTitular: ${bank['titular']??'—'}\nCuenta: ${bank['cuenta']??'—'}\nCLABE: ${bank['clabe']??'—'}')),
      Align(alignment:Alignment.centerLeft,child:TextButton.icon(onPressed:_loading||_sending?null:()=>_bank(employee),icon:Icon(saved?Icons.edit_outlined:Icons.add),label:Text(saved?'Editar datos bancarios':'Agregar datos bancarios'))),
    ]);
  }
  Future<void> _cancel(Map<String,dynamic> payment) async => _form(SibaFormPage(title:'Cancelar pago',fields:const [SibaField('motivo','Motivo',kind:'notes',isRequired:true)],onSave:(data,files,key)async{await WorksiteApi.request('/payroll/payments/${payment['id']}/cancel',method:'POST',data:data);}));
  Future<void> _files(Map<String,dynamic> payment) async => _form(SibaFormPage(title:'Comprobantes',attachments:true,fields:const [],onSave:(data,files,key)async{if(files.isEmpty)throw StateError('Selecciona un comprobante.');await WorksiteApi.upload('/payroll/payments/${payment['id']}/files',{},files);}));
  Future<void> _open(dynamic id) async {try{await WorksiteApi.open(kind:'payroll-file',recordId:int.parse('$id'));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}}
  @override Widget build(BuildContext context) {
    final rows=_rows,projects=WorksiteApi.rows(_data['projects']);
    final people=WorksiteApi.rows(_data['employees']).where((e)=>'${e['nombre']} ${e['puesto']}'.toLowerCase().contains(_search.text.toLowerCase())).where((e)=>_project=='all'||(_project=='0'?WorksiteApi.rows(e['asignaciones']).every((a)=>a['estado']!='activo')&&WorksiteApi.number(e['proyecto_id'])==0:WorksiteApi.rows(e['asignaciones']).any((a)=>'${a['proyecto_id']}'==_project&&a['estado']=='activo')||'${e['proyecto_id']}'==_project)).toList();
    return Scaffold(appBar:AppBar(title:const Text('Nómina')),body:RefreshIndicator(onRefresh:_load,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.all(18),children:[
      FilledButton.icon(onPressed:_loading||_sending?null:_person,icon:const Icon(Icons.person_add_alt),label:const Text('Agregar empleado')),const SizedBox(height:14),
      Wrap(spacing:8,children:[ChoiceChip(label:const Text('Semana'),selected:!_people,onSelected:(_)=>setState(()=>_people=false)),ChoiceChip(label:Text('Todos los empleados (${WorksiteApi.rows(_data['employees']).length})'),selected:_people,onSelected:(_)=>setState(()=>_people=true))]),const SizedBox(height:12),
      DropdownButtonFormField<String>(value:_project,isExpanded:true,decoration:const InputDecoration(labelText:'Filtrar por proyecto'),items:[const DropdownMenuItem(value:'all',child:Text('Todos los proyectos')),const DropdownMenuItem(value:'0',child:Text('Sin proyecto')),for(final p in projects)DropdownMenuItem(value:'${p['id']}',child:Text('${p['folio']} · ${p['titulo_proyecto']}',maxLines:1,overflow:TextOverflow.ellipsis))],onChanged:_sending||_loading?null:(value){setState(()=>_project=value??'all');_load();}),const SizedBox(height:12),
      if(!_people)OutlinedButton.icon(onPressed:_sending||_loading?null:()async{final value=await showDatePicker(context:context,initialDate:_start,firstDate:DateTime(2000),lastDate:DateTime(2100));if(value!=null&&mounted){setState(()=>_start=value.subtract(Duration(days:value.weekday-1)));await _load();}},icon:const Icon(Icons.calendar_today_outlined),label:Text('Semana ${_day(_start)}')),const SizedBox(height:12),
      TextField(controller:_search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(labelText:'Buscar empleado',prefixIcon:Icon(Icons.search))),const SizedBox(height:14),
      if(_loading)const LinearProgressIndicator(),if(_error!=null)Text(_error!,style:const TextStyle(color:SibaColors.danger)),
      if(!_people)...[
        Text('Neto semanal: ${sibaMoney(rows.fold<double>(0,(n,r)=>n+WorksiteApi.number(r['neto'])))}',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:12),
        FilledButton(onPressed:_loading||_sending||!rows.any((r)=>r['enviada']!=true&&r['elegible']!=false)?null:_send,child:Text(_sending?'Enviando…':'Enviar a pagos')),const SizedBox(height:16),
        if(!_loading&&rows.isEmpty)const SibaEmptyState(icon:Icons.groups_outlined,title:'Sin empleados',message:'Agrega personal en Nómina y asígnalo desde el proyecto.'),
        for(final row in rows)_worker(row),
      ]else for(final e in people)Padding(padding:const EdgeInsets.only(bottom:12),child:SibaSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${e['nombre']}',style:Theme.of(context).textTheme.titleMedium),Text('${e['puesto']}'),Text(_employeeProjects(e),style:const TextStyle(color:SibaColors.muted)),Text('Sueldo base semanal: ${sibaMoney(e['sueldoSemanal'])}'),_bankDetails(e)])))
    ])));
  }
  Widget _worker(Map<String,dynamic> row) {
    final period=_period(row),payments=WorksiteApi.rows(period?['pagos']);
    return Padding(padding:const EdgeInsets.only(bottom:14),child:SibaSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('${row['nombre']}',style:Theme.of(context).textTheme.titleMedium),Text('${row['obra']??'Sin proyecto'}',style:const TextStyle(color:SibaColors.muted)),const SizedBox(height:10),
      Text('Sueldo base: ${sibaMoney(row['semanal'])}'),Text('${row['asistencias']} días trabajados · ${row['faltas']} faltas'),Text('Descuento por faltas: ${sibaMoney(row['descuentoFaltas'])}'),Text('Sueldo por días: ${sibaMoney(row['base'])}'),Text('Neto a pagar: ${sibaMoney(row['neto'])}',style:const TextStyle(fontWeight:FontWeight.w700)),
      if(WorksiteApi.number(row['pendientes'])>0)Text('${row['pendientes']} días sin captura en la app',style:const TextStyle(color:SibaColors.muted)),
      Wrap(spacing:8,children:[if(row['enviada']!=true&&row['elegible']!=false)TextButton(onPressed:_loading||_sending?null:()=>_adjust(row),child:const Text('Sueldo y ajustes')),if(period!=null&&WorksiteApi.number(period['pendiente'])>0)FilledButton(onPressed:_loading||_sending?null:()=>_pay(row,period),child:const Text('Registrar pago'))]),
      _bankDetails(row),
      if(period!=null)ExpansionTile(tilePadding:EdgeInsets.zero,title:Text('Pagos · Pendiente ${sibaMoney(period['pendiente'])}'),children:[for(final p in payments)Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${sibaDate(p['fecha'])} · ${sibaMoney(p['monto'])} · ${p['estado']}'),Wrap(spacing:6,children:[for(final f in WorksiteApi.rows(p['archivos']))TextButton(onPressed:()=>_open(f['id']),child:Text('${f['nombre']}'))]),if(p['estado']=='registrado')Wrap(children:[TextButton(onPressed:()=>_files(p),child:const Text('Adjuntar comprobante')),TextButton(onPressed:()=>_cancel(p),child:const Text('Cancelar pago'))])]))]),
    ])));
  }
}
