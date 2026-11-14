import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import '../models/mobile_models.dart';
import '../services/worksite_api.dart';
import '../theme/siba_theme.dart';
import '../widgets/siba_widgets.dart';
import 'module_common.dart';
import 'worksite_forms.dart';
import 'project_reports_page.dart';

const worksiteCategories={'gasolina':'Gasolina','material':'Material','sueldos':'Sueldos','subcontratos':'Subcontratos','otros':'Otros gastos'};
const paymentMethods={'Transferencia':'Transferencia','Efectivo':'Efectivo','Cheque':'Cheque','Otro':'Otro'};
class ProjectPage extends StatefulWidget {
  final SibaProject project;
  const ProjectPage({super.key,required this.project});
  @override State<ProjectPage> createState()=>_ProjectPageState();
}
class _ProjectPageState extends State<ProjectPage> {
  Map<String,dynamic> _data={};List<Map<String,dynamic>> _documents=[];
  bool _loading=true;String? _error;String _tab='Gastos',_category='';
  String get _base=>'/projects/${widget.project.id}/operations';
  bool get _capture=>_data['canCaptureCosts']==true;
  bool get _manage=>_data['canManage']==true;
  bool get _hse=>_data['canManageHse']==true;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async {
    if(mounted)setState((){_loading=true;_error=null;});
    try{final results=await Future.wait([WorksiteApi.request(_base),WorksiteApi.request('/projects/${widget.project.id}/documents')]);if(mounted)setState((){_data=results[0];_documents=WorksiteApi.rows(results[1]['files']);});}
    catch(e){if(mounted)setState(()=>_error='$e');}finally{if(mounted)setState(()=>_loading=false);}
  }
  Future<void> _run(Future<void> Function() action)async{try{await action();await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}}
  Future<void> _form(SibaFormPage page)async{if(await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>page))==true)await _load();}
  Future<void> _meta()async{
    final meta=WorksiteApi.map(_data['meta']),schedule=WorksiteApi.map(meta['schedule']);
    await _form(SibaFormPage(title:'Meta general y plazo',fields:const [SibaField('meta','Meta general de gasto (MXN)',kind:'money',isRequired:true),SibaField('inicio','Fecha de inicio',kind:'date'),SibaField('limite','Fecha límite',kind:'date')],initial:{'meta':sibaMoney(meta['meta']),'inicio':WorksiteApi.day(schedule['start']),'limite':WorksiteApi.day(schedule['end'])},onSave:(data,files,key)async{await WorksiteApi.request('$_base/meta',method:'PUT',data:{...data,'revision':meta['revision']??0});}));
  }
  Future<void> _expense([Map<String,dynamic>? row])async{
    final requests=WorksiteApi.rows(_data['requisitions']).where((r)=>!['cancelada','rechazada'].contains(r['estado']));
    final initial=<String,dynamic>{'fecha':WorksiteApi.day(DateTime.now().toIso8601String()),'categoria':'material','formaPago':'Transferencia',if(row!=null)...row,'requisicionId':row?['requisicionId']?.toString()??''};
    if(row!=null)initial['fecha']=WorksiteApi.day(row['fecha']);
    await _form(SibaFormPage(title:row==null?'Registrar gasto':'Editar gasto',attachments:row==null,initial:initial,fields:[
      const SibaField('fecha','Fecha',kind:'date',isRequired:true),const SibaField('categoria','Rubro',kind:'select',choices:worksiteCategories,isRequired:true),const SibaField('concepto','Concepto / material',isRequired:true),const SibaField('monto','Importe neto (MXN)',kind:'money',isRequired:true),const SibaField('proveedor','Proveedor / persona'),const SibaField('formaPago','Forma de pago',kind:'select',choices:paymentMethods,isRequired:true),const SibaField('referencia','Referencia'),if(row==null)SibaField('requisicionId','Requisición (opcional)',kind:'select',choices:{'':'Sin requisición',for(final r in requests)'${r['id']}':'REQ-${r['id']}'})
    ],onSave:(data,files,key)async{
      if(row==null){await WorksiteApi.upload('$_base/gastos',{...data,'solicitudKey':key},files);}
      else{await WorksiteApi.request('$_base/gastos/${row['id']}',method:'PUT',data:{...data,'version':row['version']});}
    }));
  }
  Future<void> _link(Map<String,dynamic> row)async {
    final requests=WorksiteApi.rows(_data['requisitions']).where((r)=>!['cancelada','rechazada'].contains(r['estado']));
    await _form(SibaFormPage(title:'Vincular requisición',initial:{'requisicionId':row['requisicionId']?.toString()??''},fields:[SibaField('requisicionId','Requisición',kind:'select',choices:{'':'Sin requisición',for(final r in requests)'${r['id']}':'REQ-${r['id']}'})],onSave:(data,files,key)async{await WorksiteApi.request('$_base/requisition-link',method:'PUT',data:{'origenKey':row['editable']==true?'gasto-${row['id']}':row['id'],'requisicionId':data['requisicionId']});}));
  }
  Future<void> _request()async{
    final result=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>RequisitionFormPage(path:'$_base/requisiciones')));if(result==true)await _load();
  }
  Future<void> _attach(String type,dynamic record)async=>_run(()async{final files=await chooseSibaFiles();if(files.isNotEmpty)await WorksiteApi.upload('$_base/$type/$record/adjuntos',{},files);});
  Future<void> _open(String kind,dynamic id)async{try{await WorksiteApi.open(kind:kind,recordId:int.parse('$id'),projectId:widget.project.id);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}}
  Future<void> _transition(String type,Map<String,dynamic> row,String state)async=>_form(SibaFormPage(title:state=='baja'?'Dar de baja':'Cambiar estado',fields:const [SibaField('motivo','Motivo',kind:'notes',isRequired:true)],onSave:(data,files,key)async{await WorksiteApi.request('$_base/$type/${row['id']}',method:'PATCH',data:{...data,'estado':state,'revision':row['revision']});}));
  Future<void> _person()async=>_form(SibaFormPage(title:'Agregar personal a la obra',initial:{'inicio':WorksiteApi.day(DateTime.now().toIso8601String())},fields:const [SibaField('nombre','Nombre completo',isRequired:true),SibaField('puesto','Puesto',isRequired:true),SibaField('empresa','Empresa'),SibaField('inicio','Fecha de alta',kind:'date',isRequired:true),SibaField('fin','Fecha de baja (opcional)',kind:'date')],onSave:(data,files,key)async{await WorksiteApi.request('$_base/personal',method:'POST',data:{...data,'solicitudKey':key});}));
  Future<void> _document({bool hse=false})async=>_form(SibaFormPage(title:hse?'Subir permiso de trabajo':'Subir archivo del proyecto',attachments:true,document:true,initial:{'tipo':hse?'Permiso HSE':'Plano'},fields:[SibaField('tipo','Tipo de documento',kind:'select',isRequired:true,choices:hse?const {'Permiso HSE':'Permiso HSE'}:const {'Plano':'Plano','Documento técnico':'Documento técnico','Otro':'Otro'})],onSave:(data,files,key)async{if(files.isEmpty)throw StateError('Selecciona un archivo.');await WorksiteApi.upload('/projects/${widget.project.id}/documents',data,files,fileField:'archivo',document:true);}));
  Widget _empty(String message)=>Padding(padding:const EdgeInsets.all(26),child:Center(child:Text(message,style:const TextStyle(color:SibaColors.muted))));
  Widget _card(List<Widget> children)=>Padding(padding:const EdgeInsets.only(bottom:12),child:SibaSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:children)));
  Widget _files(List<Map<String,dynamic>> files,String kind)=>Wrap(spacing:6,runSpacing:6,children:files.map((f)=>OutlinedButton.icon(onPressed:()=>_open(kind,f['id']),icon:const Icon(Icons.attach_file,size:16),label:Text('${f['nombre']}',maxLines:1,overflow:TextOverflow.ellipsis))).toList());
  List<Widget> _expenses(){
    final rows=WorksiteApi.rows(_data['expenses']).where((e)=>e['estado']!='cancelado'&&(_category.isEmpty||e['categoria']==_category)).toList();
    return [DropdownButtonFormField<String>(value:_category,isExpanded:true,decoration:const InputDecoration(labelText:'Rubro'),items:[const DropdownMenuItem(value:'',child:Text('Todos los rubros')),for(final c in worksiteCategories.entries)DropdownMenuItem(value:c.key,child:Text(c.value))],onChanged:(v)=>setState(()=>_category=v??'')),const SizedBox(height:12),if(_capture)FilledButton.icon(onPressed:()=>_expense(),icon:const Icon(Icons.add),label:const Text('Registrar gasto')),const SizedBox(height:14),if(rows.isEmpty)_empty('Sin gastos registrados'),for(final row in rows)_card([
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Text('${row['concepto']??''}',style:Theme.of(context).textTheme.titleMedium)),const SizedBox(width:12),Text(sibaMoney(row['monto']),style:const TextStyle(fontWeight:FontWeight.w700,fontFeatures:[FontFeature.tabularFigures()]))]),
      const SizedBox(height:7),Text('${worksiteCategories[row['categoria']]??row['categoria']} · ${sibaDate(row['fecha'])}',style:const TextStyle(color:SibaColors.muted)),const SizedBox(height:6),Text('${row['proveedor']??''} · ${row['formaPago']??''}'),Text('${row['origen']??''}${row['requisicionId']==null?'':' · REQ-${row['requisicionId']}'}',style:const TextStyle(color:SibaColors.muted)),
      if(row['comprobante']!=null)TextButton.icon(onPressed:()=>_open('legacy-receipt',row['id']),icon:const Icon(Icons.receipt_long_outlined),label:const Text('Ver comprobante')),
      _files(WorksiteApi.rows(row['adjuntos']),'expense-file'),Wrap(spacing:8,children:[if(row['canEdit']==true)TextButton(onPressed:()=>_expense(row),child:const Text('Editar')),if(_capture&&(row['canEdit']==true||(_manage&&'${row['id']}'.startsWith('ocp-'))))TextButton(onPressed:()=>_link(row),child:const Text('Vincular requisición')),if(row['canAttach']==true)TextButton(onPressed:()=>_attach('gastos',row['id']),child:const Text('Adjuntar comprobante')),if(_manage&&row['editable']==true)TextButton(onPressed:()=>_transition('gastos',row,'cancelado'),child:const Text('Cancelar',style:TextStyle(color:SibaColors.danger)))])
    ])];
  }
  List<Widget> _requests(){
    final rows=WorksiteApi.rows(_data['requisitions']).where((r)=>!['cancelada','rechazada'].contains(r['estado'])).toList();
    return [if(_capture)FilledButton.icon(onPressed:_request,icon:const Icon(Icons.add),label:const Text('Nueva requisición')),const SizedBox(height:14),if(rows.isEmpty)_empty('Sin requisiciones'),for(final row in rows)_card([
      Row(children:[Expanded(child:Text('REQ-${row['id']}',style:Theme.of(context).textTheme.titleMedium)),SibaBadge(label:'${row['estado']}')]),const SizedBox(height:8),Text(sibaDate(row['fecha']),style:const TextStyle(color:SibaColors.muted)),
      for(final item in WorksiteApi.rows(row['partidas']))Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Text('${item['cantidad']} ${item['unidad']} · ${item['descripcion']}')),
      if('${row['notas']??''}'.isNotEmpty)Text('${row['notas']}'),
      Wrap(spacing:8,children:[OutlinedButton(onPressed:()=>_open('requisition-pdf',row['id']),child:const Text('PDF')),OutlinedButton(onPressed:()=>_open('requisition-xlsx',row['id']),child:const Text('Excel')),if(row['canAttach']==true)TextButton(onPressed:()=>_attach('requisiciones',row['id']),child:const Text('Adjuntar archivo'))]),_files(WorksiteApi.rows(row['adjuntos']),'expense-file'),
      if(_manage)Wrap(spacing:8,children:[if(row['estado']=='pendiente')TextButton(onPressed:()=>_transition('requisiciones',row,'aprobada'),child:const Text('Aprobar')),if(['pendiente','aprobada'].contains(row['estado']))TextButton(onPressed:()=>_transition('requisiciones',row,'cancelada'),child:const Text('Cancelar'))])
    ])];
  }
  List<Widget> _personnel(){final rows=WorksiteApi.rows(_data['personnel']).where((r)=>r['estado']=='activo').toList();return [if(_hse)FilledButton.icon(onPressed:_person,icon:const Icon(Icons.person_add_alt),label:const Text('Agregar personal')),const SizedBox(height:12),Text('${rows.length} personas activas',style:const TextStyle(color:SibaColors.muted)),const SizedBox(height:12),if(rows.isEmpty)_empty('Sin personal asignado'),for(final row in rows)_card([Text('${row['nombre']}',style:Theme.of(context).textTheme.titleMedium),Text('${row['puesto']} · ${row['empresa']??''}'),Text('Alta: ${sibaDate(row['fecha_inicio'])}',style:const TextStyle(color:SibaColors.muted)),if(_hse)TextButton(onPressed:()=>_transition('personal',row,'baja'),child:const Text('Dar de baja'))])];}
  List<Widget> _documentGroups(){return [
    Row(children:[Expanded(child:Text('Archivos del proyecto',style:Theme.of(context).textTheme.titleMedium)),IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),FilledButton.icon(onPressed:()=>_document(),icon:const Icon(Icons.upload_file),label:const Text('Subir archivo')),const SizedBox(height:14),
    for(final type in ['Plano','Documento técnico','Otro'])_card([Text(type=='Plano'?'Planos':type=='Otro'?'Otros archivos':'Documentos técnicos',style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:10),if(!_documents.any((f)=>f['tipo']==type))_empty('Sin archivos'),_files(_documents.where((f)=>f['tipo']==type).toList(),'project-document')]),
    const SizedBox(height:8),Text('Permisos de trabajo · HSE',style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:10),if(_hse)OutlinedButton.icon(onPressed:()=>_document(hse:true),icon:const Icon(Icons.upload_file),label:const Text('Subir permiso')),const SizedBox(height:10),_card([if(!_documents.any((f)=>f['tipo']=='Permiso HSE'))_empty('Sin permisos adjuntos'),_files(_documents.where((f)=>f['tipo']=='Permiso HSE').toList(),'project-document')])
  ];}
  @override Widget build(BuildContext context){
    final summary=WorksiteApi.map(_data['summary']),schedule=WorksiteApi.map(WorksiteApi.map(_data['meta'])['schedule']);
    final color=summary['color']=='red'?SibaColors.danger:summary['color']=='amber'?SibaColors.warning:summary['color']=='green'?SibaColors.success:SibaColors.muted;
    return Scaffold(appBar:AppBar(title:Text(widget.project.folio)),body:RefreshIndicator(onRefresh:_load,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.all(18),children:[
      Text(widget.project.title,style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:6),Text(widget.project.company,style:const TextStyle(color:SibaColors.muted)),const SizedBox(height:12),const Align(alignment:Alignment.centerLeft,child:SibaBadge(label:'Aceptado',background:SibaColors.success,foreground:Colors.white)),const SizedBox(height:20),
      if(_loading)const LinearProgressIndicator(),if(_error!=null)_card([Text(_error!,style:const TextStyle(color:SibaColors.danger)),TextButton(onPressed:_load,child:const Text('Reintentar'))]),
      if(_data.isNotEmpty)...[
        Text('Control de gastos',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:12),_card([const Text('Disponible',style:TextStyle(color:SibaColors.muted)),const SizedBox(height:8),Text(summary['available']==null?'Sin meta':sibaMoney(summary['available']),style:TextStyle(fontSize:30,fontWeight:FontWeight.w700,color:color)),if(summary['percent']!=null)...[const SizedBox(height:10),LinearProgressIndicator(value:(WorksiteApi.number(summary['percent'])/100).clamp(0.0,1.0),color:color,backgroundColor:color.withValues(alpha:.12)),const SizedBox(height:6),Text('${summary['label']} · ${WorksiteApi.number(summary['percent']).toStringAsFixed(1)}% usado',style:TextStyle(color:color))],const Divider(height:28),Text('Meta general: ${sibaMoney(summary['limit'])}'),const SizedBox(height:6),Text('Gastado: ${sibaMoney(summary['spent'])}'),const SizedBox(height:10),Text('${schedule['label']??'Sin fecha límite'}${schedule['end']==null?'':' · ${sibaDate(schedule['end'])}'}'),if(_manage)TextButton.icon(onPressed:_meta,icon:const Icon(Icons.edit_outlined,size:18),label:const Text('Editar meta y plazo'))]),
        Wrap(spacing:8,runSpacing:8,children:[for(final tab in ['Gastos','Requisiciones','Personal','Archivos','Informes'])ChoiceChip(label:Text(tab),selected:_tab==tab,onSelected:(_)=>setState(()=>_tab=tab))]),const SizedBox(height:18),
        if(_tab=='Gastos')..._expenses(),if(_tab=='Requisiciones')..._requests(),if(_tab=='Personal')..._personnel(),if(_tab=='Archivos')..._documentGroups(),if(_tab=='Informes')_card([const Icon(Icons.description_outlined,size:36,color:SibaColors.primary),const SizedBox(height:12),const Text('Informes de avance'),const SizedBox(height:12),FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProjectReportsPage(project:widget.project))),icon:const Icon(Icons.arrow_forward),label:const Text('Ver y crear informes'))]),
      ]
    ])));
  }
}
class RequisitionFormPage extends StatefulWidget{
  final String path;const RequisitionFormPage({super.key,required this.path});
  @override State<RequisitionFormPage> createState()=>_RequisitionFormPageState();
}
class _RequisitionFormPageState extends State<RequisitionFormPage>{
  final _form=GlobalKey<FormState>(),_date=TextEditingController(text:WorksiteApi.day(DateTime.now().toIso8601String())),_notes=TextEditingController();
  final _key=WorksiteApi.requestKey();final List<List<TextEditingController>> _items=[];List<SibaUpload> _files=[];bool _saving=false;String? _error;
  @override void initState(){super.initState();_add();}
  void _add()=>_items.add([TextEditingController(),TextEditingController(text:'1'),TextEditingController(text:'pza')]);
  @override void dispose(){_date.dispose();_notes.dispose();for(final row in _items){for(final c in row){c.dispose();}}super.dispose();}
  Future<void> _save()async{if(_saving||!_form.currentState!.validate())return;setState((){_saving=true;_error=null;});try{await WorksiteApi.upload(widget.path,{'fecha':_date.text,'notas':_notes.text,'solicitudKey':_key,'partidas':_items.map((r)=>{'descripcion':r[0].text.trim(),'cantidad':r[1].text.replaceAll(',',''),'unidad':r[2].text.trim()}).toList()},_files);if(mounted)Navigator.pop(context,true);}catch(e){if(mounted)setState(()=>_error='$e');}finally{if(mounted)setState(()=>_saving=false);}}
  @override Widget build(BuildContext context)=>PopScope(canPop:!_saving,child:Scaffold(appBar:AppBar(title:const Text('Nueva requisición')),body:Form(key:_form,child:ListView(padding:const EdgeInsets.all(20),children:[
    TextFormField(controller:_date,readOnly:true,decoration:const InputDecoration(labelText:'Fecha requerida',suffixIcon:Icon(Icons.calendar_today_outlined)),onTap:_saving?null:()async{final d=await showDatePicker(context:context,initialDate:DateTime.parse(_date.text),firstDate:DateTime(2000),lastDate:DateTime(2100));if(d!=null)_date.text=WorksiteApi.day(d.toIso8601String());}),const SizedBox(height:20),
    for(var i=0;i<_items.length;i++)Padding(padding:const EdgeInsets.only(bottom:16),child:SibaSurface(child:Column(children:[Row(children:[Expanded(child:Text('Material ${i+1}',style:const TextStyle(fontWeight:FontWeight.w700))),if(_items.length>1)IconButton(onPressed:_saving?null:(){final removed=_items[i];setState(()=>_items.removeAt(i));for(final c in removed){c.dispose();}},icon:const Icon(Icons.close))]),TextFormField(controller:_items[i][0],enabled:!_saving,decoration:const InputDecoration(labelText:'Material solicitado'),validator:(v)=>(v??'').trim().isEmpty?'Escribe el material':null),const SizedBox(height:12),Row(children:[Expanded(child:TextFormField(controller:_items[i][1],enabled:!_saving,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Cantidad'),validator:(v)=>(double.tryParse(v??'')??0)<=0?'Revisa cantidad':null)),const SizedBox(width:12),Expanded(child:TextFormField(controller:_items[i][2],enabled:!_saving,decoration:const InputDecoration(labelText:'Unidad'),validator:(v)=>(v??'').trim().isEmpty?'Escribe unidad':null))])]))),
    OutlinedButton.icon(onPressed:_saving||_items.length>=80?null:()=>setState(_add),icon:const Icon(Icons.add),label:const Text('Agregar material')),const SizedBox(height:16),TextFormField(controller:_notes,enabled:!_saving,maxLines:3,decoration:const InputDecoration(labelText:'Notas (opcional)')),const SizedBox(height:16),OutlinedButton.icon(onPressed:_saving?null:()async{try{final files=await chooseSibaFiles();if(mounted)setState(()=>_files=files);}catch(e){if(mounted)setState(()=>_error='$e');}},icon:const Icon(Icons.attach_file),label:Text(_files.isEmpty?'Adjuntar archivos':'${_files.length} archivos seleccionados')),for(final f in _files)Text(f.name),if(_error!=null)Text(_error!,style:const TextStyle(color:SibaColors.danger)),const SizedBox(height:20),FilledButton(onPressed:_saving?null:_save,child:Text(_saving?'Guardando…':'Guardar requisición'))
  ]))));
}
