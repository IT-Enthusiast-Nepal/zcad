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
{$MODE OBJFPC}
unit uzccommand_move;
{$INCLUDE zcadconfig.inc}

interface
uses
  gzctnrVector,zcmultiobjectchangeundocommand,
  gzctnrvectortypes,uzgldrawercanvas,
  uzcoimultiobjects,uzcdrawing,uzepalette,
  uzgldrawcontext,
  uzeentpoint,uzeentityfactory,
  uzedrawingsimple,uzcsysvars,uzcstrconsts,
  printers,graphics,uzeentdevice,
  LazUTF8,Clipbrd,LCLType,classes,uzeenttext,
  uzccommandsabstract,uzbstrproc,
  uzbtypesbase,uzccommandsmanager,
  uzccommandsimpl,
  uzcdrawings,
  uzeutils,
  sysutils,
  varmandef,
  uzglviewareadata,
  uzeffdxf,
  uzcinterface,
  uzegeometry,

  uzeconsts,
  uzegeometrytypes,uzeentity,uzeentcircle,uzeentline,uzeentgenericsubentry,uzeentmtext,
  uzeentblockinsert,uzeentpolyline,uzclog,
  uzeentlwpolyline,UBaseTypeDescriptor,uzeblockdef,Varman,URecordDescriptor,TypeDescriptors,UGDBVisibleTreeArray
  ,uzelongprocesssupport,LazLogger;
