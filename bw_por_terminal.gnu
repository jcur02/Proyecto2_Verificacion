set datafile separator ","

PCK_SZ = 40.0   # bits por paquete

# Vamos a escribir (terminal_dst, BW_promedio_bits_por_ciclo)
set print "bw_por_terminal.dat"

do for [term=0:15] {
    # stats sobre t_recibo (col 6) SOLO de las filas donde terminal_dst == term
    # every ::1 -> saltar la primera línea (encabezado)
    stats "reporte_paquetes.csv" \
          using ( (int(column(3)) == term) ? column(6) : 1/0 ) \
          every ::1 nooutput

    n = STATS_records
    if (n > 1) {
        dur = STATS_max - STATS_min      # ventana de tiempo entre primer y último paquete
        if (dur > 0) {
            bw = (n * PCK_SZ) / dur      # bits por unidad de tiempo (≈ bits/ciclo)
            # Escalamos para que se vea más "grande", por ejemplo bits por 1000 ciclos:
            bw_scaled = bw * 1000.0
            print term, bw_scaled
        }
    }
}

set print
quit

