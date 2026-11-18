unit CryptoUnit;

{$A8}

interface

uses
  Winapi.Windows, System.SysUtils, System.NetEncoding, System.Hash, System.JSON, UtilUnit;

type
  ECryptoException = class(Exception);

  TIntegraCrypto = class
  private
    class function KeyBytes(const Key: string): TBytes;
    class function Cipher(const Key, IV, Input: TBytes; var Tag: TBytes; Encrypting: Boolean): TBytes;
  public
    class function Encrypt(const PlainText, Key: string): string;
    class function Decrypt(const Payload, Key: string): string;
    class function Hash(const Payload: TJSONObject): string;
    class function FormatValor(const Valor: Double): string;
  end;

implementation

const
  BCRYPT_DLL = 'bcrypt.dll';
  GCM_IV_LEN = 12;
  GCM_TAG_LEN = 16;
  BCRYPT_USE_SYSTEM_PREFERRED_RNG = $00000002;
  BCRYPT_AUTH_MODE_INFO_VERSION = 1;
  STATUS_AUTH_TAG_MISMATCH = $C000A002;

type
  NTSTATUS = LongInt;
  BCRYPT_HANDLE = Pointer;

  // BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO; precisa do alinhamento natural ({$A8}) para bater com o C
  TBCryptAuthInfo = record
    cbSize: ULONG;
    dwInfoVersion: ULONG;
    pbNonce: PByte;
    cbNonce: ULONG;
    pbAuthData: PByte;
    cbAuthData: ULONG;
    pbTag: PByte;
    cbTag: ULONG;
    pbMacContext: PByte;
    cbMacContext: ULONG;
    cbAAD: ULONG;
    cbData: UInt64;
    dwFlags: ULONG;
  end;

function BCryptOpenAlgorithmProvider(out phAlgorithm: BCRYPT_HANDLE; pszAlgId, pszImplementation: PWideChar; dwFlags: ULONG): NTSTATUS; stdcall; external BCRYPT_DLL;
function BCryptCloseAlgorithmProvider(hAlgorithm: BCRYPT_HANDLE; dwFlags: ULONG): NTSTATUS; stdcall; external BCRYPT_DLL;
function BCryptSetProperty(hObject: BCRYPT_HANDLE; pszProperty: PWideChar; pbInput: PByte; cbInput, dwFlags: ULONG): NTSTATUS; stdcall; external BCRYPT_DLL;
function BCryptGenerateSymmetricKey(hAlgorithm: BCRYPT_HANDLE; out phKey: BCRYPT_HANDLE; pbKeyObject: PByte; cbKeyObject: ULONG; pbSecret: PByte; cbSecret, dwFlags: ULONG): NTSTATUS; stdcall; external BCRYPT_DLL;
function BCryptDestroyKey(hKey: BCRYPT_HANDLE): NTSTATUS; stdcall; external BCRYPT_DLL;
function BCryptEncrypt(hKey: BCRYPT_HANDLE; pbInput: PByte; cbInput: ULONG; pPaddingInfo: Pointer; pbIV: PByte; cbIV: ULONG; pbOutput: PByte; cbOutput: ULONG; out pcbResult: ULONG; dwFlags: ULONG): NTSTATUS; stdcall; external BCRYPT_DLL;
function BCryptDecrypt(hKey: BCRYPT_HANDLE; pbInput: PByte; cbInput: ULONG; pPaddingInfo: Pointer; pbIV: PByte; cbIV: ULONG; pbOutput: PByte; cbOutput: ULONG; out pcbResult: ULONG; dwFlags: ULONG): NTSTATUS; stdcall; external BCRYPT_DLL;
function BCryptGenRandom(hAlgorithm: BCRYPT_HANDLE; pbBuffer: PByte; cbBuffer, dwFlags: ULONG): NTSTATUS; stdcall; external BCRYPT_DLL;

procedure Check(Status: NTSTATUS; const Step: string);
begin
  if Status = 0 then
    Exit;

  if Cardinal(Status) = STATUS_AUTH_TAG_MISMATCH then
    raise ECryptoException.Create(TIntegraUtil.ErrorText('Decriptação falhou. Chave inválida ou dados adulterados.'));

  raise ECryptoException.Create(TIntegraUtil.ErrorText(Format('Falha na criptografia (%s): NTSTATUS $%.8x', [Step, Cardinal(Status)])));
end;

function NewBase64: TBase64Encoding;
begin
  // CharsPerLine = 0: sem quebra de linha a cada 76 caracteres, que o base64_decode estrito do servidor recusa
  Result := TBase64Encoding.Create(0);
end;

{ TIntegraCrypto }

