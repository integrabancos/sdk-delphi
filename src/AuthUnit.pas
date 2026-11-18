unit AuthUnit;

interface

uses
  System.SysUtils, System.JSON, ServicesUnit, UtilUnit;

type
  EAuthException = class(Exception);

  TIntegraAuth = class
  public
    class function GetAccessToken(const Credentials: TJSONObject; const RefreshToken: string = ''; IsProduction: Boolean = False; Debug: Boolean = False): string;
  end;

implementation

{ TIntegraAuth }

class function TIntegraAuth.GetAccessToken(const Credentials: TJSONObject; const RefreshToken: string = ''; IsProduction: Boolean = False; Debug: Boolean = False): string;
var
  ClientId, ClientSecret, Username, Password: string;
  Payload: TJSONObject;
  Services: TServices;
begin
  ClientId := TIntegraUtil.JsonStr(Credentials, 'client_id');
  ClientSecret := TIntegraUtil.JsonStr(Credentials, 'client_secret');
  Username := TIntegraUtil.JsonStr(Credentials, 'username');
  Password := TIntegraUtil.JsonStr(Credentials, 'password');

  if (ClientId = '') or (ClientSecret = '') or (((Username = '') or (Password = '')) and (RefreshToken = '')) then
    raise EAuthException.Create(TIntegraUtil.ErrorText('Credenciais incompletas para obtenção de token: informe client_id, client_secret e username/password ou refresh_token.'));

  Payload := TJSONObject.Create;
  Services := TServices.Create(IsProduction, '1', 60, Debug);
  try
    Payload.AddPair('client_id', ClientId);
    Payload.AddPair('client_secret', ClientSecret);
    Payload.AddPair('scope', '');
    if RefreshToken <> '' then
    begin
      Payload.AddPair('grant_type', 'refresh_token');
      Payload.AddPair('refresh_token', RefreshToken);
    end
    else
    begin
      Payload.AddPair('grant_type', 'password');
      Payload.AddPair('username', Username);
      Payload.AddPair('password', Password);
    end;

    Result := Services.Request('POST', '/oauth/token', Payload.ToJSON);
  finally
    Services.Free;
    Payload.Free;
  end;
end;

end.
