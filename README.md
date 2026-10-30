# AMBER Simulation Monitor — Google Sheets

Monitoramento remoto e simplificado de simulações de **dinâmica molecular com AMBER** utilizando **Bash**, **Google Apps Script** e **Google Sheets**.

Este projeto foi desenvolvido durante uma pesquisa de iniciação científica para acompanhar, à distância, o estado de execução das simulações em estações de trabalho da instituição. A solução foi pensada para ambientes com **restrições de acesso remoto à rede**, desde que o computador que executa as simulações consiga fazer requisições HTTPS de saída ao Web App do Google Apps Script.

> **Importante:** este sistema não contorna políticas de rede nem concede acesso remoto ao computador. Ele apenas envia informações resumidas de execução para uma planilha acessível ao pesquisador.

## Como funciona

```text
Estação com AMBER
      │
      ▼
heartbeat_sheets.sh
      │  HTTPS (GET)
      ▼
Google Apps Script (Code.gs)
      │
      ▼
Google Sheets
      │
      ▼
Acompanhamento remoto pelo navegador
```

O script Bash verifica processos do AMBER e arquivos recentes e envia periodicamente os resultados a um Web App. O Apps Script recebe seis parâmetros e **atualiza a linha do computador** na planilha; não cria uma nova linha em cada verificação.

## Dados monitorados

| Coluna | Parâmetro | Significado |
| --- | --- | --- |
| A | `pc` | Nome do computador (`hostname -s`) |
| B | `hora` | Data e hora local da verificação |
| C | `status` | `EXECUTANDO` ou `PARADO` |
| D | `cpu` | Soma do percentual de CPU dos processos AMBER identificados |
| E | `arquivo` | Nome do arquivo de produção mais recentemente modificado |
| F | `tamanho` | Tamanho do arquivo encontrado |

O monitor procura primeiro `production*.out` e `*prod*.out`; na ausência desses arquivos, utiliza o `.nc` mais recente. O uso de CPU exibido **não é limitado a 100%** em máquinas multicore e não representa uso de GPU.

## Estrutura do repositório

```text
amber-sheets-monitor/
├── README.md
├── Code.gs
└── heartbeat_sheets.sh
```

## 1. Prepare a planilha

1. Crie uma planilha no Google Sheets.
2. Na primeira aba, insira os cabeçalhos na linha 1:

   `PC | Hora | Status | CPU | Arquivo | Tamanho`
3. Copie o **ID** da planilha, presente na URL entre `/d/` e `/edit`.

## 2. Configure o Google Apps Script

1. Na planilha, abra **Extensões → Apps Script**.
2. Cole o conteúdo de [`Code.gs`](Code.gs).
3. Substitua `COLE_AQUI_O_ID_DA_PLANILHA` pelo ID da sua planilha.
4. Publique como **Aplicativo da Web** pelo menu **Implantar → Nova implantação**.
5. Configure as permissões de execução e acesso de acordo com as políticas da instituição; copie a URL terminada em `/exec`.

> **Segurança:** o código original não autentica requisições. Se o Web App aceitar acesso público, qualquer pessoa que conheça a URL poderá enviar dados e alterar linhas da planilha. Evite divulgar essa URL, restrinja o acesso quando possível e não envie nomes de arquivos ou hostnames sensíveis. Para uso institucional, implemente autenticação e controles de acesso antes de disponibilizá-lo amplamente. O ID da planilha e a URL do Web App não devem ser publicados com valores reais.

## 3. Execute o monitor no computador de simulação

Requisitos: Linux ou ambiente compatível com Bash, `curl`, `find`, `sort`, `ps`, `pgrep`, `awk` e `du`. O uso de `find -printf` é específico do GNU find.

No diretório em que estão os arquivos da simulação:

```bash
chmod +x heartbeat_sheets.sh
export WEB_APP_URL="https://script.google.com/macros/s/SEU_DEPLOYMENT_ID/exec"
./heartbeat_sheets.sh
```

Por padrão, a atualização ocorre a cada **30 segundos**. Para configurar outro intervalo (mínimo de 5 segundos):

```bash
./heartbeat_sheets.sh 10
```

Para monitorar uma pasta diferente da atual:

```bash
./heartbeat_sheets.sh 30 /caminho/da/simulacao
```

Para interromper o monitor, pressione `Ctrl+C`.

## Exemplo de saída

```text
----------------------------------------
PC:       estacao-01
Hora:     2026-10-30 08:30:00
Status:   EXECUTANDO
CPU:      95.3%
Arquivo:  production_01.out
Tamanho:  28M
Google Sheets atualizado com sucesso.
```

*Os valores acima são apenas ilustrativos.*

## Limitações importantes

- `EXECUTANDO` significa que foi encontrado um processo compatível com `pmemd`, `pmemd.cuda` ou `sander` **na máquina**. Isso não garante que o processo esteja vinculado ao diretório monitorado ou que a simulação esteja progredindo corretamente.
- O script identifica processos de **dinâmica molecular AMBER**, não todas as ferramentas de análise (como `cpptraj` ou `MMPBSA.py`). Uma análise em execução pode aparecer como `PARADO`.
- O arquivo indicado é o mais recentemente modificado, sem verificar se pertence ao processo detectado.
- O campo `hora` reflete o relógio do computador monitorado, não o do servidor Google.
- As atualizações são feitas por `GET` e substituem o estado anterior da máquina: a planilha **não mantém histórico automático**.
- Para máquinas com o mesmo hostname, a linha será compartilhada.
- É necessário acesso **HTTPS de saída** ao serviço do Google Apps Script. Redes que bloqueiam esse tráfego não são compatíveis com esta configuração.
- A checagem de sucesso busca `OK` no corpo da resposta; para uso robusto, é recomendável adicionar verificação de status HTTP, timeout e autenticação.

## Contexto acadêmico

Ferramenta desenvolvida como apoio ao acompanhamento remoto das simulações de dinâmica molecular realizadas durante pesquisa PIBITI com a proteína vvMLP de *Vitis vinifera* e sua variante P68R. O monitor é um utilitário de acompanhamento operacional e não interfere diretamente nos cálculos moleculares.

## Uso e licença

Este repositório apresenta o código desenvolvido no contexto do projeto. **Nenhuma licença de reutilização foi definida neste exemplo.** Consulte os responsáveis pelo projeto antes de definir uma licença pública para o código e seus materiais.
