{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
*  for details about the copyright.                                         *
*                                                                           *
*  This program is distributed in the hope that it will be useful,          *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
*                                                                           *
*****************************************************************************
}
{
@author(Andrey Zubarev <zamtmn@yandex.ru>) 
}

unit uzccombase;
{$INCLUDE def.inc}

interface
uses
 {$IFDEF DEBUGBUILD}strutils,{$ENDIF}
 uzcsysparams,zeundostack,zcchangeundocommand,uzcoimultiobjects,
 uzcenitiesvariablesextender,uzgldrawcontext,uzcdrawing,uzbpaths,uzeffmanager,
 uzeentdimension,uzestylesdim,uzestylestexts,uzeenttext,uzestyleslinetypes,
 URecordDescriptor,uzefontmanager,uzedrawingsimple,uzcsysvars,uzccommandsmanager,
 TypeDescriptors,uzcutils,uzcstrconsts,uzcctrlcontextmenu,{$IFNDEF DELPHI}uzctranslations,{$ENDIF}
 uzbstrproc,uzctreenode,menus, {$IFDEF FPC}lcltype,{$ENDIF}
 LCLProc,Classes,LazUTF8,Forms,Controls,Clipbrd,lclintf,
  uzcsysinfo,
  uzccommandsabstract,
  uzccommandsimpl,
  uzbtypes,
  uzcdrawings,
  sysutils,
  varmandef,
  uzglviewareadata,
  UGDBOpenArrayOfByte,
  uzeffdxf,
  uzcinterface,
  uzeconsts,
  uzeentity,
 uzeentitiestree,
 uzbtypesbase,uzbmemman,uzcdialogsfiles,
 UUnitManager,uzclog,Varman,
 uzbgeomtypes,dialogs,uzcinfoform,
 uzeentpolyline,UGDBPolyLine2DArray,uzeentlwpolyline,UGDBSelectedObjArray,
 gzctnrvectortypes,uzegeometry,uzelongprocesssupport,usimplegenerics,gzctnrstl,
 uzccommand_selectframe;
resourcestring
  rsBeforeRunPoly='Before starting you must select a 2DPolyLine';
var
       InfoFormVar:TInfoForm=nil;

       MSelectCXMenu:TPopupMenu=nil;

implementation

function GetOnMouseObjWAddr(var ContextMenu:TPopupMenu):GDBInteger;
var
  pp:PGDBObjEntity;
  ir:itrec;
  //inr:TINRect;
  line,saddr:GDBString;
  pvd:pvardesk;
  pentvarext:PTVariablesExtender;
begin
     result:=0;
     pp:=drawings.GetCurrentDWG.OnMouseObj.beginiterate(ir);
     if pp<>nil then
                    begin
                         repeat
                         pentvarext:=pp^.GetExtension(typeof(TVariablesExtender));
                         if pentvarext<>nil then
                         begin
                         pvd:=pentvarext^.entityunit.FindVariable('NMO_Name');
                         if pvd<>nil then
                                         begin
                                         if Result=20 then
                                         begin
                                              //result:=result+#13#10+'...';
                                              exit;
                                         end;
                                         line:=pp^.GetObjName+' Layer='+pp^.vp.Layer.GetFullName;
                                         line:=line+' Name='+pvd.data.PTD.GetValueAsString(pvd.data.Instance);
                                         system.str(GDBPlatformUInt(pp),saddr);
                                         ContextMenu.Items.Add(TmyMenuItem.create(ContextMenu,line,'SelectObjectByAddres('+saddr+')'));
                                         //if result='' then
                                         //                 result:=line
                                         //             else
                                         //                 result:=result+#13#10+line;
                                         inc(Result);
                                         end;
                         end;
                               pp:=drawings.GetCurrentDWG.OnMouseObj.iterate(ir);
                         until pp=nil;
                    end;
end;
function SelectOnMouseObjects_com(operands:TCommandOperands):TCommandResult;
begin
     cxmenumgr.closecurrentmenu;
     MSelectCXMenu:=TPopupMenu.create(nil);
     if GetOnMouseObjWAddr(MSelectCXMenu)=0 then
                                                         FreeAndNil(MSelectCXMenu)
                                                     else
                                                         cxmenumgr.PopUpMenu(MSelectCXMenu);
     result:=cmd_ok;
end;
function SelectObjectByAddres_com(operands:TCommandOperands):TCommandResult;
var
  pp:PGDBObjEntity;
  code:integer;
begin
  val(Operands,GDBPlatformUInt(pp),code);
  if (code=0)and(assigned(pp))then
    zcSelectEntity(pp);
  ZCMsgCallBackInterface.Do_GUIaction(nil,ZMsgID_GUIActionRedraw);
  ZCMsgCallBackInterface.Do_GUIaction(drawings.CurrentDWG.wa,ZMsgID_GUIActionSelectionChanged);
  result:=cmd_ok;
end;

function ChangeProjType_com(operands:TCommandOperands):TCommandResult;
begin
  if drawings.GetCurrentDWG.wa.param.projtype = projparalel then
  begin
    drawings.GetCurrentDWG.wa.param.projtype := projperspective;
  end
  else
    if drawings.GetCurrentDWG.wa.param.projtype = projPerspective then
    begin
    drawings.GetCurrentDWG.wa.param.projtype := projparalel;
    end;
  zcRedrawCurrentDrawing;
  result:=cmd_ok;
