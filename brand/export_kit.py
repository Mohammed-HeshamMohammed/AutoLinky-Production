"""Export the complete, outlined AutoLinky logo family. Requires Pillow and fontTools."""
import importlib.util
import json
import math
from pathlib import Path
import shutil
import subprocess
import zipfile
from PIL import Image, ImageDraw, ImageFont
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.recordingPen import DecomposingRecordingPen

ROOT=Path(__file__).resolve().parent.parent
spec=importlib.util.spec_from_file_location('make_brand',ROOT/'mobile apps/shared/tool/make_brand.py')
brand=importlib.util.module_from_spec(spec);spec.loader.exec_module(brand)
SOURCE=ROOT/'brand/fonts/Sora/Sora-Variable.ttf'
UI_SOURCE=ROOT/'frontend/public/assets/workspace-fonts/Manrope-Variable.ttf'
WEIGHT=670
font=instantiateVariableFont(TTFont(SOURCE),{'wght':WEIGHT},inplace=False)
glyphs=font.getGlyphSet();cmap=font.getBestCmap();units=font['head'].unitsPerEm
FACTOR=4
# Match the selected A's 52-unit cap height, including the i dot and y descender.
font_pixels=round(52/font['OS/2'].sCapHeight*units*FACTOR)
scale=font_pixels/FACTOR/units
face=ImageFont.truetype(str(SOURCE),font_pixels);face.set_variation_by_axes([WEIGHT])
BASELINE=59
HEIGHT=80
CUSTOM=brand.IDENTITY['wordmark']['letters']
FORMATION=json.loads((ROOT/'brand/formation.json').read_text(encoding='utf-8'))
DOT_FINISH=round(FORMATION['letters']['i']['dot']['delay']+FORMATION['letters']['i']['dot']['duration'],6)

def lettering(text,custom=False):
    letters=[];cursor=0;previous=''
    optical={'to':-.65,'oL':-.45,'ky':-.45}
    for char in text:
        if previous:
            cursor+=(face.getlength(previous+char)-face.getlength(previous)-face.getlength(char))/FACTOR
            cursor+=optical.get(previous+char,-.25)
        name=cmap[ord(char)];pen=SVGPathPen(glyphs);glyphs[name].draw(pen)
        letters.append((char,cursor,pen.getCommands()))
        cursor+=CUSTOM[char]['advance'] if custom and char in CUSTOM else font['hmtx'][name][0]*scale
        previous=char
    return letters,math.ceil(cursor)

INTEGRATED,INTEGRATED_WIDTH=lettering('utoLinky',custom=True)
TEXT,TEXT_WIDTH=lettering('AutoLinky')

def palette(mode,mono=False):
    ink=brand.IDENTITY[mode]['text'] if mode=='light' else brand.IDENTITY[mode]['onHero']
    accent=brand.IDENTITY[mode]['accent'] if mode=='light' else brand.IDENTITY[mode]['heroAccent']
    if mono:ink=accent='000000' if mode=='light' else 'FFFFFF'
    return {'ink':ink,'accent':accent}

def letter_svg(mode,char,x,mono=False):
    colors=palette(mode,mono)
    letter=CUSTOM[char]
    paths=[]
    for path in letter['paths']:
        d=' '.join(c[0]+' '.join(str(n) for n in c[1:]) for c in path['commands'])
        paths.append(f'<path fill="#{colors[path["role"]]}" d="{d}"/>')
    return f'<g data-letter="{char}" transform="translate({x+letter["bearing"]:.3f} {BASELINE-letter["capHeight"]})">'+''.join(paths)+'</g>'

