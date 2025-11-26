set terminal pngcairo size 1280,720
set output "retardo_promedio_por_terminal.png"

set datafile separator ","
set xlabel "Terminal destino"
set ylabel "Retardo promedio (ciclos)"
set title "Retardo promedio por terminal"

plot "reporte_paquetes.csv" using 3:7 smooth unique with linespoints title "Delay promedio"

unset output
quit