end;
function SelObjChangeLTypeToCurrent_com(operands:TCommandOperands):TCommandResult;
var pv:pGDBObjEntity;
    psv:PSelectedObjDesc;
    plt:PGDBLtypeProp;
    ir:itrec;
    DC:TDrawContext;
begin
  if (drawings.GetCurrentROOT.ObjArray.count = 0)or(drawings.GetCurrentDWG.wa.param.seldesc.Selectedobjcount=0) then exit;
  plt:={drawings.GetCurrentDWG.LTypeStyleTable.getDataMutable}(SysVar.dwg.DWG_CLType^);
  if plt=nil then
                 exit;
  dc:=drawings.GetCurrentDWG^.CreateDrawingRC;
  pv:=drawings.GetCurrentROOT.ObjArray.beginiterate(ir);
  if pv<>nil then
  repeat
    if pv^.Selected then
                        begin
                             pv^.vp.LineType:=plt;
                             pv^.Formatentity(drawings.GetCurrentDWG^,dc);
                        end;
  pv:=drawings.GetCurrentROOT.ObjArray.iterate(ir);
  until pv=nil;
  psv:=drawings.GetCurrentDWG.SelObjArray.beginiterate(ir);
  if psv<>nil then
  begin
       repeat
             if psv.objaddr^.Selected then
                                          begin
                                               psv.objaddr^.vp.LineType:=plt;
                                               psv.objaddr^.Formatentity(drawings.GetCurrentDWG^,dc);
                                          end;
       psv:=drawings.GetCurrentDWG.SelObjArray.iterate(ir);
       until psv=nil;
  end;
  zcRedrawCurrentDrawing;
  result:=cmd_ok;
end;
function SelObjChangeTStyleToCurrent_com(operands:TCommandOperands):TCommandResult;
var pv:PGDBObjText;
    psv:PSelectedObjDesc;
    prs:PGDBTextStyle;
    ir:itrec;
    DC:TDrawContext;
begin
  if (drawings.GetCurrentROOT.ObjArray.count = 0)or(drawings.GetCurrentDWG.wa.param.seldesc.Selectedobjcount=0) then exit;
  prs:=(SysVar.dwg.DWG_CTStyle^);
  if prs=nil then
                 exit;
  dc:=drawings.GetCurrentDWG^.CreateDrawingRC;
  pv:=drawings.GetCurrentROOT.ObjArray.beginiterate(ir);
  if pv<>nil then
  repeat
    if pv^.Selected then
    if (pv^.GetObjType=GDBMTextID)or(pv^.GetObjType=GDBTextID) then
                        begin
                             pv^.TXTStyleIndex:=prs;
                             pv^.Formatentity(drawings.GetCurrentDWG^,dc);
                        end;
  pv:=drawings.GetCurrentROOT.ObjArray.iterate(ir);
  until pv=nil;
  psv:=drawings.GetCurrentDWG.SelObjArray.beginiterate(ir);
  if psv<>nil then
  begin
       repeat
             if psv.objaddr^.Selected then
             if (psv.objaddr^.GetObjType=GDBMTextID)or(psv.objaddr^.GetObjType=GDBTextID) then
                                          begin
                                               PGDBObjText(psv.objaddr)^.TXTStyleIndex:=prs;
                                               psv.objaddr^.Formatentity(drawings.GetCurrentDWG^,dc);
                                          end;
       psv:=drawings.GetCurrentDWG.SelObjArray.iterate(ir);
       until psv=nil;
  end;
  zcRedrawCurrentDrawing;
  result:=cmd_ok;
end;
function SelObjChangeDimStyleToCurrent_com(operands:TCommandOperands):TCommandResult;
var pv:PGDBObjDimension;
    psv:PSelectedObjDesc;
    prs:PGDBDimStyle;
    ir:itrec;
    DC:TDrawContext;
begin
  if (drawings.GetCurrentROOT.ObjArray.count = 0)or(drawings.GetCurrentDWG.wa.param.seldesc.Selectedobjcount=0) then exit;
  prs:=(SysVar.dwg.DWG_CDimStyle^);
  if prs=nil then
                 exit;
  dc:=drawings.GetCurrentDWG^.CreateDrawingRC;
  pv:=drawings.GetCurrentROOT.ObjArray.beginiterate(ir);
  if pv<>nil then
  repeat
    if pv^.Selected then
    if (pv^.GetObjType=GDBAlignedDimensionID)or(pv^.GetObjType=GDBRotatedDimensionID)or(pv^.GetObjType=GDBDiametricDimensionID) then
                        begin
                             pv^.PDimStyle:=prs;
                             pv^.Formatentity(drawings.GetCurrentDWG^,dc);
                        end;
  pv:=drawings.GetCurrentROOT.ObjArray.iterate(ir);
  until pv=nil;
  psv:=drawings.GetCurrentDWG.SelObjArray.beginiterate(ir);
  if psv<>nil then
  begin
       repeat
             if psv.objaddr^.Selected then
             if (psv.objaddr^.GetObjType=GDBAlignedDimensionID)or(psv.objaddr^.GetObjType=GDBRotatedDimensionID)or(psv.objaddr^.GetObjType=GDBDiametricDimensionID) then
                                          begin
                                               PGDBObjDimension(psv.objaddr)^.PDimStyle:=prs;
                                               psv.objaddr^.Formatentity(drawings.GetCurrentDWG^,dc);
                                          end;
       psv:=drawings.GetCurrentDWG.SelObjArray.iterate(ir);
       until psv=nil;
  end;
  zcRedrawCurrentDrawing;
  result:=cmd_ok;
