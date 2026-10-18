"""Pin the shared OFL Manrope source for consistent native text weights."""
from pathlib import Path
from shutil import copyfile
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

root = Path(__file__).resolve().parents[3]
source = root / 'frontend/public/assets/workspace-fonts'
target = Path(__file__).resolve().parents[1] / 'assets/fonts'
for weight in (400, 500, 600, 700):
    font = instantiateVariableFont(TTFont(source / 'Manrope-Variable.ttf'), {'wght': weight}, inplace=True)
    font.save(target / f'Manrope-{weight}.ttf')
copyfile(source / 'OFL.txt', target / 'Manrope-OFL.txt')
print('Prepared four local Manrope print weights.')
