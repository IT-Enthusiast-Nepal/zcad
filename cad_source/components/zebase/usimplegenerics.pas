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
unit usimplegenerics;
{$INCLUDE def.inc}

interface
uses strproc,gdbase,gdbasetypes,
     {$IFNDEF DELPHI}gutil,gmap,ghashmap,gvector,{$ENDIF}
     {$IFDEF DELPHI}generics.collections,{$ENDIF}
     sysutils;
type
{$IFNDEF DELPHI}
LessPointer= TLess<pointer>;
LessGDBString= TLess<GDBString>;
LessDWGHandle= TLess<TDWGHandle>;
LessObjID= TLess<TObjID>;
LessInteger= TLess<Integer>;
{$ENDIF}
{$IFDEF DELPHI}
TMapForDelphi <TKey, TValue> = class( TDictionary<TKey, TValue>)
end;
{$ENDIF}
{$IFNDEF DELPHI}TMyMapGen <TKey, TValue, TCompare> = class( TMap<TKey, TValue, TCompare>){$ENDIF}
 {$IFDEF DELPHI}TMyMapGen <TKey,TValue> = class( TDictionary<TKey,TValue>){$ENDIF}
  function MyGetValue(key:TKey):TValue;inline;
end;
{$IFNDEF DELPHI}TMyMap <TKey, TValue, TCompare> = class( TMyMapGen<TKey, TValue, TCompare>){$ENDIF}
 {$IFDEF DELPHI}TMyMap <TKey,TValue> = class( TMyMapGen<TKey,TValue>){$ENDIF}
  procedure MyGetOrCreateValue(const key:TKey; var Value:TValue; out OutValue:TValue);inline;
end;
{$IFNDEF DELPHI}TMyMapCounter <TKey, TCompare> = class( TMyMap<TKey, SizeUInt, TCompare>){$ENDIF}
 {$IFDEF DELPHI}TMyMapCounter <TKey, TCompare> = class( TMyMap<TKey, SizeUInt>){$ENDIF}
  procedure CountKey(const key:TKey; const InitialCounter:SizeUInt);inline;
end;
{$IFNDEF DELPHI}GKey2DataMap <TKey, TValue, TCompare> = class(TMap<TKey, TValue, TCompare>){$ENDIF}
 {$IFDEF DELPHI}GKey2DataMap <TKey, TValue> = class(TDictionary<TKey, TValue>){$ENDIF}
        {$IFDEF DELPHI}type PTValue=^TValue;{$ENDIF}
        procedure RegisterKey(const key:TKey; const Value:TValue);
        function MyGetValue(key:TKey; out Value:TValue):boolean;
        function MyGetMutableValue(key:TKey; out PValue:{$IFNDEF DELPHI}PTValue{$ENDIF}{$IFDEF DELPHI}pointer{$ENDIF}):boolean;
        function MyContans(key:TKey):boolean;
end;
{$IFNDEF DELPHI}TMyVector <T> = class(TVector<T>){$ENDIF}
 {$IFDEF DELPHI}TMyVector <T> = class(Generics.Collections.TList<T>)
                                     function Size: SizeUInt; inline;
                                     procedure PushBack(const Value: T); inline;
                                     function mutable(const i:integer):pointer; inline;
 {$ENDIF}
end;

TMyVectorArray <T> = class
        type
        TVec=TMyVector <T>;
        TArrayOfVec=TMyVector <TVec>;
        var
        VArray:TArrayOfVec;
        CurrentArray:SizeInt;
        constructor create;
        destructor destroy;virtual;
        function AddArray:SizeInt;
        procedure SetCurrentArray(ai:SizeInt);
        procedure AddDataToCurrentArray(data:T);
end;

{$IFNDEF DELPHI}TMyHashMap <TKey, TValue, Thash> = class(THashMap<TKey, TValue, Thash>){$ENDIF}
 {$IFDEF DELPHI}TMyHashMap <TKey, TValue> = class(TDictionary<TKey, TValue>){$ENDIF}
  function MyGetValue(key:TKey; out Value:TValue):boolean;