end;
function SelObjChangeLayerToCurrent_com(operands:TCommandOperands):TCommandResult;
var pv:pGDBObjEntity;
    psv:PSelectedObjDesc;
    ir:itrec;
    DC:TDrawContext;
begin
  if (drawings.GetCurrentROOT.ObjArray.count = 0)or(drawings.GetCurrentDWG.wa.param.seldesc.Selectedobjcount=0) then exit;
  dc:=drawings.GetCurrentDWG^.CreateDrawingRC;
  pv:=drawings.GetCurrentROOT.ObjArray.beginiterate(ir);
  if pv<>nil then
  repeat
    if pv^.Selected then
                        begin
                             pv^.vp.Layer:=drawings.GetCurrentDWG.GetCurrentLayer;
                             pv^.Formatentity(drawings.GetCurrentDWG^,dc);
                        end;
  pv:=drawings.GetCurrentROOT.ObjArray.iterate(ir);
  until pv=nil;
  psv:=drawings.GetCurrentDWG.SelObjArray.beginiterate(ir);
  if psv<>nil then
  begin
       repeat
             if psv.objaddr^.Selected then
                                          begin
                                               psv.objaddr^.vp.Layer:=drawings.GetCurrentDWG.GetCurrentLayer;
                                               psv.objaddr^.Formatentity(drawings.GetCurrentDWG^,dc);
                                          end;
       psv:=drawings.GetCurrentDWG.SelObjArray.iterate(ir);
       until psv=nil;
  end;
  zcRedrawCurrentDrawing;
  result:=cmd_ok;
end;
function SelObjChangeColorToCurrent_com(operands:TCommandOperands):TCommandResult;
var pv:pGDBObjEntity;
    ir:itrec;
begin
  if (drawings.GetCurrentROOT.ObjArray.count = 0)or(drawings.GetCurrentDWG.wa.param.seldesc.Selectedobjcount=0) then exit;
  pv:=drawings.GetCurrentROOT.ObjArray.beginiterate(ir);
  if pv<>nil then
  repeat
    if pv^.Selected then pv^.vp.color:=sysvar.dwg.DWG_CColor^ ;
  pv:=drawings.GetCurrentROOT.ObjArray.iterate(ir);
  until pv=nil;
  zcRedrawCurrentDrawing;
  result:=cmd_ok;
end;

function SelObjChangeLWToCurrent_com(operands:TCommandOperands):TCommandResult;
var pv:pGDBObjEntity;
    ir:itrec;
begin
  if (drawings.GetCurrentROOT.ObjArray.count = 0)or(drawings.GetCurrentDWG.wa.param.seldesc.Selectedobjcount=0) then exit;
  pv:=drawings.GetCurrentROOT.ObjArray.beginiterate(ir);
  if pv<>nil then
  repeat
    if pv^.Selected then pv^.vp.LineWeight:=sysvar.dwg.DWG_CLinew^ ;
  pv:=drawings.GetCurrentROOT.ObjArray.iterate(ir);
  until pv=nil;
  zcRedrawCurrentDrawing;
  result:=cmd_ok;
end;
procedure createInfoFormVar;
begin
  if not assigned(InfoFormVar) then
  begin
  InfoFormVar:=TInfoForm.create(application.MainForm);
  InfoFormVar.DialogPanel.HelpButton.Hide;
  InfoFormVar.DialogPanel.CancelButton.Hide;
  InfoFormVar.caption:=(rsCAUTIONnoSyntaxCheckYet);
  end;
end;
function EditUnit(var entityunit:TSimpleUnit):boolean;
var
   mem:GDBOpenArrayOfByte;
   //pobj:PGDBObjEntity;
   //op:gdbstring;
   modalresult:integer;
   u8s:UTF8String;
   astring:ansistring;
begin
     mem.init({$IFDEF DEBUGBUILD}'{A1891083-67C6-4C21-8012-6D215935F6A6}',{$ENDIF}1024);
     entityunit.SaveToMem(mem);
     //mem.SaveToFile(expandpath(ProgramPath+'autosave\lastvariableset.pas'));
     setlength(astring,mem.Count);
     StrLCopy(@astring[1],mem.GetParrayAsPointer,mem.Count);
     u8s:=(astring);

     createInfoFormVar;

     InfoFormVar.memo.text:=u8s;
     modalresult:=ZCMsgCallBackInterface.DOShowModal(InfoFormVar);
     if modalresult=MrOk then
                         begin
                               u8s:=InfoFormVar.memo.text;
                               astring:={utf8tosys}(u8s);
                               mem.Clear;
                               mem.AddData(@astring[1],length(astring));

                               entityunit.free;
                               units.parseunit(SupportPath,InterfaceTranslate,mem,@entityunit);
                               result:=true;
                         end
                         else
                             result:=false;
     mem.done;
