unit SDKUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.JSON, BoletoUnit;

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
  Boleto: TIntegraBoleto;
begin
  Params := TJSONObject.Create;
  try
    Params.AddPair('access_token', 'ACCESS_TOKEN');
    Params.AddPair('x_api_key', 'X-API-KEY');
    Params.AddPair('secret_key', 'SECRET_KEY'); // 32 caracteres, pegar no cadastro da softhouse
    Params.AddPair('is_production', TJSONBool.Create(False));

    Boleto := TIntegraBoleto.Create(Params);
    try
      Payload := TJSONObject.ParseJSONValue(
        '{' +
        '  "codigo_banco": "364",' +
        '  "identificacao": "7",' +
        '  "motivo": "Cancelado pelo cliente"' +
        '}') as TJSONObject;
      try
        // O cancelamento e assincrono: guarde o evento_id da resposta para consultar o resultado
        ShowMessage(Boleto.CancelarBoleto(Payload));
      finally
        Payload.Free;
      end;
    finally
      Boleto.Free;
    end;
  finally
    Params.Free;
  end;
end;

end.
