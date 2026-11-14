"""Install prepared Android/iOS icon assets without Flutter or extra packages."""
from pathlib import Path
from datetime import datetime
import argparse, shutil, xml.etree.ElementTree as ET

def install(project,source):
    project=Path(project).resolve();source=Path(source).resolve()
    manifest=project/'android/app/src/main/AndroidManifest.xml';ios=project/'ios/Runner/Assets.xcassets'
    if not manifest.is_file() and not ios.is_dir():raise ValueError('Indica la raíz del proyecto Flutter: debe contener android o ios.')
    backup=project/'respaldo_iconos_siba'/datetime.now().strftime('%Y%m%d_%H%M%S_%f')
    def backup_file(path):
        if path.is_file():
            target=backup/path.relative_to(project);target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,target)
    def copy_tree(relative):
        for original in (source/'platform_icons'/relative).rglob('*'):
            if original.is_file():
                target=project/relative/original.relative_to(source/'platform_icons'/relative)
                backup_file(target);target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(original,target)
    if manifest.is_file():
        namespace='http://schemas.android.com/apk/res/android';ET.register_namespace('android',namespace)
        parser=ET.XMLParser(target=ET.TreeBuilder(insert_comments=True));tree=ET.parse(manifest,parser=parser);application=tree.getroot().find('application')
        if application is None:raise ValueError('No se encontró application en AndroidManifest.xml.')
        backup_file(manifest);copy_tree(Path('android/app/src/main/res'))
        application.set('{'+namespace+'}icon','@mipmap/ic_launcher');application.set('{'+namespace+'}roundIcon','@mipmap/ic_launcher_round')
        notice=next((m for m in application.findall('meta-data') if m.get('{'+namespace+'}name')=='com.google.firebase.messaging.default_notification_icon'),None)
        if notice is None:notice=ET.SubElement(application,'meta-data')
        notice.set('{'+namespace+'}name','com.google.firebase.messaging.default_notification_icon');notice.set('{'+namespace+'}resource','@drawable/siba_notification_icon')
        tree.write(manifest,encoding='utf-8',xml_declaration=True)
    if ios.is_dir():copy_tree(Path('ios/Runner/Assets.xcassets/AppIcon.appiconset'))
    return backup

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parents[1]);args=parser.parse_args()
    print('Íconos instalados. Respaldo:',install(args.project,Path(__file__).resolve().parents[1]))