end;

function ObjVarMan_com(operands:TCommandOperands):TCommandResult;
var
   pobj:PGDBObjEntity;
   //op:gdbstring;
   pentvarext:PTVariablesExtender;
begin
  if drawings.GetCurrentDWG.wa.param.SelDesc.Selectedobjcount=1 then
                                                               pobj:=PGDBObjEntity(drawings.GetCurrentDWG.GetLastSelected)
                                                           else
                                                               pobj:=nil;
  if pobj<>nil
  then
      begin
           pentvarext:=pobj^.GetExtension(typeof(TVariablesExtender));
           if pentvarext<>nil then
           begin
            if EditUnit(pentvarext^.entityunit) then
              ZCMsgCallBackInterface.Do_GUIaction(nil,ZMsgID_GUIRePrepareObject);
           end;
      end
  else
      ZCMsgCallBackInterface.TextMessage(rscmSelEntBeforeComm,TMWOHistoryOut);
  result:=cmd_ok;
end;
function BlockDefVarMan_com(operands:TCommandOperands):TCommandResult;
var
   pobj:PGDBObjEntity;
   op:gdbstring;
   pentvarext:PTVariablesExtender;
begin
     pobj:=nil;
     if drawings.GetCurrentDWG.wa.param.SelDesc.Selectedobjcount=1 then
                                                                  begin
                                                                       op:=PGDBObjEntity(drawings.GetCurrentDWG.GetLastSelected)^.GetNameInBlockTable;
                                                                       if op<>'' then
                                                                                     pobj:=drawings.GetCurrentDWG.BlockDefArray.getblockdef(op)
                                                                  end
else if length(Operands)>0 then
                               begin
                                  op:=Operands;
                                  pobj:=drawings.GetCurrentDWG.BlockDefArray.getblockdef(op)
                               end;
  if pobj<>nil
  then
      begin
           pentvarext:=pobj^.GetExtension(typeof(TVariablesExtender));
           if pentvarext<>nil then
           begin
            if EditUnit(pentvarext^.entityunit) then
              ZCMsgCallBackInterface.Do_GUIaction(nil,ZMsgID_GUIRePrepareObject);
           end;
      end
  else
      ZCMsgCallBackInterface.TextMessage(rscmSelOrSpecEntity,TMWOHistoryOut);
  result:=cmd_ok;
end;
function UnitsMan_com(operands:TCommandOperands):TCommandResult;
var
   PUnit:ptunit;
   //op:gdbstring;
   //pentvarext:PTVariablesExtender;
begin
    if length(Operands)>0 then
                               begin
                                  PUnit:=units.findunit(SupportPath,InterfaceTranslate,operands);
                                  if PUnit<>nil then
                                                    begin
                                                      EditUnit(PUnit^);
                                                    end
                                                 else
                                                    ZCMsgCallBackInterface.TextMessage('unit not found!',TMWOHistoryOut);
                               end
                          else
                              ZCMsgCallBackInterface.TextMessage('Specify unit name!',TMWOHistoryOut);
  result:=cmd_ok;
end;
function MultiObjVarMan_com(operands:TCommandOperands):TCommandResult;
var
   mem:GDBOpenArrayOfByte;
   pobj:PGDBObjEntity;
   modalresult:integer;
   u8s:UTF8String;
   astring:ansistring;
   counter:integer;
   ir:itrec;
   pentvarext:PTVariablesExtender;
begin
      begin
           mem.init({$IFDEF DEBUGBUILD}'{A1891083-67C6-4C21-8012-6D215935F6A6}',{$ENDIF}1024);

           createInfoFormVar;
           counter:=0;

           InfoFormVar.memo.text:='';
           modalresult:=ZCMsgCallBackInterface.DOShowModal(InfoFormVar);
           if modalresult=MrOk then
                               begin
                                     u8s:=InfoFormVar.memo.text;
                                     astring:={utf8tosys}(u8s);
                                     mem.Clear;
                                     mem.AddData(@astring[1],length(astring));

                                     pobj:=drawings.GetCurrentROOT.ObjArray.beginiterate(ir);
                                     if pobj<>nil then
                                     repeat
                                           if pobj^.Selected then
                                           begin
                                                pentvarext:=pobj^.GetExtension(typeof(TVariablesExtender));
                                                pentvarext^.entityunit.free;
                                                units.parseunit(SupportPath,InterfaceTranslate,mem,@pentvarext^.entityunit);
                                                mem.Seek(0);
                                                inc(counter);
                                           end;
                                           pobj:=drawings.GetCurrentROOT.ObjArray.iterate(ir);
                                     until pobj=nil;
                                     ZCMsgCallBackInterface.Do_GUIaction(nil,ZMsgID_GUIRePrepareObject);
                               end;


           //InfoFormVar.Free;
           mem.done;
           ZCMsgCallBackInterface.TextMessage(format(rscmNEntitiesProcessed,[inttostr(counter)]),TMWOHistoryOut);
      end;
    result:=cmd_ok;
