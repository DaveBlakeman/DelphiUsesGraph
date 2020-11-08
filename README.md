# DelphiUsesGraph

A small, VERY fast micro parser to analyse very large Delphi projects (it can cope with million line projects and thousands of modules with ease). Provides an export to Gephi for graph analysis of unit dependencies.

## What it does

DelphiUsesGraph allows the user to configure a small project file containing a main .pas file, and a list of library paths to other .pas source files. 

When 'Analyse' is clicked, the parser does the following:-

- The parser acquires a list of all the delphi files it can find in the specified directories, and their subdirectories
- It then scans the files, from the root file down, and extracts interface and implementations uses, plus interface procedure/function names
- An analysis of the parse graph is conducted, and statistics are gathered
- These statistics are shown in a grid on the Statistics tab. Each row of the grid contains details for one unit analysed. Details include:-
  - Unit name
  - Number of units used from the interface
  - Number of units used from the implementation
  - Number of units referencing this unit from their interface
  - Number of units referencing this unit from their implementation
  - Number of lines of code in the unit
  - Number of routines in the unit's interface
  - Whether the unit has or depends on cylic uses structures
- Clicking on any cell will give a breakdonw in the list view below
- The GEXF tab creates an XML graph structure of your project in a format tha Gephi can import. Gephi is an open source graph anlyser, which may help you make sense of the structure of your project. 
  
## What it doesn't do

DelphiUsesGraph is NOT a compiler. It should only be used on successfuly compiled projects:-
- It won't check for syntactic errors
- It won't check types, method signatures, inheritance or anything else involving processor time
- It won't generate code

The parser is VERY resilient to errors, and in the event of almost any error it will simply continue. 

## Operating instructions

- Launch the program
- Select your root .pas file (typically the main form for a VCL project)
- Specify a list of directories to search (each is searched recursiively, so this is usually very easy)
- If you wish, save your project file for later use
- Click 'Analyse'. You should get results in a few seconds
- Explore your project from the statistics tab
- If you wish, copy the GEXF XML and import into Gephi.

## Building instructions

This has been build for Delphi 10.2.3. It uses DUnitxX, and it should build without issue. Note that I had and older library reference to an earlier external DUnitX build which I had to remove, so check for this if you encouter build errors when building tests.

Enjoy!
