"""Pin the bundled OFL Manrope font for consistent offline Canvas rendering."""
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

root = Path(__file__).resolve().parent
source = root.parent / 'public/assets/workspace-fonts/Manrope-Variable.ttf'
for weight in (400, 700):
    font = instantiateVariableFont(TTFont(source), {'wght': weight}, inplace=True)
    # Separate aliases avoid platform-specific variable-font axis selection.
    family = f'AutoLinky Document {weight}'
    for record in font['name'].names:
        if record.nameID in (1, 4, 6, 16):
            name = family.replace(' ', '') if record.nameID == 6 else family
            record.string = name.encode(record.getEncoding())
    font.save(root / f'assets/Manrope-Print-{weight}.ttf')
    print(f'Prepared document font {weight}')
