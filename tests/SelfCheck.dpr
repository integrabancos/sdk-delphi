program SelfCheck;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.JSON,
  UtilUnit in '..\src\UtilUnit.pas',
  CryptoUnit in '..\src\CryptoUnit.pas';

// Vetores gerados com o PayloadCrypt/Crypto da api_banco (PHP), sem rede.
const
  KEY = '12345678901234567890123456789012';
  PHP_PAYLOAD = 'NmWoN/neR3eYUoerwga+kmkK7uaHHSli3nrmc+WzxdKbT5intebEgBXUeTRbFg==';
  PHP_PLAIN = '{"teste":"ação"}';

var
  Falhas: Integer = 0;

procedure Check(Ok: Boolean; const Msg: string);
begin
  if Ok then
    Writeln('ok    - ', Msg)
  else
  begin
    Writeln('FALHA - ', Msg);
    Inc(Falhas);
  end;
end;

function Raises(Proc: TProc): Boolean;
begin
  Result := False;
  try
    Proc;
  except
    Result := True;
  end;
end;

procedure CheckHash(const Valor, Esperado: string);
var
  Payload: TJSONObject;
begin
  Payload := TJSONObject.ParseJSONValue(
    '{"identificacao":"7","pagador":{"cpf":"01234567890","cnpj":null},' +
    '"pagamento":{"valor":' + Valor + ',"data_vencimento":"2026-05-30"}}') as TJSONObject;
  try
    Check(TIntegraCrypto.Hash(Payload) = Esperado, 'hash com valor ' + Valor);
  finally
    Payload.Free;
  end;
end;

procedure Run;
var
  Payload: TJSONObject;
  Enc: string;
begin
  // Locale com vírgula decimal (pt-BR) não pode mudar o hash
  FormatSettings.DecimalSeparator := ',';
  FormatSettings.ThousandSeparator := '.';

  CheckHash('"1"', 'bef0d02358175b8165a6e64a41aea1c2f8d7934f20059bf19872781a2c0ea592');
  CheckHash('"5.00"', '8c2e1b8b663b2a778ac0d62a0633d890e53b636662820f01f78205221d5661b3');
  CheckHash('"10.50"', '8b7c8e5f5bd2a85eee566ffc808bc29ae830335cf5a8917b812455028f584757');
  CheckHash('"1234.5"', '49d51521d0b58a30483f8c973a34ca9247c5740cab8d0c71f3bba01443ae1b25');
  CheckHash('"0.1"', '4e5481220ff864f175701ba71d2037de5eaa92f3d5b94e80c19f148900a33a8f');
  CheckHash('"99999999.99"', '30318e7bb67c056209a20dacf7a71da47de93eb839339b2a0dba0fdf5ca2991c');
  CheckHash('1.25', 'c10aef7bcec3ab557e6ffde98991ab605e89c52009349fbba776e6bbcb4ba199');

  Payload := TJSONObject.ParseJSONValue('{"identificacao":"8","pagador":{"cnpj":"44354598000192","cpf":"01234567890"},"pagamento":{"valor":"1"}}') as TJSONObject;
  try
    Check(TIntegraCrypto.Hash(Payload) = '0bf6160442361cc8df7474d8fceba2c3de77ac795cec8b57604201a80c40d126', 'hash com cnpj e sem vencimento');
  finally
    Payload.Free;
  end;

  Payload := TJSONObject.ParseJSONValue('{"identificacao":"7","pagamento":{"valor":"10,50"}}') as TJSONObject;
  try
    Check(Raises(procedure begin TIntegraCrypto.Hash(Payload) end), 'valor com vírgula é recusado');
  finally
    Payload.Free;
  end;

  Check(TIntegraCrypto.Decrypt(PHP_PAYLOAD, KEY) = PHP_PLAIN, 'decripta payload gerado pelo PHP');

  Enc := TIntegraCrypto.Encrypt(PHP_PLAIN, KEY);
  Check(TIntegraCrypto.Decrypt(Enc, KEY) = PHP_PLAIN, 'encripta e decripta (ida e volta)');
  Check(Pos(#10, Enc) = 0, 'base64 sem quebra de linha');
  Check(Enc <> TIntegraCrypto.Encrypt(PHP_PLAIN, KEY), 'IV aleatório a cada chamada');
  Check(Raises(procedure begin TIntegraCrypto.Decrypt(PHP_PAYLOAD, 'abcdefghijabcdefghijabcdefghij12') end), 'chave errada é recusada');
  Check(Raises(procedure begin TIntegraCrypto.Encrypt('x', 'curta') end), 'chave fora de 32 bytes é recusada');

  Check(TIntegraUtil.EncodeSegment('a b/ç') = 'a%20b%2F%C3%A7', 'codifica segmento da URL');
end;

begin
  try
    Run;
  except
    on E: Exception do
    begin
      Writeln('ERRO - ', E.ClassName, ': ', E.Message);
      Inc(Falhas);
    end;
  end;

  Writeln;
  if Falhas = 0 then
    Writeln('Tudo certo.')
  else
    Writeln(Falhas, ' falha(s).');
  ExitCode := Falhas;
end.