end;
{$IFNDEF DELPHI}
GDBStringHash=class
  class function hash(s:GDBstring; n:longint):SizeUInt;
end;
{$ENDIF}
TMyGDBStringDictionary <TValue> = class(TMyHashMap<GDBString, TValue{$IFNDEF DELPHI},GDBStringHash{$ENDIF}>)
end;


TGDBString2GDBStringDictionary=TMyGDBStringDictionary<GDBString>;

TMapPointerToHandle=TMyMap<pointer,TDWGHandle{$IFNDEF DELPHI}, LessPointer{$ENDIF}>;

TMapHandleToHandle=TMyMap<TDWGHandle,TDWGHandle{$IFNDEF DELPHI}, LessDWGHandle{$ENDIF}>;
TMapHandleToPointer=TMyMap<TDWGHandle,pointer{$IFNDEF DELPHI}, LessDWGHandle{$ENDIF}>;

TMapBlockHandle_BlockNames={$IFNDEF DELPHI}TMap{$ENDIF}{$IFDEF DELPHI}TMapForDelphi{$ENDIF}<TDWGHandle,string{$IFNDEF DELPHI},LessDWGHandle{$ENDIF}>;
TEntUpgradeKey=record
                      EntityID:TObjID;
                      UprradeInfo:TEntUpgradeInfo;
               end;
{$IFNDEF DELPHI}
LessEntUpgradeKey=class
  class function c(a,b:TEntUpgradeKey):boolean;inline;
end;
{$ENDIF}
implementation
{$IFDEF DELPHI}
function TMyVector<T>.Size: SizeUInt;
begin
  result:=count;
end;
procedure TMyVector<T>.PushBack(const Value: T);
begin
  Add(value);
end;
function TMyVector<T>.mutable(const i:integer):pointer;
begin
  result:=@FItems[i];
end;
{$ENDIF}
constructor TMyVectorArray<T>.create;
begin
     VArray:=TArrayOfVec.create;
end;
destructor TMyVectorArray<T>.destroy;
begin
     VArray.destroy;
end;
function TMyVectorArray<T>.AddArray:SizeInt;
begin
     result:=VArray.{$IFNDEF DELPHI}size{$ENDIF}{$IFDEF DELPHI}Count{$ENDIF};
     VArray.{$IFNDEF DELPHI}PushBack{$ENDIF}{$IFDEF DELPHI}Add{$ENDIF}(TVec.create);
end;
procedure TMyVectorArray<T>.SetCurrentArray(ai:SizeInt);
begin
     CurrentArray:=ai;
end;
procedure TMyVectorArray<T>.AddDataToCurrentArray(data:T);
begin
     (VArray[CurrentArray]){brackets for 2.6.x compiler version}.{$IFNDEF DELPHI}PushBack{$ENDIF}{$IFDEF DELPHI}Add{$ENDIF}(data);
end;
function TMyHashMap<TKey, TValue{$IFNDEF DELPHI},Thash{$ENDIF}>.MyGetValue(key:TKey; out Value:TValue):boolean;
{$IFNDEF DELPHI}var i,h,bs:longint;{$ENDIF}
begin
  (*
  {IF FPC_FULlVERSION<=20701}
  result:=contains(key);
  if result then value:=self.GetData(key);
  *)
  {$IFNDEF DELPHI}
  h:=Thash.hash(key,FData.size);
  bs:=(FData[h]).size;
  for i:=0 to bs-1 do begin
    if (((FData[h])[i]).Key=key) then
                                     begin
                                          value:=((FData[h])[i]).Value;
                                          exit(true);
                                     end;
  end;
  exit(false);
  {$ENDIF}
  {$IFDEF DELPHI}
    result:=TryGetValue(Key,Value);
  {$ENDIF}
end;
{$IFNDEF DELPHI}
class function GDBStringHash.hash(s:GDBString; n:longint):SizeUInt;
begin
     result:=makehash(s) mod SizeUInt(n);