def paint_letter(canvas,mode,char,x,mono=False):
    colors=palette(mode,mono)
    letter=CUSTOM[char]
    # Sample the same outlines used by SVG into the supersampled export.
    draw=ImageDraw.Draw(canvas)
    def point(px,py):return ((x+letter['bearing']+px)*FACTOR,(BASELINE-letter['capHeight']+py)*FACTOR)
    for path in letter['paths']:
        points=[]
        for command in path['commands']:
            if command[0] in ('M','L'):points.append(point(*command[1:]))
            elif command[0]=='Q':
                start=points[-1];control,end=point(*command[1:3]),point(*command[3:5])
                for step in range(1,25):
                    t=step/24
                    points.append(tuple((1-t)**2*a+2*(1-t)*t*b+t*t*c for a,b,c in zip(start,control,end)))
            elif command[0]=='C':
                start=points[-1];c1,c2,end=point(*command[1:3]),point(*command[3:5]),point(*command[5:7])
                for step in range(1,33):
                    t=step/32
                    points.append(tuple((1-t)**3*a+3*(1-t)**2*t*b+3*(1-t)*t*t*c+t**3*d for a,b,c,d in zip(start,c1,c2,end)))
        draw.polygon(points,fill=brand.rgb(colors[path['role']])+(255,))

def save_png(image,path):
    # Encode before replacing so local asset readers never see a partial PNG.
    brand.save_image(image,path)

def mark_svg(mode,minimal=False,mono=False):
    data=brand.IDENTITY['mark']
    ink=brand.IDENTITY[mode]['text'];accent=brand.IDENTITY[mode]['accent']
    if mode=='dark':ink=brand.IDENTITY[mode]['onHero'];accent=data['paths'][-1]['color']
    if mono:ink='000000' if mode=='light' else 'FFFFFF'
    paths=[]
    for i,p in enumerate(data['paths']):
        color=ink if mono or p.get('role') == 'ink' else accent
        d=' '.join(c[0]+' '.join(str(n) for n in c[1:]) for c in p['commands'])
        paths.append(f'<path d="{d}" fill="#{color}"/>' if data.get('style') == 'filled' else f'<path d="{d}" stroke="#{color}"/>')
    background='' if minimal else f'<rect width="100" height="100" rx="24" fill="#{brand.IDENTITY[mode]["chrome"] if mode=="light" else data["background"]}"/>'
    return background+f'<g fill="none" stroke-width="8" stroke-linecap="round" stroke-linejoin="round">'+''.join(paths)+'</g>'

def art(mode,kind):
    mono=kind.endswith('monochrome')
    minimal=kind in ('logo-minimal','logo-monochrome')
    ink=brand.IDENTITY[mode]['text'] if mode=='light' else brand.IDENTITY[mode]['onHero']
    if mono:ink='000000' if mode=='light' else 'FFFFFF'
    if kind in ('logo-short','logo-minimal','logo-monochrome'):
        view='14 20 78 60' if minimal else '0 0 100 100'
        body=mark_svg(mode,minimal,mono);width,height=(78,60) if minimal else (100,100)
    else:
        integrated=kind in ('logo-full','logo-full-monochrome')
        offset=78 if integrated else 4
        letters,text_width=(INTEGRATED,INTEGRATED_WIDTH) if integrated else (TEXT,TEXT_WIDTH)
        width,height=text_width+offset+5,HEIGHT
        view=f'0 0 {width} {height}'
        body=(f'<g transform="translate(-14 -17)">{mark_svg(mode,True,mono)}</g>' if integrated else '')
        body+=''.join(letter_svg(mode,char,offset+x,mono) if integrated and char in CUSTOM else f'<path fill="#{ink}" transform="translate({offset+x:.3f} {BASELINE}) scale({scale} {-scale})" d="{path}"/>' for char,x,path in letters)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view}">{body}</svg>\n',width,height

def i_contours():
    """Separate the unchanged Sora dot from its stem/serif, without redrawing either."""
    recording=DecomposingRecordingPen(glyphs)
    glyphs[cmap[ord('i')]].draw(recording)
    contours=[];commands=[]
    for operation,points in recording.value:
        commands.append((operation,points))
        if operation in ('closePath','endPath'):
            pen=SVGPathPen(glyphs);bounds=BoundsPen(glyphs)
            for name,args in commands:
                getattr(pen,name)(*args);getattr(bounds,name)(*args)
            contours.append((pen.getCommands(),bounds.bounds));commands=[]
    dot=max(contours,key=lambda item:item[1][1])
    return ''.join(path for path,bounds in contours if bounds!=dot[1]),dot[0]

