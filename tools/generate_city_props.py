#!/usr/bin/env python3
"""Build editable Godot mesh scenes for HackerQuest's blocky street kit."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/iso/props/city'
COLORS = {
    'ink': '172132', 'metal': '344356', 'edge': '536278', 'black': '0b1220',
    'cream': 'e7d4ae', 'wood': '805a43', 'teal': '38bca9', 'pink': 'e65c9b',
    'amber': 'f7b95f', 'blue': '5a89bd', 'cyan': '75eced', 'green': 'a2ee94',
    'steam': 'b9dce2', 'purple': '9a78d0', 'red': 'c96058',
}

class Model:
    def __init__(self, name, motion='none'):
        self.name, self.motion = name, motion
        self.nodes, self.resources, self.materials = [], [], {}
        self.mesh_count = 0

    def material(self, color, glow=False):
        key = (color, glow)
        if key not in self.materials:
            mid = f'm{len(self.materials)}'
            self.materials[key] = mid
            h = COLORS[color]
            rgb = ', '.join(f'{int(h[i:i+2],16)/255:.5f}' for i in (0,2,4))
            s = f'[sub_resource type="StandardMaterial3D" id="{mid}"]\nalbedo_color = Color({rgb}, 1)\nroughness = 0.72\n'
            if glow:
                s += f'emission_enabled = true\nemission = Color({rgb}, 1)\nemission_energy_multiplier = 1.25\n'
            self.resources.append(s)
        return self.materials[key]

    def node(self, name, pos=(0,0,0), parent='.'):
        self.nodes.append(f'[node name="{name}" type="Node3D" parent="{parent}"]\nposition = Vector3{pos}\n')

    def box(self, name, pos, size, color='metal', glow=False, parent='.'):
        mid = self.material(color, glow)
        bid = f'b{self.mesh_count}'
        self.mesh_count += 1
        self.resources.append(f'[sub_resource type="BoxMesh" id="{bid}"]\nmaterial = SubResource("{mid}")\nsize = Vector3{size}\n')
        self.nodes.append(f'[node name="{name}" type="MeshInstance3D" parent="{parent}"]\nposition = Vector3{pos}\nmesh = SubResource("{bid}")\n')

    def solid(self, pos, size):
        n = f'Collision{len(self.nodes)}'
        self.resources.append(f'[sub_resource type="BoxShape3D" id="{n}"]\nsize = Vector3{size}\n')
        self.nodes.append(f'[node name="{n}" type="StaticBody3D" parent="."]\nposition = Vector3{pos}\n\n[node name="Shape" type="CollisionShape3D" parent="{n}"]\nshape = SubResource("{n}")\n')

    def text(self, text, pos, size=26):
        n = f'Sign{len(self.nodes)}'
        self.nodes.append(f'[node name="{n}" type="Label3D" parent="."]\nposition = Vector3{pos}\npixel_size = 0.0025\nfont_size = {size}\noutline_size = 2\ntext = "{text}"\nmodulate = Color(0.85, 0.97, 1, 1)\n')

    def save(self):
        root = f'[node name="{self.name}" type="Node3D"]\nscript = ExtResource("1")\nmotion = "{self.motion}"\n'
        header = '[gd_scene format=3]\n\n[ext_resource type="Script" path="res://scripts/iso/city_prop_motion.gd" id="1"]\n\n'
        (OUT / f'prop_{self.name}.tscn').write_text(header + '\n'.join(self.resources) + '\n' + root + '\n' + '\n'.join(self.nodes))


def vending():
    m = Model('vending_machine', 'screen')
    m.box('Cabinet', (0,.85,0), (1.1,1.7,.75), 'ink')
    m.box('Header', (0,1.58,.40), (1,.22,.06), 'teal')
    m.text('COLD BYTES', (0,1.58,.44), 27)
    m.box('Window', (-.15,1.01,.39), (.65,.8,.035), 'black')
    for row in range(3):
        for col in range(3):
            m.box(f'Can{row}{col}', (-.36+col*.21,.76+row*.22,.43), (.12,.16,.09), ['pink','amber','cyan'][(row+col)%3], True)
    m.box('Screen', (.38,1.22,.40), (.16,.24,.05), 'cyan', True)
    m.box('CoinSlot', (.38,.95,.41), (.10,.04,.05), 'black')
    m.box('Dispense', (-.1,.27,.41), (.65,.22,.06), 'black')
    m.box('Lip', (-.1,.16,.46), (.7,.06,.16), 'edge')
    for x in [-.53,.53]:
        m.box(f'Trim{x}', (x,.85,.4), (.025,1.6,.025), 'cyan', True)
    m.solid((0,.85,0),(1.1,1.7,.75))
    return m


def noodle():
    m=Model('noodle_cart','steam')
    m.box('Cart', (0,.58,0),(2.2,.86,1.0),'ink')
    m.box('Worktop',(0,1.04,0),(2.4,.10,1.15),'edge')
    for x in [-.85,.85]:
        m.box(f'Wheel{x}',(x,.2,0),(.28,.38,.75),'black')
        m.box(f'Post{x}',(x,1.54,-.4),(.07,1.0,.07),'metal')
    m.box('Canopy',(0,2.05,-.06),(2.6,.13,1.45),'red')
    m.box('CanopyTrim',(0,2.0,.67),(2.6,.06,.04),'amber',True)
    for i in range(5):
        m.box(f'Curtain{i}',(-.9+i*.45,1.83,.55),(.36,.35,.035),'cream')
    m.box('Pot',(-.5,1.22,0),(.52,.28,.48),'metal')
    m.box('Broth',(-.5,1.37,0),(.44,.02,.4),'amber')
    m.box('Extractor',(-.5,1.65,-.1),(.65,.10,.55),'metal')
    m.box('Chimney',(-.5,2.17,-.1),(.22,.4,.22),'metal')
    for i in range(3):
        m.box(f'Steam{i}',(-.6+i*.12,2.4+i*.18,-.1),(.10,.12,.10),'steam')
    for i in range(3):
        m.box(f'Bowl{i}',(.2+i*.25,1.15,.22),(.18,.12,.18),'cream')
    m.box('Menu',(.8,1.45,-.35),(.4,.65,.05),'black')
    for i in range(4):
        m.box(f'MenuLine{i}',(.8,1.63-i*.11,-.31),(.27,.025,.01),'amber',True)
    m.box('FrontPanel',(0,.65,.51),(1.5,.40,.03),'red')
    m.text('N O O D L E S', (0,.65,.54),32)
    m.solid((0,.58,0),(2.2,1.1,1))
    return m


def arcade():
    m=Model('arcade_cabinet','arcade')
    m.box('Base',(0,.45,0),(.85,.9,.8),'purple')
    m.box('ScreenHousing',(0,1.20,-.10),(.85,.65,.6),'ink')
    m.box('Screen',(0,1.22,.22),(.66,.46,.035),'black')
    m.box('Marquee',(0,1.66,0),(.95,.24,.85),'pink')
    m.text('NEON RUN', (0,1.66,.435),28)
    m.box('ControlDeck',(0,.94,.26),(.93,.12,.65),'edge')
    m.box('Stick',(-.23,1.07,.34),(.04,.17,.04),'black')
    m.box('StickTop',(-.23,1.17,.34),(.1,.08,.1),'pink',True)
    for x in [.13,.30]:
        m.box(f'Button{x}',(x,1.02,.35),(.1,.04,.1),'cyan',True)
    for i in range(5):
        m.box(f'Pixel{i}',(-.23+i*.115,1.16+(i%2)*.1,.245),(.065,.065,.015),'green',True)
    m.box('CoinDoor',(0,.38,.41),(.30,.30,.025),'black')
    m.box('NeonFoot',(0,.07,.42),(.80,.04,.025),'pink',True)
    m.solid((0,.8,0),(.95,1.6,.85))
    return m


def shelter():
    m=Model('transit_shelter','screen')
    for x in [-1.5,1.5]:
        m.box(f'Post{x}',(x,1.15,-.6),(.10,2.3,.10),'metal')
        m.solid((x,1.15,-.6),(.14,2.3,.14))
    m.box('Roof',(0,2.32,0),(3.5,.15,1.9),'ink')
    m.box('RoofLight',(0,2.22,.88),(3.3,.035,.05),'cyan',True)
    m.box('Back',(0,1.4,-.65),(3.1,1.3,.05),'teal')
    m.box('Bench',(0,.52,-.20),(2.5,.12,.55),'wood')
    for x in [-.95,.95]:
        m.box(f'Leg{x}',(x,.25,-.20),(.12,.5,.35),'metal')
    m.solid((0,.4,-.25),(2.5,.8,.55))
    m.solid((0,1.4,-.65),(3.1,1.3,.08))
    m.box('RouteBoard',(.7,1.5,-.60),(.75,.9,.03),'ink')
    for i in range(4):
        m.box(f'Route{i}',(.7,1.78-i*.17,-.57),(.55,.03,.015),'cyan',True)
        m.box(f'Stop{i}',(.5,1.78-i*.17,-.55),(.07,.07,.02),'amber',True)
    m.box('Screen',(-.8,1.64,-.59),(.6,.28,.04),'cyan',True)
    m.text('CITY / LINK',(0,2.34,.97),30)
    return m


def repair():
    m=Model('repair_bench','repair')
    m.box('Table',(0,.83,0),(1.8,.13,.85),'wood')
    for x in [-.73,.73]:
        m.box(f'Leg{x}',(x,.4,0),(.12,.8,.65),'metal')
    m.box('PartsTray',(.45,.96,0),(.6,.12,.5),'ink')
    for i in range(4):
        m.box(f'Part{i}',(.22+i*.14,1.05,.04),(.09,.10,.18),['cyan','amber'][i%2])
    m.box('Laptop',(-.45,1.16,-.15),(.55,.48,.05),'ink')
    m.box('Screen',(-.45,1.16,-.11),(.45,.35,.02),'cyan',True)
    m.box('Keyboard',(-.45,.94,.1),(.55,.05,.3),'metal')
    m.node('Arm',(.7,.92,-.28))
    m.box('Upright',(0,.22,0),(.11,.44,.11),'amber',parent='Arm')
    m.box('ToolArm',(-.18,.43,0),(.46,.10,.10),'amber',parent='Arm')
    m.box('Tool',(-.39,.34,0),(.07,.16,.07),'cyan',True,parent='Arm')
    m.solid((0,.43,0),(1.8,.86,.85))
    return m


def cargo():
    m=Model('cargo_stack')
    for i in range(5):
        m.box(f'Pallet{i}',(-.56+i*.28,.10,0),(.20,.16,1.3),'wood')
    for i,(x,y,z) in enumerate([(-.35,.53,0),(.35,.53,0),(-.35,1.2,0)]):
        m.box(f'Crate{i}',(x,y,z),(.64,.65,.84),['teal','amber','red'][i])
        for dx in [-.23,.23]:
            m.box(f'Strap{i}{dx}',(x+dx,y,.43),(.045,.65,.02),'ink')
        m.box(f'Label{i}',(x,y,.445),(.25,.16,.025),'cream')
    m.solid((0,.55,0),(1.4,1.1,1.3))
    return m


def utility():
    m=Model('utility_cabinet','screen')
    m.box('Plinth',(0,.12,0),(1.4,.24,.75),'edge')
    m.box('Cabinet',(0,.91,0),(1.2,1.45,.65),'blue')
    m.box('Door',(-.1,.92,.34),(.85,1.25,.025),'metal')
    for i in range(6):
        m.box(f'Vent{i}',(-.1,.55+i*.1,.36),(.55,.035,.02),'black')
    m.box('Screen',(.4,1.35,.35),(.12,.16,.03),'green',True)
    m.box('Hazard',(-.1,1.34,.37),(.25,.19,.02),'amber')
    m.text('!',(-.1,1.34,.39),38)
    for x in [-.5,.5]:
        m.box(f'Pipe{x}',(x,.22,.52),(.10,.38,.14),'ink')
    m.solid((0,.85,0),(1.4,1.7,.75))
    return m


def aircon():
    m=Model('rooftop_aircon','fan')
    m.box('Body',(0,.48,0),(1.6,.8,.95),'edge')
    for x in [-.6,.6]:
        m.box(f'Foot{x}',(x,.08,0),(.14,.16,1.1),'ink')
    m.box('FanWell',(-.30,.49,.49),(.72,.65,.035),'black')
    m.node('Fan',(-.30,.49,.52))
    m.box('BladeH',(0,0,0),(.58,.08,.025),'metal',parent='Fan')
    m.box('BladeV',(0,0,0),(.08,.58,.025),'metal',parent='Fan')
    m.box('Hub',(0,0,.02),(.14,.14,.04),'ink',parent='Fan')
    for i in range(5):
        m.box(f'Vent{i}',(.5,.25+i*.11,.49),(.35,.035,.02),'black')
    m.box('TopStripe',(0,.9,0),(1.65,.05,1),'metal')
    m.box('Duct',(.98,.4,-.2),(.4,.4,.4),'metal')
    m.solid((0,.45,0),(1.6,.9,.95))
    return m

if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    models = [f() for f in (vending,noodle,arcade,shelter,repair,cargo,utility,aircon)]
    for model in models:
        model.save()
    print(f'Generated {len(models)} editable prop scenes in {OUT.relative_to(ROOT)}')
