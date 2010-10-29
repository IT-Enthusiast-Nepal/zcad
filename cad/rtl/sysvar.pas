unit sysvar;
interface
uses System;
var
  DWG_DrawMode:GDBInteger;
  DWG_OSMode:GDBInteger;
  DWG_PolarMode:GDBInteger;
  DWG_CLayer:GDBInteger;
  DWG_CLinew:GDBInteger;
  DWG_SystmGeometryDraw:GDBBoolean;
  DWG_HelpGeometryDraw:GDBBoolean;
  DWG_MaxGrid:GDBInteger;
  DWG_StepGrid:GDBDouble;
  DWG_DrawGrid:GDBBoolean;
  DWG_EditInSubEntry:GDBBoolean;
  DWG_SelectedObjToInsp:GDBBoolean;
  DSGN_TraceAutoInc:GDBBoolean;
  VIEW_CommandLineVisible:GDBBoolean;
  VIEW_HistoryLineVisible:GDBBoolean;
  VIEW_ObjInspVisible:GDBBoolean;
  PMenuProjType:GDBPointer;
  PMenuCommandLine:GDBPointer;
  PMenuHistoryLine:GDBPointer;
  PMenuStatusPanel:GDBPointer;
  PMenuDebugObjInsp:GDBPointer;
  StatusPanelVisible:GDBBoolean;
  DISP_ZoomFactor:GDBDouble;
  DISP_CursorSize:GDBInteger;
  DISP_OSSize:GDBDouble;
  DISP_DrawZAxis:GDBBoolean;
  DISP_ColorAxis:GDBBoolean;
  RD_PanObjectDegradation:GDBBoolean;
  RD_LineSmooth:GDBBoolean;
  RD_MaxLineWidth:GDBDouble;
  RD_MaxPointSize:GDBDouble;
  RD_Vendor:GDBString;
  RD_Renderer:GDBString;
  RD_Version:GDBString;
  RD_MaxWidth:GDBInteger;
  RD_BackGroundColor:RGB;
  RD_Restore_Mode:TRestoreMode;
  RD_LastRenderTime:GDBInteger;
  RD_LastUpdateTime:GDBInteger;
  RD_MaxRenderTime:GDBInteger;
  SAVE_Auto_Interval:GDBInteger;
  SAVE_Auto_Current_Interval:GDBInteger;
  SAVE_Auto_FileName:GDBString;
  SAVE_Auto_On:GDBBoolean;
  SYS_RunTime:GDBInteger;
  SYS_Version:GDBString;
  SYS_SystmGeometryColor:GDBInteger;
  SYS_IsHistoryLineCreated:GDBBoolean;
  SYS_AlternateFont:GDBString;
  PATH_Device_Library:GDBString;
  PATH_Template_Path:GDBString;
  PATH_Template_File:GDBString;
  PATH_Program_Run:GDBString;
  PATH_Support_Path:GDBString;
  PATH_Fonts:GDBString;
  ShowHiddenFieldInObjInsp:GDBBoolean;
  testGDBBoolean:GDBBoolean;
  pi:GDBDouble;
implementation
begin
  DWG_DrawMode:=0;
  DWG_OSMode:=6119;
  DWG_PolarMode:=1;
  DWG_CLayer:=0;
  DWG_CLinew:=-1;
  DWG_SystmGeometryDraw:=False;
  DWG_HelpGeometryDraw:=True;
  DWG_MaxGrid:=99;
  DWG_StepGrid:=0.0;
  DWG_DrawGrid:=False;
  DWG_EditInSubEntry:=False;
  DWG_SelectedObjToInsp:=True;
  DSGN_TraceAutoInc:=False;
  VIEW_CommandLineVisible:=True;
  VIEW_HistoryLineVisible:=True;
  VIEW_ObjInspVisible:=True;
  PMenuProjType:=nil;
  PMenuCommandLine:=nil;
  PMenuHistoryLine:=nil;
  PMenuStatusPanel:=nil;
  PMenuDebugObjInsp:=nil;
  StatusPanelVisible:=False;
  DISP_ZoomFactor:=1.624;
  DISP_CursorSize:=6;
  DISP_OSSize:=10.0;
  DISP_DrawZAxis:=False;
  DISP_ColorAxis:=False;
  RD_PanObjectDegradation:=False;
  RD_LineSmooth:=False;
  RD_MaxLineWidth:=-1.0;
  RD_MaxPointSize:=-1.0;
  RD_Vendor:='контекст OpenGL не создан';
  RD_Renderer:='контекст OpenGL не создан';
  RD_Version:='контекст OpenGL не создан';
  RD_MaxWidth:=-1;
  RD_BackGroundColor.r:=0;
  RD_BackGroundColor.g:=0;
  RD_BackGroundColor.b:=0;
  RD_BackGroundColor.a:=255;
  RD_Restore_Mode:=WND_Texture;
  RD_LastRenderTime:=0;
  RD_LastUpdateTime:=0;
  RD_MaxRenderTime:=0;
  SAVE_Auto_Interval:=300;
  SAVE_Auto_Current_Interval:=298;
  SAVE_Auto_FileName:='*autosave/autosave.dxf';
  SAVE_Auto_On:=True;
  SYS_RunTime:=2;
  SYS_Version:='0.9.7 SVN:9';
  SYS_SystmGeometryColor:=250;
  SYS_IsHistoryLineCreated:=True;
  SYS_AlternateFont:='GEWIND.SHX';
  PATH_Device_Library:='*programdb|c:/zcad/userdb';
  PATH_Program_Run:='C:\zcad\cad\';
  PATH_Support_Path:='*rtl|*rtl/objdefunits|*rtl/objdefunits/include|*components|*blocks/el/general';
  PATH_Fonts:='*fonts/|C:/Program Files/AutoCAD 2010/Fonts/';
  PATH_Template_Path:='*template';
  PATH_Template_File:='default.dxf';
  ShowHiddenFieldInObjInsp:=True;
  testGDBBoolean:=False;
  pi:=3.14159265359;
end.