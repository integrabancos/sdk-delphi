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
    Params.AddPair('is_production', TJSONBool.Create(False));

    Emitente := TIntegraEmitente.Create(Params);
    try
      Payload := TJSONObject.ParseJSONValue(
        '{' +
        '  "nome": "EMPRESA TESTE",' +
        '  "razao": "EMPRESA TESTE",' +
        '  "cnpj": "44354598000192",' +
        '  "telefone": "46998895532",' +
        '  "email": "empresa@teste.com",' +
        '  "rua": "TESTE",' +
        '  "numero": "1",' +
        '  "complemento": "NENHUM",' +
        '  "bairro": "TESTE",' +
        '  "nome_municipio": "CIDADE TESTE",' +
        '  "codigo_municipio": "4108403",' +
        '  "uf": "PR",' +
        '  "cep": "85601000"' +
        '}') as TJSONObject;
      try
        // O x_api_key do emitente volta no campo "token" da resposta
        ShowMessage(Emitente.Cria(Payload));
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
