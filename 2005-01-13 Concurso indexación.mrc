; ############################################################################################
; Nick: GONZO - Email: gonzomail@gmail.com
alias indexar1 {
  ; Indexa el directorio c:\windows\help entero, guardando los datos:
  ; $findfile(%index.ruta,*,N) <--- ruta
  ; $file($findfile(%index.ruta,*,N)).size <--- tamaño
  ; $file($findfile(%index.ruta,*,N)).ctime <--- tiempo
  var %index.ruta = c:\mIRC
  var %t $ticks
  remove index.rutas.txt
  remove index.size.txt
  remove index.tiempo.txt
  echo 2  Indexando: %index.ruta
  var %index 1
  var %archivo = $findfile(%index.ruta,*,1)
  while (%archivo) {
    write index.rutas.txt %archivo
    write index.size.txt $file(%archivo).size
    write index.tiempo.txt $file(%archivo).ctime
    var %archivo = $findfile(%index.ruta,*,%index)
    inc %index
  }
  echo 2  %index archivos indexados en $calc(($ticks - %t)/1000) $+ s
}
alias buscar1 {
  if (($1 == ruta) && ($2) && (!$3)) { 
    var %t = $ticks
    ; Busca por ruta. ISIN
    echo 2  Busqueda por $1 $+ :  $2
    var %index 1
    var %ruta = $read(index.rutas.txt,%index)
    while (%ruta) {
      if ($2 isin %ruta) { echo 12 Busqueda> %ruta - $read(index.size.txt,%index) $+ Bytes - $asctime($read(index.tiempo.txt,%index)) }
      var %ruta = $read(index.rutas.txt,%index)
      inc %index
    }
  }
  elseif (($1 == tamaño) && ($2 isnum) && (!$3)) {
    var %t = $ticks
    ; Busca por tamaño. IF
    echo 2  Busqueda por $1 $+ :  $2
    var %index 1
    var %ruta = $read(index.size.txt,%index)
    while (%ruta) {
      if ($2 == %ruta) { echo 12 Busqueda> $read(index.rutas.txt,%index) - %ruta $+ Bytes  - $asctime($read(index.tiempo.txt,%index)) }
      var %ruta = $read(index.size.txt,%index)
      inc %index
    }
  }
  elseif (($1 == tiempo) && ($2 isnum) && ($len($2) == 9) && (!$3)) {
    var %t = $ticks
    ; Busca por tiempo. IF
    echo 2  Busqueda por $1 $+ :  $2
    var %index 1
    var %ruta = $read(index.tiempo.txt,%index)
    while (%ruta) {
      if ($2 == %ruta) { echo 12 Busqueda> $read(index.rutas.txt,%index) - $read(index.size.txt,%index) $+ Bytes  - $asctime(%ruta) }
      var %ruta = $read(index.tiempo.txt,%index)
      inc %index
    }
  }
  echo 2  Busqueda realizada en %index archivos  $calc(($ticks - %t)/1000) $+ s
}
alias desindexar1 {   remove index.rutas.txt | remove index.size.txt | remove index.tiempo.txt  }
