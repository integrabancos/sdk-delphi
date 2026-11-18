unit BaseUnit;

interface

uses
  System.SysUtils, System.JSON, System.Net.URLClient, ServicesUnit, CryptoUnit, UtilUnit;

type
  EBaseException = class(Exception);

  TBase = class
  protected
    FAccessToken: string;
    FXApiKey: string;
    FSecretKey: string;
    FServices: TServices;

    procedure RequireApiKey;
    procedure RequireSecretKey;
    function Headers: TNetHeaders;
    function Segment(const Payload: TJSONObject; const Field: string): string;
    function SendJson(const Method, Route: string; const Payload: TJSONObject = nil): string;
    function SendCrypt(const Method, Route: string; const Payload: TJSONObject; WithHash: Boolean = False): string;
  public
    constructor Create(Params: TJSONObject); virtual;
    destructor Destroy; override;
  end;

function ParamBool(const Params: TJSONObject; const Name: string): Boolean;

implementation

function ParamBool(const Params: TJSONObject; const Name: string): Boolean;
var
  Val: TJSONValue;
begin
  Val := Params.FindValue(Name);
  Result := (Val <> nil) and ((Val is TJSONTrue) or SameText(Val.Value, 'true') or (Val.Value = '1'));
end;

{ TBase }

constructor TBase.Create(Params: TJSONObject);
begin
  if not Assigned(Params) then
    raise EBaseException.Create(TIntegraUtil.ErrorText('Devem ser passados os parametros básicos.'));

  FAccessToken := TIntegraUtil.JsonStr(Params, 'access_token');
  FXApiKey := TIntegraUtil.JsonStr(Params, 'x_api_key');
  FSecretKey := TIntegraUtil.JsonStr(Params, 'secret_key');

  if FAccessToken.Trim.IsEmpty then
    raise EBaseException.Create(TIntegraUtil.ErrorText('Access token é obrigatório para inicializar o SDK.'));

  FServices := TServices.Create(
    ParamBool(Params, 'is_production'),
    '1',
    StrToIntDef(TIntegraUtil.JsonStr(Params, 'timeout'), 60),
    ParamBool(Params, 'debug'));
end;

destructor TBase.Destroy;
begin
  FServices.Free;
  inherited;
end;

procedure TBase.RequireApiKey;
begin
  if FXApiKey.Trim.IsEmpty then
    raise EBaseException.Create(TIntegraUtil.ErrorText('x_api_key é obrigatório para esta operação (obtido no retorno da criação do emitente).'));
end;

procedure TBase.RequireSecretKey;
begin
  if FSecretKey.Trim.IsEmpty then
    raise EBaseException.Create(TIntegraUtil.ErrorText('secret_key é obrigatório para esta operação (pegar no cadastro da softhouse).'));
end;

function TBase.Headers: TNetHeaders;
begin
  Result := [TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)];
  if FXApiKey <> '' then
    Result := Result + [TNameValuePair.Create('x-api-key', FXApiKey)];
end;

function TBase.Segment(const Payload: TJSONObject; const Field: string): string;
begin
  Result := TIntegraUtil.JsonStr(Payload, Field);
  if Result.Trim.IsEmpty then
    raise EBaseException.Create(TIntegraUtil.ErrorText(Format('O campo [%s] é obrigatório para esta operação.', [Field]), Payload));

  Result := TIntegraUtil.EncodeSegment(Result);
end;

function TBase.SendJson(const Method, Route: string; const Payload: TJSONObject = nil): string;
var
  Body: string;
begin
  Body := '';
  if Assigned(Payload) then
    Body := Payload.ToJSON;

  Result := FServices.Request(Method, Route, Body, Headers);
end;

function TBase.SendCrypt(const Method, Route: string; const Payload: TJSONObject; WithHash: Boolean = False): string;
var
  Body: TJSONObject;
begin
  RequireSecretKey;
  if not Assigned(Payload) then
    raise EBaseException.Create(TIntegraUtil.ErrorText('O payload não pode ser nulo.'));

  Body := TJSONObject.Create;
  try
    if WithHash then
      Body.AddPair('hash', TIntegraCrypto.Hash(Payload));
    Body.AddPair('payload', TIntegraCrypto.Encrypt(Payload.ToJSON, FSecretKey));
    Result := FServices.Request(Method, Route, Body.ToJSON, Headers);
  finally
    Body.Free;
  end;
end;

end.