def dot_keyframes(name):
    frames=FORMATION['letters']['i']['dot']['keyframes']
    return f'@keyframes {name} {{'+''.join(
        f'{frame["at"]}% {{ transform:{"none" if frame["at"]==100 and frame["y"]==0 else "translateY("+str(frame["y"])+"px)"};opacity:{frame["opacity"]};animation-timing-function:{frame["easing"]} }}'
        for frame in frames)+'}'

def formation_data():
    """Share exact final outlines with the inline React and standalone SVG players."""
    groups=[]
    def path_data(path):
        return {'d':' '.join(c[0]+' '.join(str(n) for n in c[1:]) for c in path['commands']),'role':path['role']}
    main=[path_data(path) for path in brand.IDENTITY['mark']['paths']]
    for path,draw in zip(main,FORMATION['A']):path['draw']=draw
    groups.append({'id':'a','letter':'A','transform':'translate(-14 -17)',
        'bounds':{'x':14,'y':20,'width':78,'height':60},'paths':main})
    for index,(char,x,path) in enumerate(INTEGRATED):
        timing=FORMATION['letters'][char]
        if char=='i':
            stem,dot=i_contours()
            group={'id':f'letter-{index}','letter':char,
                'transform':f'translate({78+x:.3f} {BASELINE}) scale({scale} {-scale})',
                'bounds':{'x':0,'y':-2,'width':280,'height':800},
                'paths':[{'d':stem,'role':'ink','part':'stem','draw':timing['stem']},
                    {'d':dot,'role':'ink','part':'dot','bounce':timing['dot']}]}
        elif char in CUSTOM:
            letter=CUSTOM[char];paths=[path_data(item) for item in letter['paths']]
            for item,draw in zip(paths,timing['paths']):item['draw']=draw
            group={'id':f'letter-{index}','letter':char,
                'transform':f'translate({78+x+letter["bearing"]:.3f} {BASELINE-letter["capHeight"]})',
                'bounds':{'x':-2,'y':-2,'width':48,'height':64},'paths':paths}
        else:
            pen=BoundsPen(glyphs);glyphs[cmap[ord(char)]].draw(pen)
            low_x,low_y,high_x,high_y=pen.bounds
            group={'id':f'letter-{index}','letter':char,
                'transform':f'translate({78+x:.3f} {BASELINE}) scale({scale} {-scale})',
                'paths':[{'d':path,'role':'ink'}],
                'reveal':{'x':78+x+low_x*scale-1,'y':BASELINE-high_y*scale-1,
                    'width':(high_x-low_x)*scale+2,'height':(high_y-low_y)*scale+2,
                    'delay':timing['delay'],'duration':timing['duration']}}
        groups.append(group)
    return {'viewBox':f'0 0 {INTEGRATED_WIDTH+83} {HEIGHT}','width':INTEGRATED_WIDTH+83,
        'height':HEIGHT,'duration':FORMATION['duration'],'settle':FORMATION['settle'],'groups':groups}

