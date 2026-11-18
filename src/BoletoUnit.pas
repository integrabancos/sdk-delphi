unit BoletoUnit;

interface

uses
  System.SysUtils, System.JSON, BaseUnit;

type
  TIntegraBoleto = class(TBase)
  public
    constructor Create(Params: TJSONObject); override;
    function Credenciais(const Payload: TJSONObject): string;
    function GerarBoleto(const Payload: TJSONObject): string;
    function ConsultarBoleto(const Payload: TJSONObject): string;
    function AlterarBoleto(const Payload: TJSONObject): string;
    function CancelarBoleto(const Payload: TJSONObject): string;
    function ConsultarEventoBoleto(const Payload: TJSONObject): string;
    function GerarImpressao(const Payload: TJSONObject): string;
    function ConsultarImpressao(const Payload: TJSONObject): string;
  end;

implementation

{ TIntegraBoleto }

constructor TIntegraBoleto.Create(Params: TJSONObject);
begin
  inherited Create(Params);
  RequireApiKey;
end;

function TIntegraBoleto.Credenciais(const Payload: TJSONObject): string;
begin
  Result := SendCrypt('POST', '/cobranca/credenciais', Payload);
end;

function TIntegraBoleto.GerarBoleto(const Payload: TJSONObject): string;
begin
  Result := SendCrypt('POST', '/cobranca', Payload, True);
end;

function TIntegraBoleto.ConsultarBoleto(const Payload: TJSONObject): string;
begin
  Result := SendJson('GET', '/cobranca/' + Segment(Payload, 'codigo_banco') + '/' + Segment(Payload, 'identificacao'));
end;

function TIntegraBoleto.AlterarBoleto(const Payload: TJSONObject): string;
begin
  Result := SendCrypt('PUT', '/cobranca', Payload);
end;

function TIntegraBoleto.CancelarBoleto(const Payload: TJSONObject): string;
begin
  Result := SendCrypt('DELETE', '/cobranca', Payload);
end;

function TIntegraBoleto.ConsultarEventoBoleto(const Payload: TJSONObject): string;
begin
  Result := SendJson('GET', '/cobranca/' + Segment(Payload, 'codigo_banco') + '/' + Segment(Payload, 'identificacao') + '/' + Segment(Payload, 'evento_id'));
end;

function TIntegraBoleto.GerarImpressao(const Payload: TJSONObject): string;
begin
  Result := SendJson('POST', '/cobranca/impressao', Payload);
end;

function TIntegraBoleto.ConsultarImpressao(const Payload: TJSONObject): string;
begin
  Result := SendJson('GET', '/cobranca/impressao/' + Segment(Payload, 'impressao_id'));
end;

end.