end;

function RebuildTree_com(operands:TCommandOperands):TCommandResult;
var
   lpsh:TLPSHandle;
begin
  lpsh:=LPS.StartLongProcess(drawings.GetCurrentROOT.ObjArray.count,'Rebuild drawing spatial',nil);
  drawings.GetCurrentDWG^.pObjRoot.ObjArray.ObjTree.maketreefrom(drawings.GetCurrentDWG^.pObjRoot.ObjArray,drawings.GetCurrentDWG^.pObjRoot.vp.BoundingBox,nil);
  LPS.EndLongProcess(lpsh);
  drawings.GetCurrentDWG.wa.param.seldesc.Selectedobjcount:=0;
  drawings.GetCurrentDWG.wa.param.seldesc.OnMouseObject:=nil;
  drawings.GetCurrentDWG.wa.param.seldesc.LastSelectedObject:=nil;
  ZCMsgCallBackInterface.Do_GUIaction(nil,ZMsgID_GUIReturnToDefaultObject);
  clearcp;
  zcRedrawCurrentDrawing;
  result:=cmd_ok;
end;

procedure polytest_com_CommandStart(Operands:pansichar);
begin
  if drawings.GetCurrentDWG.GetLastSelected<>nil then
  if drawings.GetCurrentDWG.GetLastSelected.GetObjType=GDBlwPolylineID then
  begin
  drawings.GetCurrentDWG.wa.SetMouseMode((MGet3DPointWOOP) or (MMoveCamera) or (MRotateCamera) or (MGet3DPoint));
  //drawings.GetCurrentDWG.OGLwindow1.param.seldesc.MouseFrameON := true;
  ZCMsgCallBackInterface.TextMessage('Click and test inside/outside of a 2D polyline:',TMWOHistoryOut);
  exit;
  end;
  //else
  begin
       ZCMsgCallBackInterface.TextMessage('Before run 2DPolyline must be selected',TMWOHistoryOut);
       commandmanager.executecommandend;
  end;
end;
function polytest_com_BeforeClick(wc: GDBvertex; mc: GDBvertex2DI; var button: GDBByte;osp:pos_record;mclick:GDBInteger): GDBInteger;
//var tb:PGDBObjSubordinated;
begin
  result:=mclick+1;
  if (button and MZW_LBUTTON)<>0 then
  begin
       if pgdbobjlwpolyline(drawings.GetCurrentDWG.GetLastSelected).isPointInside(wc) then
       ZCMsgCallBackInterface.TextMessage('Inside!',TMWOHistoryOut)
       else
       ZCMsgCallBackInterface.TextMessage('Outside!',TMWOHistoryOut)
  end;
end;
function isrect(const p1,p2,p3,p4:GDBVertex2D):boolean;
//var
   //p:gdbdouble;
begin
     //p:=SqrVertexlength(p1,p3)-sqrVertexlength(p2,p4);
     //p:=SqrVertexlength(p1,p2)-sqrVertexlength(p3,p4);
     if (abs(SqrVertexlength(p1,p3)-sqrVertexlength(p2,p4))<sqreps)and(abs(SqrVertexlength(p1,p2)-sqrVertexlength(p3,p4))<sqreps)
     then
         result:=true
     else
         result:=false;
end;
function IsSubContur(const pva:GDBPolyline2DArray;const p1,p2,p3,p4:integer):boolean;
var
   c,i:integer;
begin
     result:=false;
     for i:=0 to pva.count-1 do
     begin
          if (i<>p1)and
             (i<>p2)and
             (i<>p3)and
             (i<>p4)
                       then
                       begin
                            c:=0;
                            if _intercept2d(PGDBVertex2D(pva.getDataMutable(p1))^,PGDBVertex2D(pva.getDataMutable(p2))^,PGDBVertex2D(pva.getDataMutable(i))^, 1, 0)
                            then
                                inc(c);
                            if _intercept2d(PGDBVertex2D(pva.getDataMutable(p2))^,PGDBVertex2D(pva.getDataMutable(p3))^,PGDBVertex2D(pva.getDataMutable(i))^, 1, 0)
                            then
                                inc(c);
                            if _intercept2d(PGDBVertex2D(pva.getDataMutable(p3))^,PGDBVertex2D(pva.getDataMutable(p4))^,PGDBVertex2D(pva.getDataMutable(i))^, 1, 0)
                            then
                                inc(c);
                            if _intercept2d(PGDBVertex2D(pva.getDataMutable(p4))^,PGDBVertex2D(pva.getDataMutable(p1))^,PGDBVertex2D(pva.getDataMutable(i))^, 1, 0)
                            then
                                inc(c);
                            if ((c mod 2)=1) then
                                                 exit;
                       end;
     end;
     result:=true;
end;
function IsSubContur2(const pva:GDBPolyline2DArray;const p1,p2,p3:integer;const p:GDBVertex2D):boolean;
var
   c,i:integer;
