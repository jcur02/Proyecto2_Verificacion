set term pngcairo size 1280,720
set output "bw_por_terminal.png"

set style data histograms
set style fill solid 1.0 border -1
set boxwidth 0.8

set xlabel "Terminal destino"
set ylabel "BW promedio (bits / 1000 ciclos)"
set title "Ancho de banda promedio por terminal destino"

set grid ytics

# Columna 1: terminal, columna 2: BW
plot "bw_por_terminal.dat" using 2:xtic(1) title "BW promedio"

unset output
quit