type
{EXPORT+}
  PTCopyObjectDesc=^TCopyObjectDesc;
  {REGISTERRECORDTYPE TCopyObjectDesc}
  TCopyObjectDesc=record
                 sourceEnt,tmpProxy,copyEnt:PGDBObjEntity;
                 end;
  ptpcoavector=^tpcoavector;
  tpcoavector={-}specialize{//}
              GZVector{-}<TCopyObjectDesc>{//};
  {REGISTEROBJECTTYPE move_com}
  move_com =  object(CommandRTEdObject)
    t3dp: gdbvertex;
    pcoa:ptpcoavector;
    //constructor init;
    procedure CommandStart(Operands:TCommandOperands); virtual;
    procedure CommandCancel; virtual;
    function BeforeClick(wc: GDBvertex; mc: GDBvertex2DI; var button: GDBByte;osp:pos_record): GDBInteger; virtual;
    function AfterClick(wc: GDBvertex; mc: GDBvertex2DI; var button: GDBByte;osp:pos_record): GDBInteger; virtual;
    function CalcTransformMatrix(p1,p2: GDBvertex):DMatrix4D; virtual;
    function Move(dispmatr:DMatrix4D;UndoMaker:GDBString): GDBInteger;
    procedure showprompt(mklick:integer);virtual;
  end;
{EXPORT-}
var
   move:move_com;
implementation
{constructor Move_com.init;
begin
  CommandInit;
  CommandName := 'Move';
  CommandGDBString := '';
end;}
procedure Move_com.showprompt(mklick:integer);
begin
     case mklick of
     0:ZCMsgCallBackInterface.TextMessage(rscmBasePoint,TMWOHistoryOut);
     1:ZCMsgCallBackInterface.TextMessage(rscmNewBasePoint,TMWOHistoryOut);
     end;
end;

procedure Move_com.CommandStart(Operands:TCommandOperands);
var //i: GDBInteger;
  tv,pobj: pGDBObjEntity;
      ir:itrec;
      counter:integer;
      tcd:TCopyObjectDesc;
      dc:TDrawContext;
begin
  //self.savemousemode:=drawings.GetCurrentDWG^.wa.param.md.mode;
  Inherited;
  counter:=0;

  pobj:=drawings.GetCurrentROOT^.ObjArray.beginiterate(ir);
  if pobj<>nil then
  repeat
    if pobj^.selected then
    inc(counter);
  pobj:=drawings.GetCurrentROOT^.ObjArray.iterate(ir);
  until pobj=nil;


  if counter>0 then
  begin
  inherited CommandStart('');
  drawings.GetCurrentDWG^.wa.SetMouseMode((MGet3DPoint) or (MMoveCamera) or (MRotateCamera));
  showprompt(0);
   dc:=drawings.GetCurrentDWG^.CreateDrawingRC;
   Getmem(GDBPointer(pcoa),sizeof(tpcoavector));
   pcoa^.init(counter);
   pobj:=drawings.GetCurrentROOT^.ObjArray.beginiterate(ir);
   if pobj<>nil then
   repeat
          begin
              if pobj^.selected then
              begin
                tv := pobj^.Clone({drawings.GetCurrentROOT}@drawings.GetCurrentDWG^.ConstructObjRoot);
                if tv<>nil then
                begin
                    drawings.GetCurrentDWG^.ConstructObjRoot.ObjArray.AddPEntity(tv^);
                    tcd.sourceEnt:=pobj;
                    tcd.tmpProxy:=tv;
                    tcd.copyEnt:=nil;
                    pcoa^.PushBackData(tcd);
                    tv^.formatentity(drawings.GetCurrentDWG^,dc);
                end;
              end;
          end;
          pobj:=drawings.GetCurrentROOT^.ObjArray.iterate(ir);
   until pobj=nil
  end
  else
  begin
    ZCMsgCallBackInterface.TextMessage(rscmSelEntBeforeComm,TMWOHistoryOut);
    Commandmanager.executecommandend;
  end;
end;

procedure Move_com.CommandCancel;
begin
     if pcoa<>nil then
     begin
          pcoa^.done;
          drawings.GetCurrentDWG^.ConstructObjRoot.ObjArray.free;
          Freemem(pointer(pcoa));
     end;
     inherited;
end;

function Move_com.BeforeClick(wc: GDBvertex; mc: GDBvertex2DI; var button: GDBByte;osp:pos_record): GDBInteger;
//var i: GDBInteger;
//  tv,pobj: pGDBObjEntity;
 //     ir:itrec;
begin
  t3dp:=wc;
  result:=0;
  if (button and MZW_LBUTTON)<>0 then
                                     showprompt(1);
end;
function Move_com.CalcTransformMatrix(p1,p2: GDBvertex):DMatrix4D;
var
    dist:gdbvertex;
begin
        dist:=uzegeometry.VertexSub(p2,p1);
        result:=uzegeometry.CreateTranslationMatrix(dist);
end;
function Move_com.Move(dispmatr:DMatrix4D;UndoMaker:GDBString): GDBInteger;
var
    //dist:gdbvertex;
    im:DMatrix4D;
    ir:itrec;
    pcd:PTCopyObjectDesc;
    m:tmethod;
    dc:TDrawContext;
begin
    im:=dispmatr;
    uzegeometry.MatrixInvert(im);
    PTZCADDrawing(drawings.GetCurrentDWG)^.UndoStack.PushStartMarker(UndoMaker);
    dc:=drawings.GetCurrentDWG^.CreateDrawingRC;
    with PushCreateTGMultiObjectChangeCommand(PTZCADDrawing(drawings.GetCurrentDWG)^.UndoStack,dispmatr,im,pcoa^.Count)^ do
    begin
     pcd:=pcoa^.beginiterate(ir);
   if pcd<>nil then
   repeat
        m:=tmethod(@pcd^.sourceEnt^.Transform);
        (*m.Data:=pcd^.sourceEnt;
        m.Code:={pointer}(@pcd^.sourceEnt^.Transform);*)
        AddMethod(m);

        dec(pcd^.sourceEnt^.vp.LastCameraPos);
        pcd^.sourceEnt^.Formatentity(drawings.GetCurrentDWG^,dc);

        pcd:=pcoa^.iterate(ir);
   until pcd=nil;
   comit;
   end;
   PTZCADDrawing(drawings.GetCurrentDWG)^.UndoStack.PushEndMarker;
   result:=cmd_ok;
end;
function Move_com.AfterClick(wc: GDBvertex; mc: GDBvertex2DI; var button: GDBByte;osp:pos_record): GDBInteger;
var //i:GDBInteger;
    //dist:gdbvertex;
    dispmatr{,im}:DMatrix4D;
    //ir:itrec;
    //pcd:PTCopyObjectDesc;
    //m:tmethod;
    dc:TDrawContext;
begin
      dispmatr:=CalcTransformMatrix(t3dp,wc);
      drawings.GetCurrentDWG^.ConstructObjRoot.ObjMatrix:=dispmatr;
      dc:=drawings.GetCurrentDWG^.CreateDrawingRC;
  if (button and MZW_LBUTTON)<>0 then
  begin
   move(dispmatr,self.CommandName);

   drawings.GetCurrentDWG^.ConstructObjRoot.ObjMatrix:=onematrix;
   drawings.GetCurrentDWG^.ConstructObjRoot.ObjArray.free;
   drawings.GetCurrentROOT^.FormatAfterEdit(drawings.GetCurrentDWG^,dc);

   commandmanager.executecommandend;
  end;
  result:=cmd_ok;
end;
procedure startup;
begin
  move.init('Move',0,0);
end;
procedure Finalize;
begin
end;
initialization
  debugln('{I}[UnitsInitialization] Unit "',{$INCLUDE %FILE%},'" initialization');
  startup;
finalization
  debugln('{I}[UnitsFinalization] Unit "',{$INCLUDE %FILE%},'" finalization');
  finalize;
end.