begin
     result:=false;
     for i:=0 to pva.count-1 do
     begin
          if (i<>p1)and
             (i<>p2)and
             (i<>p3)
                       then
                       begin
                            c:=0;
                            if _intercept2d(PGDBVertex2D(pva.getDataMutable(p1))^,PGDBVertex2D(pva.getDataMutable(p2))^,PGDBVertex2D(pva.getDataMutable(i))^, 1, 0)
                            then
                                inc(c);
                            if _intercept2d(PGDBVertex2D(pva.getDataMutable(p2))^,PGDBVertex2D(pva.getDataMutable(p3))^,PGDBVertex2D(pva.getDataMutable(i))^, 1, 0)
                            then
                                inc(c);
                            if _intercept2d(PGDBVertex2D(pva.getDataMutable(p3))^,p,PGDBVertex2D(pva.getDataMutable(i))^, 1, 0)
                            then
                                inc(c);
                            if _intercept2d(p,PGDBVertex2D(pva.getDataMutable(p1))^,PGDBVertex2D(pva.getDataMutable(i))^, 1, 0)
                            then
                                inc(c);
                            if ((c mod 2)=1) then
                                                 exit;
                       end;
     end;
     result:=true;
end;
procedure nextP(var p,c:integer);
begin
     inc(p);
     if p=c then
                        p:=0;
end;
function CutRect4(var pva,pvr:GDBPolyline2DArray):boolean;
var
   p1,p2,p3,p4,i:integer;
begin
     result:=false;
     p1:=0;p2:=1;p3:=2;p4:=3;
     for i:=1 to pva.count do
     begin
          if isrect(PGDBVertex2D(pva.getDataMutable(p1))^,
                    PGDBVertex2D(pva.getDataMutable(p2))^,
                    PGDBVertex2D(pva.getDataMutable(p3))^,
                    PGDBVertex2D(pva.getDataMutable(p4))^)then
          if pva.ispointinside(Vertexmorph(PGDBVertex2D(pva.getDataMutable(p1))^,PGDBVertex2D(pva.getDataMutable(p3))^,0.5))then
          if IsSubContur(pva,p1,p2,p3,p4)then
              begin
                   pvr.PushBackData(pva.getDataMutable(p1)^);
                   pvr.PushBackData(pva.getDataMutable(p2)^);
                   pvr.PushBackData(pva.getDataMutable(p3)^);
                   pvr.PushBackData(pva.getDataMutable(p4)^);

                   pva.deleteelement(p3);
                   pva.deleteelement(p2);
                   pva.optimize;

                   result:=true;
                   exit;
              end;
          nextP(p1,pva.count);nextP(p2,pva.count);nextP(p3,pva.count);nextP(p4,pva.count);
     end;
end;
function CutRect3(var pva,pvr:GDBPolyline2DArray):boolean;
var
   p1,p2,p3,p4,i:integer;
   p:GDBVertex2d;
begin
     result:=false;
     p1:=0;p2:=1;p3:=2;p4:=3;
     for i:=1 to pva.count do
     begin
          p.x:=PGDBVertex2D(pva.getDataMutable(p1))^.x+(PGDBVertex2D(pva.getDataMutable(p3))^.x-PGDBVertex2D(pva.getDataMutable(p2))^.x);
          p.y:=PGDBVertex2D(pva.getDataMutable(p1))^.y+(PGDBVertex2D(pva.getDataMutable(p3))^.y-PGDBVertex2D(pva.getDataMutable(p2))^.y);
          if distance2piece_2dmy(p,PGDBVertex2D(pva.getDataMutable(p3))^,PGDBVertex2D(pva.getDataMutable(p4))^)<eps then
          if pva.ispointinside(Vertexmorph(PGDBVertex2D(pva.getDataMutable(p1))^,PGDBVertex2D(pva.getDataMutable(p3))^,0.5))then
          if IsSubContur2(pva,p1,p2,p3,p)then
              begin
                   pvr.PushBackData(pva.getDataMutable(p1)^);
                   pvr.PushBackData(pva.getDataMutable(p2)^);
                   pvr.PushBackData(pva.getDataMutable(p3)^);
                   pvr.PushBackData(p);

                   PGDBVertex2D(pva.getDataMutable(p3))^.x:=p.x;
                   PGDBVertex2D(pva.getDataMutable(p3))^.y:=p.y;
                   pva.deleteelement(p2);
                   pva.optimize;

                   result:=true;
                   exit;
              end;
          nextP(p1,pva.count);nextP(p2,pva.count);nextP(p3,pva.count);nextP(p4,pva.count);
     end;
end;

procedure polydiv(var pva,pvr:GDBPolyline2DArray;m:DMatrix4D);
var
   nstep,i:integer;
   p3dpl:PGDBObjPolyline;
   wc:gdbvertex;
   DC:TDrawContext;
