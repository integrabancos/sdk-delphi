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
        '  "numero": "5",' +
        '  "codigo_banco": "364",' +
        '  "identificacao": "7",' +
        '  "pagamento": {' +
        '    "valor": "10.50",' +
        '    "data_vencimento": "2026-12-30",' +
        '    "descricao": "Mensalidade"' +
        '  },' +
        '  "pagador": {' +
        '    "cpf": "01234567890",' +
        '    "cnpj": null,' +
        '    "nome": "Cliente Teste",' +
        '    "endereco": {' +
        '      "logradouro": "Rodovia BR-277",' +
        '      "numero": "592",' +
        '      "bairro": "Parque Sao Paulo",' +
        '      "nome_municipio": "Francisco Beltrao",' +
        '      "uf": "PR",' +
        '      "cep": "85601000"' +
        '    }' +
        '  }' +
        '}') as TJSONObject;
      try
        // Use ponto como separador decimal em pagamento.valor
        ShowMessage(Boleto.GerarBoleto(Payload));
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
