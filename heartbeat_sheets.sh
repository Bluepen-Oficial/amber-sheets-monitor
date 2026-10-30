#!/usr/bin/env bash

# Monitor de dinâmica molecular Amber com atualização do Google Sheets.
set -u

# Configure a variável de ambiente WEB_APP_URL ou substitua o texto abaixo.
WEB_APP_URL="${WEB_APP_URL:-COLE_AQUI_A_URL_DO_WEB_APP}"

INTERVALO="${1:-30}"
DIRETORIO="${2:-$PWD}"

if [[ "$WEB_APP_URL" == "COLE_AQUI_A_URL_DO_WEB_APP" ]]; then
    echo "ERRO: configure a URL do Google Apps Script."
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "ERRO: curl não está instalado."
    exit 1
fi

if ! [[ "$INTERVALO" =~ ^[0-9]+$ ]] || (( INTERVALO < 5 )); then
    echo "ERRO: intervalo mínimo de 5 segundos."
    exit 1
fi

if [[ ! -d "$DIRETORIO" ]]; then
    echo "ERRO: diretório não encontrado: $DIRETORIO"
    exit 1
fi

PC="$(hostname -s)"

arquivo_recente() {
    local f
    f="$(find "$DIRETORIO" -type f \
        \( -name 'production*.out' -o -name '*prod*.out' \) \
        -printf '%T@ %p\n' 2>/dev/null |
        sort -nr | head -n 1 | cut -d' ' -f2-)"

    if [[ -z "$f" ]]; then
        f="$(find "$DIRETORIO" -type f -name '*.nc' \
            -printf '%T@ %p\n' 2>/dev/null |
            sort -nr | head -n 1 | cut -d' ' -f2-)"
    fi
    printf '%s' "${f:-Nenhum arquivo encontrado}"
}

cpu_amber() {
    ps -eo comm=,pcpu= 2>/dev/null |
        awk '$1 ~ /^(pmemd|pmemd\.cuda|sander)(\.MPI)?$/ {
            s += $2
            achou=1
        }
        END {
            if (achou)
                printf "%.1f%%", s
            else
                printf "0.0%%"
        }'
}

while true; do
    HORA="$(date '+%Y-%m-%d %H:%M:%S')"
    ARQUIVO="$(arquivo_recente)"
    CPU="$(cpu_amber)"

    if pgrep -f '(^|/)(pmemd(\.cuda)?|sander)(\.MPI)?([[:space:]]|$)' \
        >/dev/null 2>&1; then
        STATUS="EXECUTANDO"
    else
        STATUS="PARADO"
    fi

    if [[ "$ARQUIVO" != "Nenhum arquivo encontrado" && -f "$ARQUIVO" ]]; then
        TAMANHO="$(du -h "$ARQUIVO" 2>/dev/null | awk '{print $1}')"
        [[ -n "$TAMANHO" ]] || TAMANHO="indisponível"
        ARQUIVO="$(basename "$ARQUIVO")"
    else
        TAMANHO="0"
    fi

    echo "----------------------------------------"
    echo "PC:       $PC"
    echo "Hora:     $HORA"
    echo "Status:   $STATUS"
    echo "CPU:      $CPU"
    echo "Arquivo:  $ARQUIVO"
    echo "Tamanho:  $TAMANHO"

    RESPOSTA="$(curl -sS -L --get "$WEB_APP_URL" \
        --data-urlencode "pc=$PC" \
        --data-urlencode "hora=$HORA" \
        --data-urlencode "status=$STATUS" \
        --data-urlencode "cpu=$CPU" \
        --data-urlencode "arquivo=$ARQUIVO" \
        --data-urlencode "tamanho=$TAMANHO" 2>&1)"

    if [[ "$RESPOSTA" == *"OK"* ]]; then
        echo "Google Sheets atualizado com sucesso."
    else
        echo "Falha no envio: $RESPOSTA"
    fi

    sleep "$INTERVALO"
done