begin
     nstep:=0;
     pva.optimize;
     repeat
           case nstep of
                       0:begin
                              if CutRect4(pva,pvr) then
                                                       nstep:=-1;

                         end;
                       1:begin
                              if CutRect3(pva,pvr) then
                                                       nstep:=-1;
                         end;
                       {2:begin

                              if CutRect3(pva,pvr) then
                                                       nstep:=-1;
                         end}
           end;
           inc(nstep)
     until nstep=2;

     if pvr.Count>0 then
     begin
     p3dpl := GDBPointer(drawings.GetCurrentROOT.ObjArray.CreateInitObj(GDBPolylineID,drawings.GetCurrentROOT));
     p3dpl.Closed:=true;
     p3dpl^.vp.Layer :=drawings.GetCurrentDWG.GetCurrentLayer;
     p3dpl^.vp.lineweight := sysvar.dwg.DWG_CLinew^;
     dc:=drawings.GetCurrentDwg^.CreateDrawingRC;
     i:=0;
     while i<pvr.Count do
     begin
          wc.x:=PGDBVertex2D(pvr.getDataMutable(i))^.x;
          wc.y:=PGDBVertex2D(pvr.getDataMutable(i))^.y;
          wc.z:=0;
          wc:=uzegeometry.VectorTransform3D(wc,m);
          p3dpl^.AddVertex(wc);

          if ((i+1) mod 4)=0 then
          begin
               p3dpl^.Formatentity(drawings.GetCurrentDWG^,dc);
               p3dpl^.RenderFeedback(drawings.GetCurrentDWG.pcamera^.POSCOUNT,drawings.GetCurrentDWG.pcamera^,drawings.GetCurrentDWG^.myGluProject2,dc);
               zcAddEntToCurrentDrawingWithUndo(p3dpl);
               //drawings.GetCurrentROOT.ObjArray.ObjTree.CorrectNodeBoundingBox(p3dpl^);
               if i<>pvr.Count-1 then
               begin
               p3dpl := GDBPointer(drawings.GetCurrentROOT.ObjArray.CreateInitObj(GDBPolylineID,drawings.GetCurrentROOT));
               p3dpl.Closed:=true;
               end;
          end;
          inc(i);
     end;

     //p3dpl^.Formatentity(drawings.GetCurrentDWG^,dc);
     //p3dpl^.RenderFeedback(drawings.GetCurrentDWG.pcamera^.POSCOUNT,drawings.GetCurrentDWG.pcamera^,drawings.GetCurrentDWG^.myGluProject2,dc);
     //zcAddEntToCurrentDrawingWithUndo(p3dpl);
     end;
     //drawings.GetCurrentROOT.ObjArray.ObjTree.CorrectNodeBoundingBox(p3dpl^);
     //redrawoglwnd;
end;

procedure polydiv_com(Operands:pansichar);
var pva,pvr:GDBPolyline2DArray;
begin
  if drawings.GetCurrentDWG.GetLastSelected<>nil then
  if drawings.GetCurrentDWG.GetLastSelected.GetObjType=GDBlwPolylineID then
  begin
       pva.init({$IFDEF DEBUGBUILD}'{9372BADE-74EE-4101-8FA4-FC696054CD4F}',{$ENDIF}pgdbobjlwpolyline(drawings.GetCurrentDWG.GetLastSelected).Vertex2D_in_OCS_Array.count,true);
       pvr.init({$IFDEF DEBUGBUILD}'{9372BADE-74EE-4101-8FA4-FC696054CD4F}',{$ENDIF}pgdbobjlwpolyline(drawings.GetCurrentDWG.GetLastSelected).Vertex2D_in_OCS_Array.count,true);

       pgdbobjlwpolyline(drawings.GetCurrentDWG.GetLastSelected).Vertex2D_in_OCS_Array.copyto(pva);

       polydiv(pva,pvr,pgdbobjlwpolyline(drawings.GetCurrentDWG.GetLastSelected).GetMatrix^);

       pva.done;
       pvr.done;
       exit;
  end;
  //else
  begin
       ZCMsgCallBackInterface.TextMessage(rsBeforeRunPoly,TMWOHistoryOut);
       commandmanager.executecommandend;
  end;
end;

procedure finalize;
begin
     //Optionswindow.done;
     //Aboutwindow.{done}free;
     //Helpwindow.{done}free;

     //DWGPageCxMenu^.done;
     //gdbfreemem(pointer(DWGPageCxMenu));
end;
function SnapProp_com(operands:TCommandOperands):TCommandResult;
begin
  ZCMsgCallBackInterface.Do_PrepareObject(nil,drawings.GetUnitsFormat,dbunit.TypeName2PTD('TOSModeEditor'),@OSModeEditor,drawings.GetCurrentDWG,true);
  result:=cmd_ok;
end;
function StoreFrustum_com(operands:TCommandOperands):TCommandResult;
//var
   //p:PCommandObjectDef;
   //ps:pgdbstring;
   //ir:itrec;
   //clist:TZctnrVectorGDBString;
begin
   drawings.GetCurrentDWG.wa.param.debugfrustum:=drawings.GetCurrentDWG.pcamera.frustum;
   drawings.GetCurrentDWG.wa.param.ShowDebugFrustum:=true;
   result:=cmd_ok;
