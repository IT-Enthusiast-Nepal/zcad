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
{**
@author(Andrey Zubarev <zamtmn@yandex.ru>) 
}

unit uzcutils;
{$INCLUDE def.inc}


interface
uses uzeutils,LCLProc,zcmultiobjectcreateundocommand,uzeentitiesmanager,uzepalette,
     uzeentityfactory,uzgldrawcontext,uzcdrawing,uzestyleslinetypes,uzcsysvars,
     uzestyleslayers,sysutils,gdbasetypes,gdbase,uzcdrawings,varmandef,
     uzeconsts,UGDBVisibleOpenArray,uzeentgenericsubentry,uzeentity,
     uzeentblockinsert,memman;

  {**Добавление в чертеж примитива с обвязкой undo
    @param(PEnt Указатель на добавляемый примитив)
    @param(Drawing Чертеж куда будет добавлен примитив)}
  procedure zcAddEntToDrawingWithUndo(const PEnt:PGDBObjEntity;var Drawing:TDrawing);

  {**Добавление в текущий чертеж примитива с обвязкой undo
    @param(PEnt Указатель на добавляемый примитив)}
  procedure zcAddEntToCurrentDrawingWithUndo(const PEnt:PGDBObjEntity);

  procedure zcAddEntToCurrentDrawingConstructRoot(const PEnt: PGDBObjEntity);

  procedure zcClearCurrentDrawingConstructRoot;

  {**Получение "описателя" выбраных примитивов в текущем "корне" текущего чертежа
    @return(Указатель на первый выбранный примитив и общее количество выбраных примитивов)}
  function zcGetSelEntsDeskInCurrentRoot:TSelEntsDesk;

  {**Выставление общих свойств примитива в соответствии с настройками текущего чертежа.
     Слой, Тип линии, Вес линии, Цвет, Масштаб типа линии
    @param(PEnt Указатель на примитив)}
  procedure zcSetEntPropFromCurrentDrawingProp(const PEnt: PGDBObjEntity);

  {**Помещение в стек undo маркера начала команды. Используется для группировки
     операций отмены. Допускаются вложеные команды. Количество маркеров начала и
     конца должно совпадать
    @param(CommandName Имя команды. Будет показано в окне истории при отмене\повторе)}
  procedure zcStartUndoCommand(CommandName:GDBString);

  {**Помещение в стек undo маркера конца команды. Используется для группировки
     операций отмены. Допускаются вложеные команды. Количество маркеров начала и
     конца должно совпадать}
  procedure zcEndUndoCommand;

function GDBInsertBlock(own:PGDBObjGenericSubEntry;BlockName:GDBString;p_insert:GDBVertex;
                        scale:GDBVertex;rotate:GDBDouble;needundo:GDBBoolean=false
                        ):PGDBObjBlockInsert;

function old_ENTF_CreateBlockInsert(owner:PGDBObjGenericSubEntry;ownerarray: PGDBObjEntityOpenArray;
                                layeraddres:PGDBLayerProp;LTAddres:PGDBLtypeProp;color:TGDBPaletteColor;LW:TGDBLineWeight;
                                point: gdbvertex; scale, angle: GDBDouble; s: pansichar):PGDBObjBlockInsert;
implementation
function old_ENTF_CreateBlockInsert(owner:PGDBObjGenericSubEntry;ownerarray: PGDBObjEntityOpenArray;
                                layeraddres:PGDBLayerProp;LTAddres:PGDBLtypeProp;color:TGDBPaletteColor;LW:TGDBLineWeight;
                                point: gdbvertex; scale, angle: GDBDouble; s: pansichar):PGDBObjBlockInsert;
var
  pb:pgdbobjblockinsert;
  nam:gdbstring;
  DC:TDrawContext;
  CreateProc:TAllocAndInitAndSetGeomPropsFunc;
begin
  result:=nil;
  if pos(DevicePrefix, uppercase(s))=1  then
                                            begin
                                                nam:=copy(s,length(DevicePrefix)+1,length(s)-length(DevicePrefix));
                                                CreateProc:=_StandartDeviceCreateProcedure;
                                            end
                                        else
                                            begin
                                                 nam:=s;
                                                 CreateProc:=_StandartBlockInsertCreateProcedure;
                                            end;
  if assigned(CreateProc)then
                           begin
                               PGDBObjEntity(pb):=CreateProc(owner,[point.x,point.y,point.z,scale,angle,nam]);
                               zeSetEntityProp(pb,layeraddres,LTAddres,color,LW);
                               if ownerarray<>nil then
                                               ownerarray^.add(@pb);
                           end
                       else
                           begin
                                pb:=nil;
                                debugln('{E}ENTF_CreateBlockInsert: BlockInsert entity not registred');
                                //programlog.LogOutStr('ENTF_CreateBlockInsert: BlockInsert entity not registred',lp_OldPos,LM_Error);
                           end;
  if pb=nil then exit;
  //setdefaultproperty(pb);
  pb.pattrib := nil;
  pb^.BuildGeometry(gdb.GetCurrentDWG^);
  pb^.BuildVarGeometry(gdb.GetCurrentDWG^);
  DC:=gdb.GetCurrentDWG^.CreateDrawingRC;
  pb^.formatEntity(gdb.GetCurrentDWG^,dc);
  owner.ObjArray.ObjTree.CorrectNodeTreeBB(pb);
  result:=pb;
