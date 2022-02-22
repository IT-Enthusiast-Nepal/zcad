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

unit gzctnrobjectschunk;
interface
uses gzctnrVector,sysutils,gzctnrvectortypes;
const
  ObjAlign=4;
type
{Export+}
{----REGISTEROBJECTTYPE GDataChunk}
GDataChunk=
  object(GZVector{-}<Byte>{//})(*OpenArrayOfData=GDBByte*)
                function beginiterate(out ir:itrec):Pointer;virtual;
                function iterate(var ir:itrec):Pointer;virtual;

                function Align(SData:Integer):Integer;
                procedure AlignDataSize;

                function AllocData(SData:Word):Integer;virtual;
             end;
{----REGISTEROBJECTTYPE GObjectsChunk}
GObjectsChunk{-}<PBaseObj>{//}=
  object(GDataChunk)(*OpenArrayOfData=GDBByte*)
                function iterate(var ir:itrec):Pointer;virtual;
             end;
{Export-}
implementation
function GDataChunk.Align(SData:Integer):Integer;
var
  m:integer;
begin
  m:=SData mod ObjAlign;
  if m=0 then
    result:=SData
  else
    result:=SData+ObjAlign-m;
end;

procedure GDataChunk.AlignDataSize;
var
  m:integer;
begin
  if not((parray=nil)or(count=0))then begin
    m:=Count mod ObjAlign;
    if m<>0 then
      inherited AllocData(ObjAlign-m);
    m:=Count mod ObjAlign
  end;
end;

function GDataChunk.AllocData(SData:Word):Integer;
var
  m:integer;
begin
  if not((parray=nil)or(count=0))then begin
    m:=Count mod ObjAlign;
    if m<>0 then
      inherited AllocData(ObjAlign-m);
    m:=Count mod ObjAlign
  end;
  result:=inherited;
end;
function GDataChunk.beginiterate(out ir:itrec):Pointer;
begin
     if parray=nil then
                       result:=nil
                   else
                       begin
                             ir.itp:=pointer(parray);
                             ir.itc:=0;
                             result:=pointer(parray);
                       end;
end;
function GDataChunk.iterate(var ir:itrec):Pointer;
var
  s:integer;
  m:integer;
begin
  if count=0 then result:=nil
  else
  begin
      s:=ObjAlign;
      if ir.itc<(count-s) then
                      begin
                           m:=s mod ObjAlign;
                           if m<>0 then
                             s:=s+ObjAlign-m;
                           inc(PByte(ir.itp),s);
                           inc(ir.itc,s);

                           result:=ir.itp;
                      end
                  else result:=nil;
  end;
end;

function GObjectsChunk<PBaseObj>.iterate(var ir:itrec):Pointer;
var
  s:integer;
  m:integer;
begin
  if count=0 then result:=nil
  else
  begin
      s:=sizeof(PBaseObj(ir.itp)^);
      if ir.itc<(count-s) then
                      begin
                           m:=s mod ObjAlign;
                           if m<>0 then
                             s:=s+ObjAlign-m;
                           inc(PByte(ir.itp),s);
                           inc(ir.itc,s);

                           result:=ir.itp;
                      end
                  else result:=nil;
  end;
end;

begin
end.

