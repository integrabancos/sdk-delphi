unit SDKUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.JSON, AuthUnit;

type
  TForm1 = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  Credentials: TJSONObject;
  Resp: string;
  RespJson: TJSONValue;
  RefreshToken: string;
begin
  // Depois do primeiro login, passe o refresh_token salvo em vez de username/password
  RefreshToken := '';

  Credentials := TJSONObject.Create;
  try
    Credentials.AddPair('client_id', 'CLIENT-ID');
    Credentials.AddPair('client_secret', 'CLIENT-SECRET');
    Credentials.AddPair('username', 'seuemail@suaempresa.com.br');
    Credentials.AddPair('password', '12345678');

    Resp := TIntegraAuth.GetAccessToken(Credentials, RefreshToken, False);
  finally
    Credentials.Free;
  end;

  RespJson := TJSONObject.ParseJSONValue(Resp);
  try
    if (RespJson = nil) or (RespJson.FindValue('access_token') = nil) then
      raise Exception.Create('Falha ao obter o access_token: ' + Resp);

    // Salve access_token, refresh_token e expires_in no seu banco de dados
    ShowMessage(
      'access_token: ' + RespJson.FindValue('access_token').Value + sLineBreak +
      'refresh_token: ' + RespJson.FindValue('refresh_token').Value + sLineBreak +
      'expires_in: ' + RespJson.FindValue('expires_in').Value);
  finally
    RespJson.Free;
  end;
end;

end.
