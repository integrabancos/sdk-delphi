unit UtilUnit;

interface

uses
  System.SysUtils, System.JSON;

type
  TIntegraUtil = class
  public
    class function JsonStr(const Obj: TJSONObject; const Path: string): string;
    class function EncodeSegment(const Value: string): string;
    class function ErrorText(const Mensagem: string; const Data: TJSONValue = nil): string;
    class function PontoDecimal: TFormatSettings;
  end;

implementation

{ TIntegraUtil }

class function TIntegraUtil.JsonStr(const Obj: TJSONObject; const Path: string): string;
var
  Val: TJSONValue;
begin
  Result := '';
  if not Assigned(Obj) then
    Exit;

  Val := Obj.FindValue(Path);
  // TJSONNull.Value devolve 'null'; o PHP do servidor interpola null como string vazia
  if (Val = nil) or (Val is TJSONNull) then
    Exit;

  Result := Val.Value;
end;

class function TIntegraUtil.EncodeSegment(const Value: string): string;
var
  B: Byte;
begin
  Result := '';
  for B in TEncoding.UTF8.GetBytes(Value) do
    if CharInSet(Char(B), ['A'..'Z', 'a'..'z', '0'..'9', '-', '.', '_', '~']) then
      Result := Result + Char(B)
    else
      Result := Result + '%' + IntToHex(B, 2);
end;

class function TIntegraUtil.ErrorText(const Mensagem: string; const Data: TJSONValue = nil): string;
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  try
    Obj.AddPair('message', Mensagem);
    if Assigned(Data) then
      Obj.AddPair('data', Data.Clone as TJSONValue);
    Result := Obj.ToJSON;
  finally
    Obj.Free;
  end;
end;

class function TIntegraUtil.PontoDecimal: TFormatSettings;
begin
  Result := TFormatSettings.Create;
  Result.DecimalSeparator := '.';
  Result.ThousandSeparator := ',';
end;

end.