class function TIntegraCrypto.KeyBytes(const Key: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(Key);
  if Length(Result) <> 32 then
    raise ECryptoException.Create(TIntegraUtil.ErrorText(Format('O campo secret_key deve ter exatamente 32 caracteres, pegar no cadastro da softhouse. Recebido: %d.', [Length(Result)])));
end;

class function TIntegraCrypto.Cipher(const Key, IV, Input: TBytes; var Tag: TBytes; Encrypting: Boolean): TBytes;
var
  Alg, HKey: BCRYPT_HANDLE;
  Info: TBCryptAuthInfo;
  Mode: string;
  Len: ULONG;
begin
  Mode := 'ChainingModeGCM';
  Check(BCryptOpenAlgorithmProvider(Alg, 'AES', nil, 0), 'BCryptOpenAlgorithmProvider');
  try
    Check(BCryptSetProperty(Alg, 'ChainingMode', PByte(PWideChar(Mode)), (Length(Mode) + 1) * SizeOf(WideChar), 0), 'BCryptSetProperty');
    Check(BCryptGenerateSymmetricKey(Alg, HKey, nil, 0, @Key[0], Length(Key), 0), 'BCryptGenerateSymmetricKey');
    try
      FillChar(Info, SizeOf(Info), 0);
      Info.cbSize := SizeOf(Info);
      Info.dwInfoVersion := BCRYPT_AUTH_MODE_INFO_VERSION;
      Info.pbNonce := @IV[0];
      Info.cbNonce := Length(IV);
      Info.pbTag := @Tag[0];
      Info.cbTag := Length(Tag);

      SetLength(Result, Length(Input));
      Len := 0;
      if Encrypting then
        Check(BCryptEncrypt(HKey, PByte(Input), Length(Input), @Info, nil, 0, PByte(Result), Length(Result), Len, 0), 'BCryptEncrypt')
      else
        Check(BCryptDecrypt(HKey, PByte(Input), Length(Input), @Info, nil, 0, PByte(Result), Length(Result), Len, 0), 'BCryptDecrypt');
      SetLength(Result, Len);
    finally
      BCryptDestroyKey(HKey);
    end;
  finally
    BCryptCloseAlgorithmProvider(Alg, 0);
  end;
end;

class function TIntegraCrypto.Encrypt(const PlainText, Key: string): string;
var
  K, IV, Tag, Data: TBytes;
  B64: TBase64Encoding;
begin
  K := KeyBytes(Key);
  SetLength(IV, GCM_IV_LEN);
  Check(BCryptGenRandom(nil, @IV[0], GCM_IV_LEN, BCRYPT_USE_SYSTEM_PREFERRED_RNG), 'BCryptGenRandom');
  SetLength(Tag, GCM_TAG_LEN);
  Data := Cipher(K, IV, TEncoding.UTF8.GetBytes(PlainText), Tag, True);

  B64 := NewBase64;
  try
    Result := B64.EncodeBytesToString(IV + Tag + Data);
  finally
    B64.Free;
  end;
end;

class function TIntegraCrypto.Decrypt(const Payload, Key: string): string;
var
  K, Raw, IV, Tag, Data: TBytes;
  B64: TBase64Encoding;
begin
  K := KeyBytes(Key);
  B64 := NewBase64;
  try
    Raw := B64.DecodeStringToBytes(Payload);
  finally
    B64.Free;
  end;

  if Length(Raw) < GCM_IV_LEN + GCM_TAG_LEN then
    raise ECryptoException.Create(TIntegraUtil.ErrorText(Format('Comprimento do payload inválido: %d bytes.', [Length(Raw)])));

  IV := Copy(Raw, 0, GCM_IV_LEN);
  Tag := Copy(Raw, GCM_IV_LEN, GCM_TAG_LEN);
  Data := Copy(Raw, GCM_IV_LEN + GCM_TAG_LEN, MaxInt);
  Result := TEncoding.UTF8.GetString(Cipher(K, IV, Data, Tag, False));
end;

class function TIntegraCrypto.FormatValor(const Valor: Double): string;
begin
  // Mesmo texto do (float) interpolado no PHP (precision=14): 10.50 -> "10.5", 1.00 -> "1"; sempre com ponto
  Result := FloatToStrF(Valor, ffGeneral, 14, 0, TIntegraUtil.PontoDecimal);
end;

class function TIntegraCrypto.Hash(const Payload: TJSONObject): string;
var
  Doc, ValorStr: string;
  Valor: Double;
begin
  Doc := TIntegraUtil.JsonStr(Payload, 'pagador.cnpj');
  if Doc = '' then
    Doc := TIntegraUtil.JsonStr(Payload, 'pagador.cpf');

  ValorStr := TIntegraUtil.JsonStr(Payload, 'pagamento.valor');
  if not TryStrToFloat(ValorStr, Valor, TIntegraUtil.PontoDecimal) or (Valor <= 0) then
    raise ECryptoException.Create(TIntegraUtil.ErrorText('pagamento.valor deve ser informado, maior que zero e com ponto como separador decimal!', Payload));

  Result := LowerCase(THashSHA2.GetHashString(
    TIntegraUtil.JsonStr(Payload, 'identificacao') + '|' +
    Doc + '|' +
    FormatValor(Valor) + '|' +
    TIntegraUtil.JsonStr(Payload, 'pagamento.data_vencimento')));
end;

end.
