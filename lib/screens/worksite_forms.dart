import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_client.dart';
import '../services/worksite_api.dart';
import '../theme/siba_theme.dart';

class SibaField {
  final String name,label,kind;
  final bool isRequired;
  final Map<String,String> choices;
  const SibaField(this.name,this.label,{this.kind='text',this.isRequired=false,this.choices=const {}});
}
Future<List<SibaUpload>> chooseSibaFiles({bool document=false,bool camera=false}) async {
  if (camera) {
    final file = await ImagePicker().pickImage(source:ImageSource.camera,maxWidth:2200,imageQuality:85);
    if (file == null) return [];
    return [SibaUpload(file.path,file.name,await file.length())];
  }
  final List<PlatformFile> selected;
  if (document) {
    final item = await FilePicker.pickFile(type:FileType.any);
    selected = item == null ? <PlatformFile>[] : [item];
  } else {
    selected = await FilePicker.pickFiles(type:FileType.custom,allowedExtensions:['pdf','jpg','jpeg','png','webp']);
  }
  if (selected.isEmpty) return [];
  final files = <SibaUpload>[];
  for (final item in selected) {
    if (item.path == null) throw const ApiException('Guarda el archivo en el teléfono y selecciónalo nuevamente.');
    files.add(SibaUpload(item.path!,item.name,await File(item.path!).length()));
  }
  return files;
}
class SibaFormPage extends StatefulWidget {
  final String title;
  final List<SibaField> fields;
  final Map<String,dynamic> initial;
  final Future<void> Function(Map<String,dynamic>,List<SibaUpload>,String) onSave;
  final bool attachments,document;
  final String? note;
  const SibaFormPage({super.key,required this.title,required this.fields,required this.onSave,this.initial=const {},this.attachments=false,this.document=false,this.note});
  @override State<SibaFormPage> createState()=>_SibaFormPageState();
}
class _SibaFormPageState extends State<SibaFormPage> {
  final _form=GlobalKey<FormState>();final _key=WorksiteApi.requestKey();
  late final Map<String,TextEditingController> _controls;
  List<SibaUpload> _files=[];bool _saving=false;String? _error;
  @override void initState(){super.initState();_controls={for(final f in widget.fields)f.name:TextEditingController(text:'${widget.initial[f.name] ?? ''}')};}
  @override void dispose(){for(final c in _controls.values){c.dispose();}super.dispose();}
  Future<void> _pick({bool camera=false}) async {try{final files=await chooseSibaFiles(document:widget.document,camera:camera);if(files.isNotEmpty&&mounted)setState(()=>_files=widget.document?files:[..._files,...files.where((f)=>!_files.any((old)=>old.path==f.path))]);}catch(e){if(mounted)setState(()=>_error='$e');}}
  Future<void> _save() async {
    if(_saving||!_form.currentState!.validate())return;setState((){_saving=true;_error=null;});
    try {final data=<String,dynamic>{for(final f in widget.fields)f.name:_controls[f.name]!.text.trim()};for(final f in widget.fields.where((f)=>f.kind=='money')){data[f.name]=WorksiteApi.amount('${data[f.name]}');}await widget.onSave(data,_files,_key);if(mounted)Navigator.pop(context,true);}catch(e){if(mounted)setState(()=>_error='$e');}finally{if(mounted)setState(()=>_saving=false);}
  }
  Widget _field(SibaField field){
    final control=_controls[field.name]!;
    if(field.kind=='select')return DropdownButtonFormField<String>(value:field.choices.containsKey(control.text)?control.text:null,isExpanded:true,decoration:InputDecoration(labelText:field.label),items:field.choices.entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value,maxLines:1,overflow:TextOverflow.ellipsis))).toList(),onChanged:_saving?null:(v)=>setState(()=>control.text=v??''),validator:(v)=>field.isRequired&&(v==null||v.isEmpty)?'Selecciona una opción':null);
    return TextFormField(controller:control,enabled:!_saving,readOnly:field.kind=='date',maxLines:field.kind=='notes'?3:1,keyboardType:field.kind=='money'||field.kind=='number'?const TextInputType.numberWithOptions(decimal:true):TextInputType.text,decoration:InputDecoration(labelText:field.label,suffixIcon:field.kind=='date'?const Icon(Icons.calendar_today_outlined,size:18):null),validator:(v)=>field.isRequired&&(v??'').trim().isEmpty?'Completa este campo':null,onTap:field.kind=='date'?()async{final value=await showDatePicker(context:context,initialDate:DateTime.tryParse(control.text)??DateTime.now(),firstDate:DateTime(2000),lastDate:DateTime(2100));if(value!=null)control.text=value.toIso8601String().substring(0,10);}:null);
  }
  @override Widget build(BuildContext context)=>PopScope(canPop:!_saving,child:Scaffold(appBar:AppBar(title:Text(widget.title)),body:SafeArea(child:Form(key:_form,child:ListView(padding:const EdgeInsets.all(20),children:[if(widget.note!=null)...[Text(widget.note!,style:const TextStyle(color:SibaColors.muted)),const SizedBox(height:18)],for(final field in widget.fields)...[_field(field),const SizedBox(height:16)],if(widget.attachments)...[Wrap(spacing:10,runSpacing:8,children:[OutlinedButton.icon(onPressed:_saving?null:()=>_pick(),icon:const Icon(Icons.attach_file),label:const Text('Seleccionar archivos')),if(!widget.document)OutlinedButton.icon(onPressed:_saving?null:()=>_pick(camera:true),icon:const Icon(Icons.camera_alt_outlined),label:const Text('Foto del ticket'))]),for(final file in _files)ListTile(dense:true,contentPadding:EdgeInsets.zero,title:Text(file.name),trailing:IconButton(onPressed:_saving?null:()=>setState(()=>_files.remove(file)),icon:const Icon(Icons.close))),const SizedBox(height:14)],if(_error!=null)...[Text(_error!,style:const TextStyle(color:SibaColors.danger)),const SizedBox(height:14)],FilledButton(onPressed:_saving?null:_save,child:Text(_saving?'Guardando…':'Guardar'))])))));
}
