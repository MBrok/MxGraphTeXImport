# MxGraphTeXImport
Library to render diagrams in MxGraph XML format to TeX documents using LuaLaTex and TikZ.

# Current Version 
0.0.1

# Description
This Library is intended to import MxGraph diagrams (i.e. generated from DrawIO (https://www.drawio.com/)) into LaTeX documents preserving fonts and scaling. It is written in Lua and needs LuaTeX (https://www.luatex.org/) to be compiled.

This Library is in pre-alpha state and currently can only import class diagrams and sequence diagrams. Since it translates mxCell vertices and edges to TikZ nodes and edges it should be possible to render other mxGraph diagrams as well but the output will not be very pretty.

# Requirements
## Lua Dependencies
- LuaLaTex (https://www.luatex.org/)
- Xml2Lua (https://github.com/manoelcampos/xml2lua)

## LaTeX dependencies
- TikZ (https://tikz.dev/)
    - TikZ library "shapes"
    - TikZ library "shapes.multipart"    
    - TikZ library "positioning"
- luapackageloader https://ctan.org/pkg/luapackageloader?lang=de

# Usage
- Put the Module on your (Lua)LaTeX Path.
- Provide the xml2lua package (https://github.com/manoelcampos/xml2lua) either by putting it into the subfolder "xml2lua" in the mxGraphImport folder of this implementation or by providing it to Lua's package lookup path on your system.
- Import the package to your TeX document:  
    ```
    \usepackage{mxGraphImport}
- Now you can add diagrams using the control sequences
    ```
    \drawClassDiagram{"<filename>"}
    \drawSequenceDiagram{"<filename>"}
    ````
    Where <filename> is the xml file containing the mxGraph diagram you want to import into your TeX document. Note that the xml in the xml file may not be compressed.





