unit SDKUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.JSON, EmitenteUnit;

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
  Params, Payload: TJSONObject;
  Emitente: TIntegraEmitente;
begin
  Params := TJSONObject.Create;
  try
    Params.AddPair('access_token', 'ACCESS_TOKEN');
    Params.AddPair('x_api_key', 'X-API-KEY');
    Params.AddPair('is_production', TJSONBool.Create(False));

    Emitente := TIntegraEmitente.Create(Params);
    try
      Payload := TJSONObject.ParseJSONValue(
        '{' +
        '  "codigo_banco": "403"' +
        '}') as TJSONObject;
      try
        // Link de autorizacao da conta no banco (modo parceria, hoje so a Cora)
        ShowMessage(Emitente.Autorizacao(Payload));
      finally
        Payload.Free;
      end;
    finally
      Emitente.Free;
    end;
  finally
    Params.Free;
  end;
end;

end.
