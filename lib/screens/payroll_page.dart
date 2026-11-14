import 'package:flutter/material.dart';
import '../services/siba_access.dart';
import '../services/worksite_api.dart';
import '../theme/siba_theme.dart';
import '../widgets/siba_widgets.dart';
import 'module_common.dart';
import 'project_page.dart' show paymentMethods;
import 'worksite_forms.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key});
  @override State<PayrollPage> createState()=>_PayrollPageState();
}
class _PayrollPageState extends State<PayrollPage> {
  Map<String,dynamic> _data={};String? _project,_error;bool _loading=true,_showPaid=false;
  final _search=TextEditingController();late DateTime _start,_end;
  @override void initState(){super.initState();final now=DateTime.now();_start=DateTime(now.year,now.month,now.day).subtract(Duration(days:now.weekday-1));_end=_start.add(const Duration(days:6));_load();}
  @override void dispose(){_search.dispose();super.dispose();}
  String _day(DateTime value)=>WorksiteApi.day(value.toIso8601String());
  Future<void> _load()async{if(!SibaAccess.allowed('nomina')||!SibaAccess.canManage){setState((){_loading=false;_error='Tu perfil no tiene acceso a Nómina.';});return;}setState((){_loading=true;_error=null;});try{final value=await WorksiteApi.request('/payroll');if(mounted)setState(()=>_data=value);}catch(e){if(mounted)setState(()=>_error='$e');}finally{if(mounted)setState(()=>_loading=false);}}
  Future<void> _form(SibaFormPage page)async{if(await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>page))==true)await _load();}
  List<Map<String,dynamic>> get _periods=>WorksiteApi.rows(_data['periods']).where((p)=>'${p['proyecto_id']}'==_project&&WorksiteApi.day(p['inicio'])==_day(_start)&&WorksiteApi.day(p['fin'])==_day(_end)).toList();
  Map<String,dynamic>? _period(Map<String,dynamic> e){for(final p in _periods){if('${p['empleado_id']}'=='${e['id']}')return p;}return null;}
  Future<void> _date(bool start)async{final result=await showDatePicker(context:context,initialDate:start?_start:_end,firstDate:DateTime(2000),lastDate:DateTime(2100));if(result!=null)setState((){if(start){_start=result;if(_end.isBefore(_start))_end=_start;}else{_end=result;if(_start.isAfter(_end))_start=_end;}});}
  Future<void> _person()async{if(_project==null)return;await _form(SibaFormPage(title:'Agregar trabajador',initial:{'inicio':_day(DateTime.now())},fields:const [SibaField('nombre','Nombre completo',isRequired:true),SibaField('puesto','Puesto',isRequired:true),SibaField('empresa','Empresa'),SibaField('inicio','Fecha de alta',kind:'date',isRequired:true),SibaField('banco','Banco (opcional)'),SibaField('titular','Titular (opcional)'),SibaField('cuenta','Cuenta (opcional)'),SibaField('clabe','CLABE (opcional)')],onSave:(data,files,key)async{await WorksiteApi.request('/payroll/employees',method:'POST',data:{...data,'proyectoId':_project,'solicitudKey':key});}));}
  Future<void> _bank(Map<String,dynamic> employee)async{final bank=WorksiteApi.map(employee['datosBancarios']);await _form(SibaFormPage(title:'Datos bancarios',initial:{...bank,'titular':bank['titular']??employee['nombre']},fields:const [SibaField('banco','Banco'),SibaField('titular','Titular'),SibaField('cuenta','Cuenta'),SibaField('clabe','CLABE de 18 dígitos')],onSave:(data,files,key)async{await WorksiteApi.request('/payroll/employees/${employee['id']}/bank',method:'PUT',data:{...data,'revision':bank['revision']??0});}));}
  Future<void> _pay(Map<String,dynamic> employee,Map<String,dynamic>? period)async{
    final bank=WorksiteApi.map(employee['datosBancarios']);
    await _form(SibaFormPage(title:'Pagar a ${employee['nombre']}',attachments:true,initial:{'neto':period?['neto']??'','monto':period?['pendiente']??'','fecha':_day(DateTime.now()),'metodo':'Transferencia','banco':bank['banco']??''},note:'${sibaDate(_day(_start))} al ${sibaDate(_day(_end))}\nBanco: ${bank['banco']??'Sin registrar'}\nTitular: ${bank['titular']??''}\nCLABE: ${bank['clabe']??''}',fields:[if(period==null)const SibaField('neto','Nómina neta del periodo (MXN)',kind:'money',isRequired:true),const SibaField('monto','Importe a pagar (MXN)',kind:'money',isRequired:true),const SibaField('fecha','Fecha de pago',kind:'date',isRequired:true),const SibaField('metodo','Forma de pago',kind:'select',choices:paymentMethods,isRequired:true),const SibaField('banco','Banco de salida'),const SibaField('referencia','Referencia'),if(period==null)const SibaField('notas','Notas (opcional)',kind:'notes')],onSave:(data,files,key)async{
      await WorksiteApi.upload('/payroll/worksites/$_project/payments',{...data,'neto':period?['neto']??data['neto'],'empleadoId':employee['id'],'inicio':_day(_start),'fin':_day(_end),'bankRevision':bank['revision']??0,'solicitudKey':key},files);
    }));
  }
  Future<void> _edit(Map<String,dynamic> period)async=>_form(SibaFormPage(title:'Editar nómina del periodo',initial:period,fields:const [SibaField('neto','Nómina neta (MXN)',kind:'money',isRequired:true),SibaField('notas','Notas',kind:'notes')],onSave:(data,files,key)async{await WorksiteApi.request('/payroll/periods/${period['id']}',method:'PUT',data:{...data,'revision':period['revision']});}));
  Future<void> _cancel(Map<String,dynamic> payment)async=>_form(SibaFormPage(title:'Cancelar pago',fields:const [SibaField('motivo','Motivo',kind:'notes',isRequired:true)],onSave:(data,files,key)async{await WorksiteApi.request('/payroll/payments/${payment['id']}/cancel',method:'POST',data:data);}));
  Future<void> _files(Map<String,dynamic> payment)async=>_form(SibaFormPage(title:'Adjuntar comprobantes',attachments:true,fields:const [],onSave:(data,files,key)async{if(files.isEmpty)throw StateError('Selecciona un comprobante.');await WorksiteApi.upload('/payroll/payments/${payment['id']}/files',{},files);}));
  Future<void> _open(dynamic id)async{try{await WorksiteApi.open(kind:'payroll-file',recordId:int.parse('$id'));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}}
  @override Widget build(BuildContext context){
    final projects=WorksiteApi.rows(_data['projects']);
    final workers=WorksiteApi.rows(_data['employees']).where((e)=>'${e['proyecto_id']}'==_project).where((e){final p=_period(e);return (WorksiteApi.number(e['activo'])==1||p!=null)&&(_showPaid||p==null||WorksiteApi.number(p['pendiente'])>0)&&'${e['nombre']} ${e['puesto']}'.toLowerCase().contains(_search.text.toLowerCase());}).toList();
    final periods=_periods;final paid=periods.fold<double>(0,(n,p)=>n+WorksiteApi.number(p['pagado'])),pending=periods.fold<double>(0,(n,p)=>n+WorksiteApi.number(p['pendiente']));
    return Scaffold(appBar:AppBar(title:const Text('Nómina')),body:RefreshIndicator(onRefresh:_load,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.all(18),children:[
      Text('Pagos por obra',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:18),if(_loading)const LinearProgressIndicator(),if(_error!=null)...[Text(_error!,style:const TextStyle(color:SibaColors.danger)),TextButton(onPressed:_load,child:const Text('Reintentar'))],
      DropdownButtonFormField<String>(value:projects.any((p)=>'${p['id']}'==_project)?_project:null,isExpanded:true,decoration:const InputDecoration(labelText:'Selecciona una obra'),items:projects.map((p)=>DropdownMenuItem(value:'${p['id']}',child:Text('${p['folio']} · ${p['titulo_proyecto']}',maxLines:1,overflow:TextOverflow.ellipsis))).toList(),onChanged:(v)=>setState(()=>_project=v)),const SizedBox(height:12),
      if(_project==null)const Padding(padding:EdgeInsets.symmetric(vertical:42),child:Column(children:[Icon(Icons.business_center_outlined,size:48,color:SibaColors.muted),SizedBox(height:12),Text('Selecciona una obra para consultar su personal y registrar pagos.',textAlign:TextAlign.center)]))
      else ...[
        Row(children:[Expanded(child:OutlinedButton.icon(onPressed:()=>_date(true),icon:const Icon(Icons.calendar_today_outlined,size:16),label:Text(sibaDate(_day(_start))))),const SizedBox(width:10),Expanded(child:OutlinedButton.icon(onPressed:()=>_date(false),icon:const Icon(Icons.calendar_today_outlined,size:16),label:Text(sibaDate(_day(_end)))))]),const SizedBox(height:14),SibaSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Pagado'),Text(sibaMoney(paid),style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:12),Text('Pendiente: ${sibaMoney(pending)}')])),const SizedBox(height:16),
        TextField(controller:_search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(labelText:'Buscar trabajador o puesto',prefixIcon:Icon(Icons.search))),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Mostrar también pagados'),value:_showPaid,onChanged:(v)=>setState(()=>_showPaid=v)),OutlinedButton.icon(onPressed:_person,icon:const Icon(Icons.person_add_alt),label:const Text('Agregar trabajador')),const SizedBox(height:16),
        if(workers.isEmpty)const Padding(padding:EdgeInsets.all(22),child:Text('Sin trabajadores pendientes para este periodo.',textAlign:TextAlign.center)),
        for(final employee in workers)_worker(employee,_period(employee))
      ]
    ])));
  }
  Widget _worker(Map<String,dynamic> employee,Map<String,dynamic>? period){final bank=WorksiteApi.map(employee['datosBancarios']);return Padding(padding:const EdgeInsets.only(bottom:14),child:SibaSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('${employee['nombre']}',style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:4),Text('${employee['puesto']}',style:const TextStyle(color:SibaColors.muted)),if(period!=null)...[const SizedBox(height:12),Text('Neto: ${sibaMoney(period['neto'])}'),Text('Pagado: ${sibaMoney(period['pagado'])}'),Text('Pendiente: ${sibaMoney(period['pendiente'])}',style:const TextStyle(fontWeight:FontWeight.w700))],const SizedBox(height:10),
    ExpansionTile(tilePadding:EdgeInsets.zero,title:const Text('Datos bancarios'),children:[SelectableText('Banco: ${bank['banco']??''}\nTitular: ${bank['titular']??''}\nCuenta: ${bank['cuenta']??''}\nCLABE: ${bank['clabe']??''}'),TextButton(onPressed:()=>_bank(employee),child:const Text('Editar datos bancarios'))]),
    if(period==null||WorksiteApi.number(period['pendiente'])>0)SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>_pay(employee,period),icon:const Icon(Icons.payments_outlined),label:const Text('Registrar pago'))),if(period!=null)...[
      TextButton(onPressed:()=>_edit(period),child:const Text('Editar importe del periodo')),
      ExpansionTile(tilePadding:EdgeInsets.zero,title:const Text('Pagos del periodo'),children:[for(final p in WorksiteApi.rows(period['pagos']))Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${sibaDate(p['fecha'])} · ${sibaMoney(p['monto'])}',style:const TextStyle(fontWeight:FontWeight.w700)),Text('${p['metodo']} · ${p['estado']}'),if(p['beneficiario'] is Map)Text('Beneficiario: ${WorksiteApi.map(p['beneficiario'])['titular']??''}'),Wrap(spacing:6,children:[for(final f in WorksiteApi.rows(p['archivos']))TextButton.icon(onPressed:()=>_open(f['id']),icon:const Icon(Icons.receipt_long_outlined,size:16),label:Text('${f['nombre']}'))]),if(p['estado']=='registrado')Wrap(children:[TextButton(onPressed:()=>_files(p),child:const Text('Adjuntar comprobante')),TextButton(onPressed:()=>_cancel(p),child:const Text('Cancelar pago',style:TextStyle(color:SibaColors.danger)))])]))])
    ]
  ])));}
}
