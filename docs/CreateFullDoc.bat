md FullDoc
pasdoc.exe --graphviz-uses --graphviz-classes --output FullDoc --auto-abstract --staronly --write-uses-list --source SourcesFullList.txt --include ..\cad_source;..\cad_source\autogenerated;..\cad_source\components\zebase;..\cad_source\other;..\cad_source\zengine\u\undostack
dottoxml.py FullDoc\GVClasses.dot FullClasses.graphml
dottoxml.py FullDoc\GVUses.dot FullUses.graphml

pause