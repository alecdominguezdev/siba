import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/biometric_service.dart';
import '../theme/siba_theme.dart';
import '../widgets/siba_widgets.dart';
import 'shell_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState()=>_LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final _form=GlobalKey<FormState>();
  final _username=TextEditingController();
  final _password=TextEditingController();
  bool _saving=false,_obscure=true;String? _error;
  @override void dispose(){_username.dispose();_password.dispose();super.dispose();}
  Future<void> _login({bool biometric=false}) async {
    if(_saving||(!biometric&&!_form.currentState!.validate()))return;
    setState((){_saving=true;_error=null;});
    try {
      if(biometric){
        final verified=await BiometricService.verifyForDeviceAccess(localizedReason:'Abre tu sesión de SIBA.');
        if(!verified.verified)return;
        await ApiClient.instance.me();
      }else{await ApiClient.instance.login(_username.text,_password.text);}
      if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const SibaShellPage()),(_)=>false);
    }catch(e){if(mounted)setState(()=>_error='$e');}
    finally{if(mounted)setState(()=>_saving=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:SibaColors.canvas,
    body:SafeArea(child:Center(child:SingleChildScrollView(
      padding:const EdgeInsets.all(24),
      child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:430),
        child:SibaSurface(child:Form(key:_form,
          child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            const Align(alignment:Alignment.centerLeft,child:SibaLogo(width:170)),
            const SizedBox(height:26),
            Text('Iniciar sesión',style:Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height:8),
            const Text('Ingresa con tu cuenta de SIBA.',style:TextStyle(color:SibaColors.muted)),
            const SizedBox(height:24),
            TextFormField(controller:_username,enabled:!_saving,
              autofillHints:const [AutofillHints.username],textInputAction:TextInputAction.next,
              decoration:const InputDecoration(labelText:'Usuario',prefixIcon:Icon(Icons.person_outline)),
              validator:(v)=>(v??'').trim().isEmpty?'Escribe tu usuario':null),
            const SizedBox(height:16),
            TextFormField(controller:_password,enabled:!_saving,obscureText:_obscure,
              autofillHints:const [AutofillHints.password],onFieldSubmitted:(_)=>_login(),
              decoration:InputDecoration(labelText:'Contraseña',prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(onPressed:()=>setState(()=>_obscure=!_obscure),icon:Icon(_obscure?Icons.visibility_outlined:Icons.visibility_off_outlined))),
              validator:(v)=>(v??'').isEmpty?'Escribe tu contraseña':null),
            if(_error!=null)...[const SizedBox(height:16),Text(_error!,style:const TextStyle(color:SibaColors.danger))],
            const SizedBox(height:24),
            FilledButton(onPressed:_saving?null:()=>_login(),child:Text(_saving?'Ingresando…':'Entrar')),
            if(ApiClient.instance.biometricLoginEnabled)...[
              const SizedBox(height:10),OutlinedButton.icon(onPressed:_saving?null:()=>_login(biometric:true),icon:const Icon(Icons.fingerprint),label:const Text('Abrir sesión guardada'))
            ],
            const SizedBox(height:20),const Text('SIBA · Aplicación de obra',textAlign:TextAlign.center,style:TextStyle(color:SibaColors.muted,fontSize:12))
          ]),
        )),
      ),
    ))),
  );
}