end;
class function LessEntUpgradeKey.c(a,b:TEntUpgradeKey):boolean;inline;
begin
  //c:=a<b;
  if a.UprradeInfo=b.UprradeInfo then
                                     exit(a.EntityID<b.EntityID)
  else result:=a.UprradeInfo<b.UprradeInfo;

end;
{$ENDIF}
procedure GKey2DataMap<TKey, TValue{$IFNDEF DELPHI},TCompare{$ENDIF}>.RegisterKey(const key:TKey; const Value:TValue);
{$IFNDEF DELPHI}
var
   (*
   {IFDEF OldIteratorDef}
   TParent:specialize TMap<TKey, TValue, TCompare>;
   Iterator:TParent.TIterator;
   {ELSE}
   *)
   Iterator:TIterator;
{$ENDIF}
begin
{$IFNDEF DELPHI}
  Iterator:=Find(key);
  if  Iterator=nil then
                       begin
                            Insert(Key,Value);
                       end
                   else
                       begin
                            Iterator.Value:=value;
                            Iterator.Destroy;
                       end;
{$ENDIF}
{$IFDEF DELPHI}
  AddOrSetValue(Key,Value);
{$ENDIF}
end;
function GKey2DataMap<TKey, TValue{$IFNDEF DELPHI},TCompare{$ENDIF}>.MyGetValue(key:TKey; out Value:TValue):boolean;
{$IFNDEF DELPHI}
var
   (*
   {IFDEF OldIteratorDef}
   TParent:specialize TMap<TKey, TValue, TCompare>;
   Iterator:TParent.TIterator;
   {ELSE}
   *)
   Iterator:TIterator;
{$ENDIF}
begin
{$IFNDEF DELPHI}
  Iterator:=Find(key);
  if  Iterator=nil then
                       result:=false
                   else
                       begin
                            Value:=Iterator.GetValue;
                            Iterator.Destroy;
                            result:=true;
                       end;
{$ENDIF}
{$IFDEF DELPHI}
  result:=TryGetValue(Key,Value);
{$ENDIF}
end;
function GKey2DataMap<TKey, TValue{$IFNDEF DELPHI},TCompare{$ENDIF}>.MyGetMutableValue(key:TKey; out PValue:{$IFNDEF DELPHI}PTValue{$ENDIF}{$IFDEF DELPHI}pointer{$ENDIF}):boolean;
{$IFNDEF DELPHI}
var
   (*
   {IFDEF OldIteratorDef}
   TParent:specialize TMap<TKey, TValue, TCompare>;
   Iterator:TParent.TIterator;
   {ELSE}
   *)
   Iterator:TIterator;
{$ENDIF}
{$IFDEF DELPHI}
var
  hc: Integer;
  index: Integer;
{$ENDIF}
begin
{$IFNDEF DELPHI}
  Iterator:=Find(key);
  if  Iterator=nil then
                       result:=false
                   else
                       begin
                            PValue:=Iterator.MutableValue;
                            Iterator.Destroy;
                            result:=true;
                       end;
{$ENDIF}
{$IFDEF DELPHI}
  hc:=Hash(Key);
  index := GetBucketIndex(Key, hc);
  if index >= 0 then
    begin
      PValue:=@FItems[Index].Value;
      result:=true;
    end
  else
    begin
      PValue:=nil;
      result:=false;
    end;
{$ENDIF}
end;
function GKey2DataMap<TKey, TValue{$IFNDEF DELPHI},TCompare{$ENDIF}>.MyContans(key:TKey):boolean;
{$IFNDEF DELPHI}
var
   (*
   {$IF FPC_FULlVERSION<=20701}
   {$IFDEF OldIteratorDef}
   TParent:specialize TMap<TKey, TValue, TCompare>;
   Iterator:TParent.TIterator;
   {$ELSE}
   Iterator:TIterator;
   {$ENDIF}
   {$ELSE}
   *)
   Pair:TPair;
   Node: TMSet.PNode;