def formation_svg(mode,data):
    """No script or font loading. The draw masks reveal the canonical filled paths."""
    colors=palette(mode);defs=[];body=[]
    for group in data['groups']:
        shapes=[];outer=''
        if 'reveal' in group:
            reveal=group['reveal'];clip=f'af-{mode}-{group["id"]}'
            defs.append(f'<clipPath id="{clip}" clipPathUnits="userSpaceOnUse"><rect class="af-wipe" '
                f'x="{reveal["x"]:.4f}" y="{reveal["y"]:.4f}" width="{reveal["width"]:.4f}" height="{reveal["height"]:.4f}" '
                f'style="--delay:{reveal["delay"]}s;--duration:{reveal["duration"]}s"/></clipPath>')
            outer=f' clip-path="url(#{clip})"'
        for index,path in enumerate(group['paths']):
            mask=''
            if 'draw' in path:
                trace=path['draw'];mask_id=f'af-{mode}-{group["id"]}-{index}'
                bounds=group['bounds']
                traces=[]
                for part_index,part in enumerate(trace.get('parts',[trace])):
                    trace_svg=(f'<path class="af-trace" d="{part["d"]}" fill="none" stroke="white" stroke-width="{part["strokeWidth"]}" stroke-linecap="round" stroke-linejoin="round" pathLength="1" '
                        f'style="--delay:{part["delay"]}s;--duration:{part["duration"]}s;--ease:{part.get("easing","cubic-bezier(.22,.7,.2,1)")}"/>')
                    if part.get('clip'):
                        part_id=f'{mask_id}-part-{part_index}'
                        defs.append(f'<clipPath id="{part_id}" clipPathUnits="userSpaceOnUse"><path d="{part["clip"]}"/></clipPath>')
                        trace_svg=f'<g clip-path="url(#{part_id})">{trace_svg}</g>'
                    traces.append(trace_svg)
                defs.append(f'<mask id="{mask_id}" maskUnits="userSpaceOnUse" x="{bounds["x"]}" y="{bounds["y"]}" width="{bounds["width"]}" height="{bounds["height"]}" style="mask-type:luminance">'
                    +''.join(traces)+f'<rect class="af-settle" x="{bounds["x"]}" y="{bounds["y"]}" width="{bounds["width"]}" height="{bounds["height"]}" fill="white"/></mask>')
                mask=f' mask="url(#{mask_id})"'
            shape=f'<g transform="{group["transform"]}"><path d="{path["d"]}" fill="var(--brand-{path["role"]},#{colors[path["role"]]})"{mask}/></g>'
            if 'bounce' in path:
                bounce=path['bounce']
                shape=f'<g class="af-dot" data-part="dot" style="--delay:{bounce["delay"]}s;--duration:{bounce["duration"]}s">{shape}</g>'
                shape+=f'<g class="af-dot-rest" data-part="dot-rest"><g transform="{group["transform"]}"><path d="{path["d"]}" fill="var(--brand-{path["role"]},#{colors[path["role"]]})"/></g></g>'
            elif path.get('part'):shape=f'<g data-part="{path["part"]}">{shape}</g>'
            shapes.append(shape)
        body.append(f'<g data-letter="{group["letter"]}"{outer}>'+''.join(shapes)+'</g>')
    styles=f'''<style>
@keyframes af-draw {{ 0% {{ stroke-dashoffset:1;opacity:0 }} .1% {{ opacity:1 }} 100% {{ stroke-dashoffset:0;opacity:1 }} }}
@keyframes af-wipe {{ from {{ transform:scaleX(0) }} to {{ transform:scaleX(1) }} }}
@keyframes af-settle {{ from {{ opacity:0 }} to {{ opacity:1 }} }}
{dot_keyframes('af-dot-bounce')}
@keyframes af-dot-hide {{ to {{ visibility:hidden }} }}
@keyframes af-dot-show {{ to {{ visibility:visible }} }}
.af-trace {{ stroke-dasharray:1 2;stroke-dashoffset:0 }}
.af-settle {{ opacity:1 }}
.af-dot-rest {{ display:none }}
@media (prefers-reduced-motion:no-preference) {{
  .is-forming .af-trace {{ stroke-dashoffset:1;animation:af-draw var(--duration) var(--ease) var(--delay) both }}
  .is-forming .af-wipe {{ transform-box:fill-box;transform-origin:left center;animation:af-wipe var(--duration) cubic-bezier(.22,.7,.2,1) var(--delay) both }}
  .is-forming .af-settle {{ opacity:0;animation:af-settle .001s steps(1,end) {data['settle']}s forwards }}
  .is-forming .af-dot {{ animation:af-dot-bounce var(--duration) linear var(--delay) both,af-dot-hide .001s steps(1,end) {DOT_FINISH}s forwards }}
  .is-forming .af-dot-rest {{ display:block;visibility:hidden;animation:af-dot-show .001s steps(1,end) {DOT_FINISH}s forwards }}
}}
@media (prefers-reduced-motion:reduce) {{
  .is-forming .af-trace {{ stroke-dashoffset:0;opacity:1;animation:none }}
  .is-forming .af-wipe {{ transform:none;animation:none }}
  .is-forming .af-settle {{ opacity:1;animation:none }}
  .is-forming .af-dot {{ transform:none;opacity:1;animation:none }}
}}
</style>'''
    return f'<svg xmlns="http://www.w3.org/2000/svg" class="is-forming" viewBox="{data["viewBox"]}" role="img" aria-labelledby="af-title"><title id="af-title">AutoLinky logo formation</title>{styles}<defs>'+''.join(defs)+'</defs>'+''.join(body)+'</svg>\n'