end;
procedure zcAddEntToDrawingWithUndo(const PEnt:PGDBObjEntity;var Drawing:TDrawing);
var
    domethod,undomethod:tmethod;
begin
     SetObjCreateManipulator(domethod,undomethod);
     with PushMultiObjectCreateCommand(Drawing.UndoStack,tmethod(domethod),tmethod(undomethod),1)^ do
     begin
          AddObject(PEnt);
          comit;
     end;
end;
procedure zcAddEntToCurrentDrawingWithUndo(const PEnt:PGDBObjEntity);
begin
     zcAddEntToDrawingWithUndo(PEnt,PTDrawing(gdb.GetCurrentDWG)^);
end;
procedure zcStartUndoCommand(CommandName:GDBString);
begin
     PTDrawing(gdb.GetCurrentDWG)^.UndoStack.PushStartMarker(CommandName);
end;
procedure zcAddEntToCurrentDrawingConstructRoot(const PEnt: PGDBObjEntity);
begin
  zeAddEntToRoot(PEnt,gdb.GetCurrentDWG^.ConstructObjRoot);
end;
procedure zcClearCurrentDrawingConstructRoot;
begin
  gdb.GetCurrentDWG^.ConstructObjRoot.ObjArray.Clear;
end;
procedure zcEndUndoCommand;
begin
     PTDrawing(gdb.GetCurrentDWG)^.UndoStack.PushEndMarker;
end;
function GDBInsertBlock(own:PGDBObjGenericSubEntry;//владелец
                        BlockName:GDBString;       //имя блока
                        p_insert:GDBVertex;        //точка вставки
                        scale:GDBVertex;           //масштаб
                        rotate:GDBDouble;          //поворот
                        needundo:GDBBoolean=false  //завернуть в ундо
                        ):PGDBObjBlockInsert;
var
  tb:PGDBObjBlockInsert;
  domethod,undomethod:tmethod;
  DC:TDrawContext;
begin
  result := GDBPointer(own.ObjArray.CreateObj(GDBBlockInsertID));
  result.init(gdb.GetCurrentROOT,gdb.GetCurrentDWG^.GetCurrentLayer,0);
  result^.Name:=BlockName;
  result^.vp.ID:=GDBBlockInsertID;
  result^.Local.p_insert:=p_insert;
  result^.scale:=scale;
  result^.CalcObjMatrix;
  result^.setrot(rotate);
  result^.rotate:=rotate;
  tb:=pointer(result^.FromDXFPostProcessBeforeAdd(nil,gdb.GetCurrentDWG^));
  if tb<>nil then begin
                       tb^.bp:=result^.bp;
                       result^.done;
                       gdbfreemem(pointer(result));
                       result:=pointer(tb);
  end;
  if needundo then
  begin
      SetObjCreateManipulator(domethod,undomethod);
      with PushMultiObjectCreateCommand(PTDrawing(gdb.GetCurrentDWG)^.UndoStack,tmethod(domethod),tmethod(undomethod),1)^ do
      begin
           AddObject(result);
           comit;
      end;
  end
  else
     own.ObjArray.add(addr(result));
  result^.CalcObjMatrix;
  result^.BuildGeometry(gdb.GetCurrentDWG^);
  result^.BuildVarGeometry(gdb.GetCurrentDWG^);
  DC:=gdb.GetCurrentDWG^.CreateDrawingRC;
  result^.FormatEntity(gdb.GetCurrentDWG^,dc);
  if needundo then
  begin
  gdb.GetCurrentROOT^.ObjArray.ObjTree.CorrectNodeTreeBB(result);
  result^.Visible:=0;
  result^.RenderFeedback(gdb.GetCurrentDWG^.pcamera^.POSCOUNT,gdb.GetCurrentDWG^.pcamera^,gdb.GetCurrentDWG^.myGluProject2,dc);
  end;
end;
function zcGetSelEntsDeskInCurrentRoot:TSelEntsDesk;
begin
  result:=zeGetSelEntsDeskInRoot(gdb.GetCurrentROOT^);
end;
procedure zcSetEntPropFromCurrentDrawingProp(const PEnt: PGDBObjEntity);
begin
     zeSetEntPropFromDrawingProp(PEnt,gdb.GetCurrentDWG^)
end;

procedure setdefaultproperty(pvo:pgdbobjEntity);
begin
  pvo^.selected := false;
  pvo^.Visible:=gdb.GetCurrentDWG.pcamera.VISCOUNT;
  pvo^.vp.layer :=gdb.GetCurrentDWG.GetCurrentLayer;
  pvo^.vp.lineweight := sysvar.dwg.DWG_CLinew^;
end;

begin
end.
