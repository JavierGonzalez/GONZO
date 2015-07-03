; ###################################
; #### III Concurso de Scripting ####
; ####  http://gonzo.teoriza.com ####
; ###################################

; #################################
; Lz elezeta[ arrob4]gmail[punt0 ]com
;Usar /cuentasilabas FICHERO.txt
alias silabas.lz {
  var %t = $ticks,%y = 1,%suma = 0
  window -nh @cuentasilabas-Lz
  loadbuf @cuentasilabas-Lz $1
  while (%y < $line(@cuentasilabas-Lz,0)) {
    inc %suma $lz.silabas($line(@cuentasilabas-Lz,%y))
    inc %y
  }
  window -c @cuentasilabas-Lz
  echo -a Lz: S�labas: %suma
  echo -a Lz: Tiempo: $calc($ticks - %t) $+ ms
}
alias -l lz.silabas {
  var %x = $1
  %x = $lower(%x)
  %x = $replace(%x,�,�,�,�,�,�,�,�,�,�)
  %x = $replace(%x,gui,gi,gue,ge,gu�,g�,gu�,g�,qui,ki,que,ke,qu�,k�,qu�,k�)
  %x = $remove(%x,�)
  %x = $replace(%x,ya,la,ye,le,yi,li,yo,lo,yu,lu)
  %x = $replace(%x,y,i,ua,a,ue,e,uo,o,ia,a,io,o,i�,e,u�,e,u�,o,u�,a,i�,a,iu,u,ei,i,oi,i,ai,i,i�,o,ui,i)
  %x = $replace(%x,i�i,i,i�i,i,i�i,i)
  %x = $replace(%x,ie,e,�o,ulo,�a,ula,�a,ila,eo,elo,�e,ile,�e,ule,�i,eli,�u,elu,eu,elu,�u,olu,ou,olu,�u,alu,au,alu,�i,ali,�i,eli,�i,oli,u�,uli,i�,ilu)
  %x = $replace(%x,�,a,�,e,�,i,�,o,�,u)
  %x = $calc($count(%x,a) + $count(%x,e) + $count(%x,i) + $count(%x,o) + $count(%x,u))
  return %x
}


; #################################
; GONZO gonzomail@gmail.com
alias silabas.gonzo {
  var %silabas.texto scripting-texto-silabas.txt
  var %tiempo $ticks
  var %silabas 0
  var %linea 1
  while (%linea <= $lines(%silabas.texto)) {
    var %palabra 1    
    while ($gettok($read(%silabas.texto,%linea),%palabra,32)) {
      var %letra 1
      while ($mid($gettok($read(%silabas.texto,%linea),%palabra,32),%letra,1)) { 
        if (($mid($gettok($read(%silabas.texto,%linea),%palabra,32),%letra,1) isin aeiou�����) && (($mid($gettok($read(%silabas.texto,%linea),%palabra,32),$calc(%letra - 1),1) !isin iu���) || (%letra == 1))) { inc %silabas | inc %frase.silabada }
        inc %letra
      }
      inc %palabra
    }
    echo 2 $read(%silabas.texto,%linea) %frase.silabada
    unset %frase.silabada
    inc %linea
  }
  echo 4 N�mero de s�labas:  %silabas $+ / $+ 729  Precisi�n:  $round($calc((100 * %silabas ) / 729),2) $+ %  en  $calc($ticks - %tiempo) $+ ms
}