def export_formation(output):
    data=formation_data()
    module='// Generated by brand/export_kit.py from identity.json and formation.json.\n'
    module+='export const brandFormation = '+json.dumps(data,separators=(',',':'))+';\n'
    (ROOT/'frontend/src/brandFormation.js').write_text(module,encoding='utf-8')
    css='/* Generated i-dot motion from brand/formation.json. */\n'+dot_keyframes('brand-dot-bounce')+'\n'
    css+='@keyframes brand-dot-hide { to { visibility:hidden; } }\n@keyframes brand-dot-show { to { visibility:visible; } }\n'
    css+='.brand-form-dot-rest { display:none; }\n'
    css+=f'.brand-wordmark.is-forming .brand-form-dot {{ animation:brand-dot-bounce var(--form-duration) linear var(--form-delay) both,brand-dot-hide .001s steps(1,end) {DOT_FINISH}s forwards; }}\n'
    css+=f'.brand-wordmark.is-forming .brand-form-dot-rest {{ display:block;visibility:hidden;animation:brand-dot-show .001s steps(1,end) {DOT_FINISH}s forwards; }}\n'
    css+='@media (prefers-reduced-motion:reduce) { .brand-wordmark .brand-form-dot { transform:none;opacity:1;animation:none!important; } }\n'
    (ROOT/'frontend/src/brandFormation.css').write_text(css,encoding='utf-8')
    for mode in ('light','dark'):
        svg=formation_svg(mode,data)
        (output/mode/'logo-formation.svg').write_text(svg,encoding='utf-8')
        (brand.WEB/f'logo-formation-{mode}.svg').write_text(svg,encoding='utf-8')
    (output/'formation.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')

def png(mode,kind,width,height):
    canvas=Image.new('RGBA',(width*FACTOR,height*FACTOR))
    ink=brand.rgb(brand.IDENTITY[mode]['text'] if mode=='light' else brand.IDENTITY[mode]['onHero'])+(255,)
    if kind.endswith('monochrome'):ink=(0,0,0,255) if mode=='light' else (255,255,255,255)
    paths=brand.IDENTITY['mark']['paths']
    original=[p['color'] for p in paths]
    for i,p in enumerate(paths):p['color']=(''.join(f'{v:02X}' for v in ink[:3]) if kind.endswith('monochrome') or p.get('role') == 'ink' else brand.IDENTITY[mode]['accent'] if mode=='light' else 'BED2A8')
    mark=brand.mark(100*FACTOR)
    for p,color in zip(paths,original):p['color']=color
    if kind=='logo-short':
        tile=Image.new('RGBA',(100*FACTOR,100*FACTOR),brand.rgb(brand.IDENTITY[mode]['chrome'] if mode=='light' else '171C19')+(255,));tile.alpha_composite(mark);tile=brand.rounded(tile,.24);canvas.alpha_composite(tile)
    elif kind in ('logo-minimal','logo-monochrome'):
        canvas.alpha_composite(mark.crop(tuple(v*FACTOR for v in (14,20,92,80))))
    elif kind in ('logo-full','logo-full-monochrome'):
        canvas.alpha_composite(mark,(-14*FACTOR,-17*FACTOR))
    if kind in ('wordmark','wordmark-monochrome','logo-full','logo-full-monochrome'):
        integrated=kind in ('logo-full','logo-full-monochrome')
        offset=78 if integrated else 4;draw=ImageDraw.Draw(canvas)
        letters=INTEGRATED if integrated else TEXT
        for char,x,_ in letters:
            if integrated and char in CUSTOM:paint_letter(canvas,mode,char,offset+x,kind.endswith('monochrome'))
            else:draw.text(((offset+x)*FACTOR,BASELINE*FACTOR),char,font=face,fill=ink,anchor='ls')
    return canvas