begin
  (*
  {$IF FPC_FULlVERSION<=20701}
  Iterator:=Find(key);
  if Iterator<>nil then
                           begin
                                result:=true;
                                Iterator.Destroy;
                           end
                       else
                           result:=false;
  {$ELSE}
  *)
  Pair.Key:=key;
  Node := FSet.NFind(Pair);
  Result := Node <> nil;
end;
{$ENDIF}
{$IFDEF DELPHI}
var
  hc: Integer;
  index: Integer;
begin
  hc:=Hash(Key);
  index := GetBucketIndex(Key, hc);
  if index >= 0 then
    begin
      result:=true;
    end
  else
    begin
      result:=false;
    end;
end;
{$ENDIF}

function TMyMapGen<TKey, TValue{$IFNDEF DELPHI},TCompare{$ENDIF}>.MyGetValue(key:TKey):TValue;
{$IFNDEF DELPHI}
var
   (*
   {IFDEF OldIteratorDef}
   TParent:specialize TMap<TKey, TValue, TCompare>;
   Iterator:TParent.TIterator;
   {ELSE}
   *)
   Iterator:TIterator;
{$ENDIF}
begin
{$IFNDEF DELPHI}
  Iterator:=Find(key);
  if  Iterator=nil then
                       //result:=TValue(0)
                       result:=default(TValue)
                   else
                       begin
                            result:=Iterator.GetValue;
                            Iterator.Destroy;
                       end;
{$ENDIF}
{$IFDEF DELPHI}
  if not TryGetValue(Key,result) then
                                     result:=default(TValue);
{$ENDIF}
end;
procedure TMyMapCounter<TKey, TCompare>.CountKey(const key:TKey; const InitialCounter:SizeUInt);
{$IFNDEF DELPHI}
var
   (*
   {IFDEF OldIteratorDef}
   TParent:specialize TMap<TKey, TValue, TCompare>;
   Iterator:TParent.TIterator;
   {ELSE}
   *)
   Iterator:TIterator;
begin
  Iterator:=Find(key);
  if  Iterator=nil then
                       begin
                            Insert(Key, InitialCounter);
                       end
                   else
                       begin
                            Iterator.SetValue(Iterator.GetValue+1);
                            Iterator.Destroy;
                       end;
end;
{$ENDIF}
{$IFDEF DELPHI}
var
  hc: Integer;
  index: Integer;
begin
  hc:=Hash(Key);
  index := GetBucketIndex(Key, hc);
  if index >= 0 then
    begin
      inc(FItems[Index].Value);
    end
  else
    begin
      AddOrSetValue(Key,InitialCounter);
    end;
end;
{$ENDIF}
procedure TMyMap<TKey, TValue{$IFNDEF DELPHI},TCompare{$ENDIF}>.MyGetOrCreateValue(const key:TKey; var Value:TValue; out OutValue:TValue);
{$IFNDEF DELPHI}
var
   (*
   {IFDEF OldIteratorDef}
   TParent:specialize TMap<TKey, TValue, TCompare>;
   Iterator:TParent.TIterator;
   {ELSE}
   *)
   Iterator:TIterator;
begin
  Iterator:=Find(key);
  if  Iterator=nil then
                       begin
                            Insert(Key, Value);
                            OutValue:=Value;
                            value:=value+1;
                            //inc(Value);
                       end
                   else
                       begin
                            OutValue:=Iterator.GetValue;
                            Iterator.Destroy;
                       end;
end;
{$ENDIF}
{$IFDEF DELPHI}
var
  hc: Integer;
  index: Integer;
begin
  hc:=Hash(Key);
  index := GetBucketIndex(Key, hc);
  if index >= 0 then
    begin
      OutValue:=FItems[Index].Value;
    end
  else
    begin
      AddOrSetValue(Key,Value);
      OutValue:=Value;
      //value:=value+1;
    end;
end;
{$ENDIF}
begin
end.
