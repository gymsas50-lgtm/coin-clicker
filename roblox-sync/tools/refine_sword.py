from pathlib import Path
import xml.etree.ElementTree as E,math
p=Path(__file__).resolve().parents[1]/'src/RoyalSword.rbxmx';tree=E.parse(p);tool=tree.getroot().find('Item');handle=next(i for i in tool.findall('Item') if i.get('referent')=='Part1');script=next(i for i in tool.findall('Item') if i.get('class')=='Script')
for i in list(tool.findall('Item')):
 if i is not handle and i is not script:tool.remove(i)
count=100

def val(p,t,n,v):E.SubElement(p,t,{'name':n}).text=str(v)
def part(name,pos,size,color,angle=0,material=1088,shape=1):
 global count
 count+=1;ref='Detail'+str(count);item=E.SubElement(tool,'Item',{'class':'Part','referent':ref});pr=E.SubElement(item,'Properties');val(pr,'string','Name',name)
 for n,v in [('Anchored','false'),('CanCollide','false'),('CanTouch','false'),('CanQuery','false'),('Massless','true')]:val(pr,'bool',n,v)
 val(pr,'token','Material',material);val(pr,'token','TopSurface',0);val(pr,'token','BottomSurface',0);val(pr,'token','shape',shape)
 cf=E.SubElement(pr,'CoordinateFrame',{'name':'CFrame'});co,si=math.cos(angle),math.sin(angle)
 for n,v in zip(['X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'],[*pos,co,-si,0,si,co,0,0,0,1]):E.SubElement(cf,n).text=str(v)
 vec=E.SubElement(pr,'Vector3',{'name':'size'})
 for n,v in zip('XYZ',size):E.SubElement(vec,n).text=str(v)
 c=E.SubElement(pr,'Color3',{'name':'Color'})
 for n,v in zip('RGB',color):E.SubElement(c,n).text=str(v/255)
 w=E.SubElement(item,'Item',{'class':'WeldConstraint','referent':'W'+str(count)});wp=E.SubElement(w,'Properties');val(wp,'string','Name','HandleWeld');val(wp,'Ref','Part0','Part1');val(wp,'Ref','Part1',ref)

steel=(161,183,205);edge=(227,238,247);gold=(204,160,75);lightgold=(238,202,112);deepgold=(134,91,38);blue=(34,122,181);ice=(108,209,235)
# Leather winding, gold collars and stacked pommel.
for i in range(-4,5):
 part('Leather winding',(0,i*.106,0),(.302,.032,.302),(86,76,60),-.12,material=256)
for y in [-.53,.5]:part('Engraved grip collar',(0,y,0),(.37,.10,.35),gold)
part('Pommel base',(0,-.66,0),(.47,.27,.37),gold)
part('Pommel setting',(0,-.78,0),(.34,.34,.32),deepgold,math.pi/4)
for face in [-1,1]:
 part('Pommel sapphire',(0,-.73,face*.205),(.235,.29,.11),blue,math.pi/4,material=1568)
 part('Gem glint',(-.035,-.68,face*.268),(.065,.1,.018),ice,math.pi/4,material=288)
# Swept quillons with layered contrasting gold trim.
part('Central guard',(0,.65,0),(1.15,.22,.41),gold)
for side in [-1,1]:
 for k in range(4):
  x=side*(.55+k*.19);y=.66-k*.065;angle=side*(-.13-k*.11)
  part('Swept golden quillon',(x,y,0),(.34,.19,.34-k*.025),gold,angle)
  part('Guard polished crest',(x,y+.085,-.02),(.30,.035,.25-k*.02),lightgold,angle)
 part('Quillon jewel setting',(side*1.22,.39,0),(.25,.30,.27),deepgold,side*-.6)
 part('Quillon sapphire',(side*1.24,.39,-.15),(.15,.20,.07),blue,math.pi/4,1568)
for face in [-1,1]:
 part('Guard diamond setting',(0,.72,face*.25),(.43,.49,.1),lightgold,math.pi/4)
 part('Guard sapphire',(0,.72,face*.32),(.28,.34,.1),blue,math.pi/4,1568)
 part('Guard sapphire highlight',(-.045,.79,face*.379),(.065,.13,.018),ice,.4,288)
# Broad steel faces, polished edges, central fuller and gold ricasso.
part('Tempered blade',(0,2.34,0),(.60,3.16,.13),steel)
for side in [-1,1]:part('Silver cutting bevel',(side*.325,2.34,0),(.065,3.16,.065),edge)
for face in [-1,1]:
 part('Blue steel fuller',(0,2.40,face*.08),(.16,2.82,.033),(51,79,109))
 for side in [-1,1]:part('Fuller polished ridge',(side*.105,2.4,face*.075),(.028,2.83,.026),edge)
 part('Gold ricasso',(0,1.04,face*.085),(.49,.5,.035),gold)
 part('Ricasso crest',(0,1.1,face*.112),(.19,.27,.028),lightgold,math.pi/4)
 # Small inset diamond runes, not a giant glow strip.
 for i in range(4):part('Sapphire rune',(0,1.65+i*.43,face*.107),(.066,.125,.02),ice,math.pi/4,288)
# Tapered crown of closely joined steel sections ends in an actual narrow point.
for i in range(16):
 width=.665*(1-i/16);y=3.92+(i+.5)*.047
 part('Tapered blade tip',(0,y,0),(width,.047,.13*(1-i/19)),edge if i>11 else steel)
 if i<11:
  for face in [-1,1]:part('Tip fuller',(0,y,face*.071),(.14*(1-i/12),.047,.018),(51,79,109))
part('Needle point',(0,4.69,0),(.018,.035,.018),edge)
tool.find("Properties/string[@name='ToolTip']").text='Сапфировый страж'
tree.write(p,encoding='utf-8',xml_declaration=True)
print('New sword detail parts:',count-100,'; equipped grip script preserved')
