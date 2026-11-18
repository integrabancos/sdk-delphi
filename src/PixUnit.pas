unit PixUnit;

interface

uses
  System.SysUtils, System.JSON, BaseUnit;

type
  TIntegraPix = class(TBase)
  public
    constructor Create(Params: TJSONObject); override;
    function Credenciais(const Payload: TJSONObject): string;
    function Gerar(const Payload: TJSONObject): string;
    function ConsultarPix(const Payload: TJSONObject): string;
  end;

implementation

{ TIntegraPix }

constructor TIntegraPix.Create(Params: TJSONObject);
begin
  inherited Create(Params);
  RequireApiKey;
end;

function TIntegraPix.Credenciais(const Payload: TJSONObject): string;
begin
  Result := SendCrypt('POST', '/pix/credenciais', Payload);
end;

function TIntegraPix.Gerar(const Payload: TJSONObject): string;
begin
  Result := SendCrypt('POST', '/pix', Payload, True);
end;

function TIntegraPix.ConsultarPix(const Payload: TJSONObject): string;
begin
  Result := SendJson('GET', '/pix/' + Segment(Payload, 'codigo_banco') + '/' + Segment(Payload, 'identificacao'));
end;

end.
