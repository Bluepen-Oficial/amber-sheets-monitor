/**
 * Recebe atualizações enviadas pelo heartbeat.sh e atualiza uma linha por máquina.
 * Substitua o identificador abaixo pelo ID da sua planilha.
 */
function doGet(e) {
  const SHEET_ID = "COLE_AQUI_O_ID_DA_PLANILHA";

  const ss = SpreadsheetApp.openById(SHEET_ID);
  const aba = ss.getSheets()[0];

  const pc = e.parameter.pc || "";
  const hora = e.parameter.hora || "";
  const status = e.parameter.status || "";
  const cpu = e.parameter.cpu || "";
  const arquivo = e.parameter.arquivo || "";
  const tamanho = e.parameter.tamanho || "";

  const dados = aba.getDataRange().getValues();
  let linha = -1;

  for (let i = 1; i < dados.length; i++) {
    if (dados[i][0] == pc) {
      linha = i + 1;
      break;
    }
  }

  if (linha == -1) {
    linha = aba.getLastRow() + 1;
  }

  aba.getRange(linha, 1).setValue(pc);
  aba.getRange(linha, 2).setValue(hora);
  aba.getRange(linha, 3).setValue(status);
  aba.getRange(linha, 4).setValue(cpu);
  aba.getRange(linha, 5).setValue(arquivo);
  aba.getRange(linha, 6).setValue(tamanho);

  return ContentService.createTextOutput("OK");
}