def export():
    output=ROOT/'brand/assets';output.mkdir(parents=True,exist_ok=True)
    kinds=['logo-full','logo-full-monochrome','wordmark','logo-short','logo-minimal','logo-monochrome','wordmark-monochrome']
    for mode in ('light','dark'):
        directory=output/mode;directory.mkdir(exist_ok=True)
        for kind in kinds:
            svg,w,h=art(mode,kind)
            (directory/f'{kind}.svg').write_text(svg,encoding='utf-8')
            image=png(mode,kind,w,h);save_png(image,directory/f'{kind}.png')
            for target in (brand.OUT,brand.WEB):
                if kind=='logo-short':
                    (target/f'logo-{mode}.svg').write_text(svg,encoding='utf-8')
                if kind=='wordmark':
                    (target/f'wordmark-{mode}.svg').write_text(svg,encoding='utf-8')
                if kind=='logo-full':
                    (target/f'logo-full-{mode}.svg').write_text(svg,encoding='utf-8')
        # The in-app native mark follows the app's light/dark appearance.
        catalog=brand.IOS/'BrandLogo.imageset'
        for kind,name in [('logo-short','logo'),('logo-full','wordmark')]:
            if name=='wordmark':catalog=brand.IOS/'BrandWordmark.imageset';catalog.mkdir(exist_ok=True)
            image=Image.open(directory/f'{kind}.png');save_png(image,catalog/f'{name}-{mode}.png')
    for folder,stem in [('BrandLogo.imageset','logo'),('BrandWordmark.imageset','wordmark')]:
        catalog=brand.IOS/folder
        images=[{'idiom':'universal','filename':f'{stem}-light.png'},{'idiom':'universal','filename':f'{stem}-dark.png','appearances':[{'appearance':'luminosity','value':'dark'}]}]
        (catalog/'Contents.json').write_text(json.dumps({'images':images,'info':{'author':'xcode','version':1}},indent=2)+'\n',encoding='utf-8')
    export_formation(output)
    legacy=brand.IOS/'BrandLogo.imageset/logo.png'
    if legacy.exists():legacy.unlink()
    # Separate native splash sources, including Android 12's larger transparent canvas.
    for mode in ('light','dark'):
        tile=Image.open(output/mode/'logo-short.png').resize((512,512),Image.Resampling.LANCZOS)
        suffix='' if mode=='light' else '_dark'
        save_png(tile.resize((384,384),Image.Resampling.LANCZOS),brand.OUT/f'splash{suffix}.png')
        splash=Image.new('RGBA',(1152,1152));splash.alpha_composite(tile,(320,320));save_png(splash,brand.OUT/f'splash_android12{suffix}.png')
    app_assets=output/'app';app_assets.mkdir(exist_ok=True)
    for name in ['icon.png','icon_background.png','icon_foreground.png','icon_monochrome.png','splash.png','splash_dark.png']:
        shutil.copyfile(brand.OUT/name,app_assets/name)
    for name in ['favicon.svg','favicon.ico','apple-touch-icon.png','icon-192.png','icon-512.png']:
        shutil.copyfile(brand.WEB/name,app_assets/name)
    # Human-readable contact sheet contains the real exported logo assets.
    board=Image.new('RGB',(1500,1500),'#fbfbf9');draw=ImageDraw.Draw(board)
    label=ImageFont.truetype(str(UI_SOURCE),19);label.set_variation_by_axes([500])
    title=ImageFont.truetype(str(UI_SOURCE),29);title.set_variation_by_axes([650])
    labels=['Integrated logo','Monochrome logo','Text logo / Sora 670','Compact','Minimal','Monochrome mark','Monochrome text']
    for column,mode in enumerate(('light','dark')):
        x=column*750;bg='#fbfbf9' if mode=='light' else '#171c19';fg='#252a29' if mode=='light' else '#eeeade'
        draw.rectangle((x,0,x+749,1499),fill=bg);draw.text((x+42,35),'AutoLinky / '+mode.upper(),font=title,fill=fg)
        for row,kind in enumerate(kinds):
            y=120+row*180;draw.text((x+42,y),labels[row],font=label,fill=fg)
            image=Image.open(output/mode/f'{kind}.png');image.thumbnail((600,108),Image.Resampling.LANCZOS);board.paste(image,(x+42,y+38),image)
        draw.text((x+42,1420),'A leads. L echoes.',font=label,fill=fg)
    save_png(board,ROOT/'brand/brand-kit.png')
    preview=Image.new('RGB',(1500,300),'#fbfbf9');preview_draw=ImageDraw.Draw(preview)
    for column,mode in enumerate(('light','dark')):
        x=column*750;bg='#fbfbf9' if mode=='light' else '#171c19';fg='#252a29' if mode=='light' else '#eeeade'
        preview_draw.rectangle((x,0,x+749,299),fill=bg)
        preview_draw.text((x+42,35),'AUTOLINKY / '+mode.upper(),font=label,fill=fg)
        image=Image.open(output/mode/'logo-full.png');image.thumbnail((660,150),Image.Resampling.LANCZOS)
        preview.paste(image,(x+40,95),image)
    preview_path=ROOT/'frontend/output/playwright/wordmark-preview.png';preview_path.parent.mkdir(parents=True,exist_ok=True);save_png(preview,preview_path)
    social=Image.new('RGB',(1200,630),'#171c19');social_draw=ImageDraw.Draw(social)
    header=Image.open(output/'dark/logo-full.png');header.thumbnail((330,80),Image.Resampling.LANCZOS);social.paste(header,(65,40),header)
    heading=ImageFont.truetype(str(UI_SOURCE),66);heading.set_variation_by_axes([700])
    body=ImageFont.truetype(str(UI_SOURCE),24);body.set_variation_by_axes([500])
    social_draw.text((65,210),'Your next job.',font=heading,fill='#eeeade')
    social_draw.text((65,295),'Less busywork.',font=heading,fill='#bed2a8')
    social_draw.text((68,430),'CV matching. Applications at your pace.',font=body,fill='#b4beb2')
    social_draw.text((68,540),'A more personal job search.',font=body,fill='#b4beb2')
    symbol=Image.open(output/'dark/logo-minimal.png');symbol.thumbnail((330,270),Image.Resampling.LANCZOS);social.paste(symbol,(820,220),symbol)
    save_png(social,brand.WEB/'og.png');save_png(social,output/'app/social-preview.png')
    archive=ROOT/'frontend/output/playwright/autolinky-brand-kit.zip';archive.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as zipped:
        for path in output.rglob('*'):
            if path.is_file():zipped.write(path,path.relative_to(ROOT/'brand'))
        if (ROOT/'brand/README.md').exists():zipped.write(ROOT/'brand/README.md','README.md')
        if (ROOT/'brand/PACKAGE.md').exists():zipped.write(ROOT/'brand/PACKAGE.md','PACKAGE.md')
        zipped.write(ROOT/'brand/concepts/README.md','concepts/README.md')
        zipped.write(ROOT/'brand/identity.json','identity.json');zipped.write(ROOT/'brand/brand-kit.png','brand-kit.png')
        zipped.write(ROOT/'brand/formation.json','formation.json')
        for path in (ROOT/'brand/fonts').rglob('*'):
            if path.is_file():zipped.write(path,path.relative_to(ROOT/'brand'))
    subprocess.run(['node',str(ROOT/'frontend/scripts/refresh-brand-assets.mjs')],cwd=ROOT,check=True)
    print('Exported outlined light/dark full, text, short, minimal and monochrome logo sets, native variants and ZIP.')

if __name__=='__main__':export()