end;
(*function ScriptOnUses(Sender: TPSPascalCompiler; const Name: string): Boolean;
{ the OnUses callback function is called for each "uses" in the script.
  It's always called with the parameter 'SYSTEM' at the top of the script.
  For example: uses ii1, ii2;
  This will call this function 3 times. First with 'SYSTEM' then 'II1' and then 'II2'.
}
begin
  if Name = 'SYSTEM' then
  begin
    SIRegister_Std(Sender);
    { This will register the declarations of these classes:
      TObject, TPersisent. This can be found
      in the uPSC_std.pas unit. }
    SIRegister_Controls(Sender);
    { This will register the declarations of these classes:
      TControl, TWinControl, TFont, TStrings, TStringList, TGraphicControl. This can be found
      in the uPSC_controls.pas unit. }

    SIRegister_Forms(Sender);
    { This will register: TScrollingWinControl, TCustomForm, TForm and TApplication. uPSC_forms.pas unit. }

    SIRegister_stdctrls(Sender);
     { This will register: TButtonContol, TButton, TCustomCheckbox, TCheckBox, TCustomEdit, TEdit, TCustomMemo, TMemo,
      TCustomLabel and TLabel. Can be found in the uPSC_stdctrls.pas unit. }

    AddImportedClassVariable(Sender, 'Application', 'TApplication');
    // Registers the application variable to the script engine.
    {PGDBDouble=^GDBDouble;
    PGDBFloat=^GDBFloat;
    PGDBString=^GDBString;
    PGDBAnsiString=^GDBAnsiString;
    PGDBBoolean=^GDBBoolean;
    PGDBInteger=^GDBInteger;
    PGDBByte=^GDBByte;
    PGDBLongword=^GDBLongword;
    PGDBQWord=^GDBQWord;
    PGDBWord=^GDBWord;
    PGDBSmallint=^GDBSmallint;
    PGDBShortint=^GDBShortint;
    PGDBPointer=^GDBPointer;}
    Sender.AddType('GDBDouble',btDouble){: TPSType};
    Sender.AddType('GDBFloat',btSingle);
    Sender.AddType('GDBString',btString);
    Sender.AddType('GDBInteger',btS32);
    //Sender.AddType('GDBBoolean',btBoolean);

    sender.AddDelphiFunction('procedure test;');
    sender.AddDelphiFunction('procedure ShowError(errstr:GDBString);');

    Result := True;
  end else
    Result := False;
end;
*)

procedure startup;
//var
   //pmenuitem:pzmenuitem;
begin
  Randomize;
  CreateCommandFastObjectPlugin(@SelectOnMouseObjects_com,'SelectOnMouseObjects',CADWG,0);
  CreateCommandFastObjectPlugin(@SelectObjectByAddres_com,'SelectObjectByAddres',CADWG,0);

  CreateCommandFastObjectPlugin(@ObjVarMan_com,'ObjVarMan',CADWG or CASelEnt,0);
  CreateCommandFastObjectPlugin(@MultiObjVarMan_com,'MultiObjVarMan',CADWG or CASelEnts,0);
  CreateCommandFastObjectPlugin(@BlockDefVarMan_com,'BlockDefVarMan',CADWG,0);
  CreateCommandFastObjectPlugin(@BlockDefVarMan_com,'BlockDefVarMan',CADWG,0);
  CreateCommandFastObjectPlugin(@UnitsMan_com,'UnitsMan',0,0);
  CreateCommandFastObjectPlugin(@ChangeProjType_com,'ChangeProjType',CADWG,0);
  CreateCommandFastObjectPlugin(@SelObjChangeLayerToCurrent_com,'SelObjChangeLayerToCurrent',CADWG,0);
  CreateCommandFastObjectPlugin(@SelObjChangeLWToCurrent_com,'SelObjChangeLWToCurrent',CADWG,0);
  CreateCommandFastObjectPlugin(@SelObjChangeColorToCurrent_com,'SelObjChangeColorToCurrent',CADWG,0);
  CreateCommandFastObjectPlugin(@SelObjChangeLTypeToCurrent_com,'SelObjChangeLTypeToCurrent',CADWG,0);
  CreateCommandFastObjectPlugin(@SelObjChangeTStyleToCurrent_com,'SelObjChangeTStyleToCurrent',CADWG,0);
  CreateCommandFastObjectPlugin(@SelObjChangeDimStyleToCurrent_com,'SelObjChangeDimStyleToCurrent',CADWG,0);
  CreateCommandFastObjectPlugin(@RebuildTree_com,'RebuildTree',CADWG,0);

  CreateCommandRTEdObjectPlugin(@polytest_com_CommandStart,nil,nil,nil,@polytest_com_BeforeClick,@polytest_com_BeforeClick,nil,nil,'PolyTest',0,0);

  CreateCommandFastObjectPlugin(@PolyDiv_com,'PolyDiv',CADWG,0).CEndActionAttr:=CEDeSelect;

  CreateCommandFastObjectPlugin(@SnapProp_com,'SnapProperties',CADWG,0).overlay:=true;

  CreateCommandFastObjectPlugin(@StoreFrustum_com,'StoreFrustum',CADWG,0).overlay:=true;
end;
initialization
  OSModeEditor.initnul;
  OSModeEditor.trace.ZAxis:=false;
  OSModeEditor.trace.Angle:=TTA45;
  startup;
finalization
  debugln('{I}[UnitsFinalization] Unit "',{$INCLUDE %FILE%},'" finalization');
  finalize;
end.