; #################################
; Matyas santillanmatias@gmail.com                                                                                                                                                                                                                                                     
;Para cargar... /silabas
alias silabas { dialog -m silabas silabas }
;cuerpo principal!!!!
alias -l silaba1 {
  var %file = $sfile(c:)
  var %total = 0
  var %lineas = $calc($lines(%file) +1)
  var %a = 1
  while (%a != %lineas) {
    did -a Silabas 2 $read(%file,%a) - $+ $silaba2($read(%file,%a)) $+ -
    var %total = %total + $silaba2($read(%file,%a))
    inc %a
  }
  did -ra Silabas 5 %total
}
alias -l silaba2 {
  var %total = 0
  var %palabras = $calc($gettok($1-,0,32) +1)
  var %a = 1
  while (%a != %palabras) {
    var %total = %total + $silaba3($gettok($1-,%a,32))
    inc %a
  }
  return %total
}
alias -l silaba3 {
  if ($len($1) != 1) {
    var %total = $vocal($1) | var %a = 2 | var %b = $calc($len($1) +1)
    while (%a != %b) { if ($comprueba($right($left($1,%a),2))) { dec %total } | inc %a }
    return %total
  }
  else { return 1 }
}
;Funciones!!!!
alias -l vocal {
  var %vocales = 0 | var %a = 1
  while (%a != 11) { 
    var %vocales = %vocales + $findtok($tokn($1),$gettok(a e i o u á é í ó ú,%a,32),0,216) 
    inc %a 
  }
  return %vocales 
}
alias -l tokn { 
  var %palabra = $null | var %a = 1 | var %b = $calc($len($1) +1)
  while (%a != %b) { var %palabra = %palabra $+ $right($left($1,%a),1) $+ $chr(216) | inc %a }
  return $left(%palabra,-1) 
}
alias -l comprueba { 
  if (i isin $1) {
    var %a = 1 
    while (%a != 10) { 
      if ($gettok(a e o u á é í ó ú,%a,32) isin $1) { return $true }
      inc %a 
    }
    return $false
  }
  elseif (u isin $1) {
    var %a = 1 
    while (%a != 10) { 
      if ($gettok(a e i o á é í ó ú,%a,32) isin $1) { return $true } 
      inc %a 
    }
    return $false
  }
  else { return $false }
}
;estetico
dialog Silabas {
  title "III Concurso de Scripting: Contar sílabas"
  size -1 -1 221 88
  option dbu
  button "Aceptar", 1, 184 76 35 10, flat ok
  list 2, 1 3 218 58, size hsbar
  edit "", 3, 1 63 177 10, disable
  button "Archivo TXT", 6, 2 76 54 10, flat
  radio "Linea", 7, 57 76 54 10, flat push
  radio "Palabra", 8, 112 76 54 10, flat push disable
  button "!", 9, 180 63 10 10, flat
  edit "", 5, 192 62 27 10, read center
  button "?", 10, 169 76 10 10, flat
}
on *:dialog:silabas:sclick:*: {
  if ($did = 10) { if ($input(Autor: Matias Santillan $crlf Nick: Matyas,o,Acerca de)) { beep } }
  if ($did = 6) { silaba1 | did -u $dname 7,8 | did -b $dname 3 }
  if ($did = 7) { did -re $dname 3 | did -f $dname 3 }
  if ($did = 9) && ($did(7).state = 1) && ($did(3)) { did -r $dname 2 | did -a $dname 2 $did(3) - $+ $silaba3($did(3)) $+ - | did -ra $dname 5 $silaba3($did(3)) }
}


; #################################
; hyphen
; Sint�xis: /silabas <file.txt>
alias silabas.hyphen { 
  var %t1 = $ticks
  if (!$exists($1-)) var %err = $input(No existe el archivo,odw,Error)
  else { 
    var %c = 0 | .fopen f1 $1 | window -lh @silabas 200 200 200 400 | clear @silabas
    while (!$feof) { csilabas $fread(f1) }
    .fclose f1
    echo -s Total: $line(@silabas,0) s�labas
    window -c @silabas
  }
  echo -s $calc(($ticks - %t1)/1000) mseg
}
alias -l csilabas { 
  var %consonantes = b,c,d,f,g,h,j,k,l,m,n,�,p,q,r,s,t,v,w,x,y,z | var %svocales = a,e,i,o,u,�,�,�,�,� | var %wvocales = � | var %vocales = %svocales $+ , $+ %wvocales | var %letras = %vocales $+ , $+ %consonantes 
  var %i,%j,%n,%m,%g,%s
  %j = 1 | %s = $replace($1-,$chr(32),-,$chr(160),-,$chr(44),-,.,-,?,-,�,-) $+ - | %n = $len(%s) | %i = 1
  while (%i <= %n) {
    %g = 0
    if ($ca(%i,%s) isin %consonantes) {
      if ($ca($calc(%i + 1),%s) isin %vocales) {
        if ($ca($calc(%i - 1),%s) isin %vocales) %g = 1
      }
      elseif ($ca($calc(%i + 1),%s) isin %consonantes) && ($ca($calc(%i - 1),%s) isin %vocales) {
        if ($ca($calc(%i + 1),%s) isin r) {
          if ($ca(%i,%s) isin b c d f g k p r t v) %g = 1
          else %g = 2
        }
        elseif ($ca($calc(%i + 1),%s) isin t l) {
          if ($ca(%i,%s) isin b c d f g k l p t v) %g = 1
          else %g = 2
        }
        elseif ($ca($calc(%i + 1),%s) isin h) {
          if ($ca(%i,%s) isin c s p) %g = 1 
          else %g = 2
        }
        else %g = 2 
      }
    }
    elseif ($ca(%i,%s) isin %svocales) {
      if ($cal($calc(%i - 1),%s) isin %svocales) %g = 1
    }
    elseif ($ca(%i,%s) == -) { aline @silabas $mid(%s,%j,$calc(%i - %j)) | inc %i | %j = %i }
    if (%g == 1) { aline @silabas $mid(%s,%j,$calc(%i - %j)) | %j = %i }
    elseif (%g == 2) { inc %i | aline @silabas $mid(%s,%j,$calc(%i - %j)) | %j = %i }
    inc %i 
  }
}
alias -l ca { return $mid($2-,$1,1) }
