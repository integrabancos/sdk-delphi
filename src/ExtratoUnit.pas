unit ExtratoUnit;

interface

uses
  System.SysUtils, System.JSON, BaseUnit;

type
  TIntegraExtrato = class(TBase)
  public
    constructor Create(Params: TJSONObject); override;
    function Credenciais(const Payload: TJSONObject): string;
    function Gerar(const Payload: TJSONObject): string;
    function ConsultarExtrato(const Payload: TJSONObject): string;
  end;

implementation

{ TIntegraExtrato }

constructor TIntegraExtrato.Create(Params: TJSONObject);
begin
  inherited Create(Params);
  RequireApiKey;
end;

function TIntegraExtrato.Credenciais(const Payload: TJSONObject): string;
begin
  Result := SendCrypt('POST', '/extrato/credenciais', Payload);
end;

function TIntegraExtrato.Gerar(const Payload: TJSONObject): string;
begin
  Result := SendJson('POST', '/extrato', Payload);
end;

function TIntegraExtrato.ConsultarExtrato(const Payload: TJSONObject): string;
begin
  Result := SendJson('GET', '/extrato/' + Segment(Payload, 'codigo_banco') + '/' + Segment(Payload, 'extrato_id'));
end;

end.
