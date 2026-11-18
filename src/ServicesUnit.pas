unit ServicesUnit;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Net.HttpClient, System.Net.URLClient;

type
  TServices = class
  private
    const
      URI_PRODUCAO = 'https://api.integrabancos.com.br/api/v';
      URI_SANDBOX = 'https://hom-api.integrabancos.com.br/api/v';

    var
      FBaseUri: string;
      FDebug: Boolean;
      FHttp: THTTPClient;

    function ErrorJson(const Mensagem: string; HttpCode: Integer; const Method, Url, Body: string): string;
  public
    constructor Create(IsProduction: Boolean; const Version: string = '1'; Timeout: Integer = 60; Debug: Boolean = False);
    destructor Destroy; override;
    function Request(const Method, Endpoint: string; const Body: string = ''; const Headers: TNetHeaders = nil): string;
  end;

implementation

{ TServices }

constructor TServices.Create(IsProduction: Boolean; const Version: string = '1'; Timeout: Integer = 60; Debug: Boolean = False);
begin
  if IsProduction then
    FBaseUri := URI_PRODUCAO + Version
  else
    FBaseUri := URI_SANDBOX + Version;

  FDebug := Debug;
  FHttp := THTTPClient.Create;
  FHttp.ConnectionTimeout := Timeout * 1000;
  FHttp.ResponseTimeout := Timeout * 1000;
end;

destructor TServices.Destroy;
begin
  FHttp.Free;
  inherited;
end;

function TServices.ErrorJson(const Mensagem: string; HttpCode: Integer; const Method, Url, Body: string): string;
var
  Obj, Req: TJSONObject;
begin
  Obj := TJSONObject.Create;
  try
    Obj.AddPair('sucesso', TJSONBool.Create(False));
    Obj.AddPair('mensagem', Mensagem);
    Obj.AddPair('http_code', TJSONNumber.Create(HttpCode));
    if FDebug then
    begin
      Req := TJSONObject.Create;
      Req.AddPair('method', Method);
      Req.AddPair('url', Url);
      Req.AddPair('body', Body);
      Obj.AddPair('request', Req);
    end;
    Result := Obj.ToJSON;
  finally
    Obj.Free;
  end;
end;

function TServices.Request(const Method, Endpoint: string; const Body: string = ''; const Headers: TNetHeaders = nil): string;
var
  Url: string;
  Req: IHTTPRequest;
  Resp: IHTTPResponse;
  Source: TStringStream;
  Header: TNameValuePair;
  Parsed: TJSONValue;
begin
  Url := FBaseUri + Endpoint;
  Source := nil;
  try
    try
      Req := FHttp.GetRequest(Method, Url);
      Req.AddHeader('Accept', 'application/json');
      Req.AddHeader('Content-Type', 'application/json');
      for Header in Headers do
        Req.AddHeader(Header.Name, Header.Value);

      // O body vai pelo SourceStream em qualquer verbo: o cancelamento de boleto é DELETE com corpo
      if Body <> '' then
      begin
        Source := TStringStream.Create(Body, TEncoding.UTF8);
        Req.SourceStream := Source;
      end;

      Resp := FHttp.Execute(Req);
      Result := Resp.ContentAsString(TEncoding.UTF8);

      if Result.Trim.IsEmpty then
        Exit(ErrorJson('Resposta vazia da API.', Resp.StatusCode, Method, Url, Body));

      Parsed := TJSONObject.ParseJSONValue(Result);
      if Parsed = nil then
        Exit(ErrorJson('Resposta inválida da API: ' + Copy(Result, 1, 500), Resp.StatusCode, Method, Url, Body));
      Parsed.Free;
    except
      on E: Exception do
        Result := ErrorJson('Erro na requisição: ' + E.Message, 0, Method, Url, Body);
    end;
  finally
    Source.Free;
  end;
end;

end.
