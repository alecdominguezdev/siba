"""Prepare native app resources from SIBA's isolated gray symbol (Pillow)."""
from pathlib import Path
import json
from PIL import Image, ImageOps, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
source=Image.open(ROOT/'assets/branding/siba_simbolo.png').convert('RGBA')
source=source.crop(source.getchannel('A').getbbox())
background=(244,246,248)
res=ROOT/'platform_icons/android/app/src/main/res'

def placed(size,box,monochrome=False):
    mark=ImageOps.contain(source,(box,box),Image.Resampling.LANCZOS)
    if monochrome:
        alpha=mark.getchannel('A');mark=Image.new('RGBA',mark.size,'white');mark.putalpha(alpha)
    result=Image.new('RGBA',(size,size),(0,0,0,0));result.alpha_composite(mark,((size-mark.width)//2,(size-mark.height)//2));return result

def icon(size):
    result=Image.new('RGBA',(size,size),background+(255,));result.alpha_composite(placed(size,round(size*.82)));return result.convert('RGB')

for density,scale in [('mdpi',1),('hdpi',1.5),('xhdpi',2),('xxhdpi',3),('xxxhdpi',4)]:
    path=res/('mipmap-'+density);path.mkdir(parents=True,exist_ok=True)
    size=round(48*scale);square=icon(size);square.save(path/'ic_launcher.png')
    mask=Image.new('L',(size*4,size*4),0);ImageDraw.Draw(mask).ellipse((0,0,size*4-1,size*4-1),fill=255)
    rounded=square.convert('RGBA');rounded.putalpha(mask.resize((size,size),Image.Resampling.LANCZOS));rounded.save(path/'ic_launcher_round.png')
    placed(round(108*scale),round(58*scale)).save(path/'ic_siba_foreground.png')
    placed(round(108*scale),round(58*scale),True).save(path/'ic_siba_monochrome.png')
    path=res/('drawable-'+density);path.mkdir(parents=True,exist_ok=True)
    placed(round(24*scale),round(20*scale),True).save(path/'siba_notification_icon.png')

for qualifier,mono in [('v26',False),('v33',True)]:
    path=res/('mipmap-anydpi-'+qualifier);path.mkdir(parents=True,exist_ok=True)
    xml='''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/siba_launcher_background" />
    <foreground android:drawable="@mipmap/ic_siba_foreground" />
'''+('    <monochrome android:drawable="@mipmap/ic_siba_monochrome" />\n' if mono else '')+'</adaptive-icon>\n'
    for filename in ['ic_launcher.xml','ic_launcher_round.xml']:(path/filename).write_text(xml)
path=res/'values';path.mkdir(parents=True,exist_ok=True)
(path/'siba_launcher_colors.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<resources><color name="siba_launcher_background">#F4F6F8</color></resources>\n')
ios=ROOT/'platform_icons/ios/Runner/Assets.xcassets/AppIcon.appiconset';ios.mkdir(parents=True,exist_ok=True)
entries=[]
def add(size,scale,idiom):
    filename=f'Icon-App-{size}x{size}@{scale}x.png';pixels=round(float(size)*scale);icon(pixels).save(ios/filename)
    entries.append({'size':f'{size}x{size}','idiom':idiom,'filename':filename,'scale':f'{scale}x'})
for size in ['20','29','40']:
    for scale in [2,3]:add(size,scale,'iphone')
for scale in [2,3]:add('60',scale,'iphone')
for size in ['20','29','40','76']:
    for scale in [1,2]:add(size,scale,'ipad')
add('83.5',2,'ipad');add('1024',1,'ios-marketing')
(ios/'Contents.json').write_text(json.dumps({'images':entries,'info':{'version':1,'author':'xcode'}},indent=2)+'\n')
icon(1024).save(ROOT/'branding/siba_app_icon_1024.png')
icon(256).save(ROOT.parent/'SIBA_icono_app.png')
print('Generated Android launcher/adaptive/themed/notification resources and iOS AppIcon assets.')
