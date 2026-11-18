unit EmitenteUnit;

interface

uses
  System.SysUtils, System.JSON, BaseUnit;

type
  TIntegraEmitente = class(TBase)
  public
    function Cria(const Payload: TJSONObject): string;
    function Atualiza(const Payload: TJSONObject): string;
    function Webhook(const Payload: TJSONObject): string;
    function Autorizacao(const Payload: TJSONObject): string;
  end;

implementation

{ TIntegraEmitente }

function TIntegraEmitente.Cria(const Payload: TJSONObject): string;
begin
  Result := SendJson('POST', '/emitente', Payload);
end;

function TIntegraEmitente.Atualiza(const Payload: TJSONObject): string;
begin
  RequireApiKey;
  Result := SendJson('PUT', '/emitente', Payload);
end;

function TIntegraEmitente.Webhook(const Payload: TJSONObject): string;
begin
  RequireApiKey;
  Result := SendJson('PUT', '/emitente/webhook', Payload);
end;

function TIntegraEmitente.Autorizacao(const Payload: TJSONObject): string;
begin
  RequireApiKey;
  Result := SendJson('POST', '/emitente/autorizacao', Payload);
end;

end.
