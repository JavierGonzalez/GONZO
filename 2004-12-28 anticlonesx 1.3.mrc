; ################# anticlonesx #################
; Creado por GONZO
; http://gonzo.teoriza.com - gonzomail@gmail.com
; /anticlonesx  -  Activa o desactiva
; Detecta: ClonesX en todas sus formas y versiones.
; 
; En caso de detección de ataque se bloqueara el
; canal con +RM durante 60 segundos y los baneara.
; Añadido un protector de querys masivos que pondra
; +R durante 120 segundos si abren 10 o mas querys 
; en 3 o menos segundos.
;
; Tiene permiso para modificar y utilizar este código 
; como mejor le parezca siempre y cuando no lo
; publique como suyo. No tiene derecho a publicar 
; este programa sin hacer referencia a la unica fuente
; original que es http://gonzo.teoriza.com
; ##############################################

on *:JOIN:*: {
  if (%anticlonesx.estado == on) {
    var %anticlonesx.identd $gettok($right($address($nick,0),-2),1,64)
    if ((($nick != %anticlonesx.identd) && ($left($right($address,15),1) == $chr(46)) && ($left(%anticlonesx.identd,5) != webch)) || (%anticlonesx.identd != javachat)) {
      if ((%anticlonesx.identd === w) && ($left($nick,1) === w) && ($right($nick,6) isnum) && ($len($nick) == 7)) { halt }
      if (($left(%anticlonesx.identd,1) isalpha) && ($left(%anticlonesx.identd,1) islower) && ($right(%anticlonesx.identd,$calc($len(%anticlonesx.identd) - 1)) isnum) && ($len(%anticlonesx.identd) <= 5)) { 
        inc %anticlonesx.clon 1 | set %anticlonesx.ataque 1 ClonesX
      }
      elseif ((%anticlonesx.identd isalpha) && (%anticlonesx.identd islower) && ($nick isalpha) && ($nick islower) && ($len($nick) >= 12) && ($len(%anticlonesx.identd) >= 4)) { 
        inc %anticlonesx.clon 1
        set %anticlonesx.ataque 8 ClonesX modificado2
      }
      elseif (($left($nick,1) isalpha) && ($left($nick,1) islower) && ($right($nick,$calc($len($nick) - 1)) isnum) && (($len($nick) == 4) || ($len($nick) == 5))) { inc %anticlonesx.clon 1 | set %anticlonesx.ataque 2 ClonesX }
      elseif ((%anticlonesx.identd !isnum) && (%anticlonesx.identd === $left($nick,$len(%anticlonesx.identd))) && ($right($nick, - $+ $len(%anticlonesx.identd)) isnum) && ($len($right($nick, - $+ $len(%anticlonesx.identd))) > 2)) { 
        if (%anticlonesx.inick == %anticlonesx.identd) { inc %anticlonesx.clon 1 | set %anticlonesx.ataque 4 ClonesX }
        else { set -u3 %anticlonesx.inick %anticlonesx.identd }
      }
      elseif (($right($nick,4) islower) && ($right($nick,4) isalpha) && ($len($nick) >= 6)) { 
        if (%anticlonesx.identd === %anticlonesx.identd.anterior) {
          inc %anticlonesx.clon 1
          set %anticlonesx.ataque 7 ClonesX identd personalizada 
        }
        else { set -u3 %anticlonesx.identd.anterior %anticlonesx.identd }
      }
      else { unset %anticlonesx.clon }
      if (%anticlonesx.clon isnum) { 
        echo -s  [ $+ %anticlonesx.clon $+ ] Positivo en $chan  12 $nick $+ ! $+ $address 14 ( $+ $ctime v $+ $readini(anticlonesx.mrc, anticlones, version) %anticlonesx.numeroclones %anticlonesx.hosts %anticlonesx.ataque $+ )
      }
      if ((%anticlonesx.clon >= %anticlonesx.numeroclones) && (%anticlonesx.mass == $chan)) {
        flash CLONES
        .timerATAQUE 1 1 echo 4   [!]  Ataque de clones en $chan   12 $nick $+ ! $+ $address
        if ($me isop $chan) { 
          inc %anticlonesx.clones 1
          if (%anticlonesx.extra != off) {
            if (($right($nick,2) isnum) && ($len($nick) > 5) && ($left($nick,-4) !isnum)) { 
              set %anticlonesx.ban $iif($right($nick,4) isnum,$left($nick,-4),$left($nick,-3)) $+ *!*@* 
              mode # +RMb %anticlonesx.ban
              set %anticlonesx.ataque.nicks  + nicks: $iif($right($nick,4) isnum,$left($nick,-4),$left($nick,-3)) $+ *
            } 
            else { mode # +RM }
            set %anticlonesx.extra off 
          }
          if ($gettok($address($nick,0),2,64) !isin %anticlonesx.cadahost) {
            set %anticlonesx.cadahost %anticlonesx.cadahost $gettok($address($nick,0),2,64)
            set %anticlonesx.ac b $+ %anticlonesx.ac *!*@ $+ $gettok($address($nick,0),2,64) 
            inc %anticlonesx.hosts 1
            inc %anticlonesx.num 1
            .timerABAN 1 1 ac.banea $chan $chr(43) $+ %anticlonesx.ac
            if (%anticlonesx.num == 6) { .timerABAN off | mode # $chr(43) $+ %anticlonesx.ac | unset %anticlonesx.ac | unset %anticlonesx.num }
          }
          .timerFIN 1 60 ac.fin $chan
        }
      }
      set -u3 %anticlonesx.mass $chan
    }
  }
}
on *:OPEN:?:*: {
  if (%anticlonesx.estado == on) {
    if ((%anticlonesx.query.limite != 0) && (%anticlonesx.query == %anticlonesx.query.limite)) {
      mode $me +R
      echo 4 [!] 2 Ataque de clones por query detectado. %anticlonesx.query.limite querys abiertos en menos de 2 segundos. +R activado durante 180s.
      .timerAC.QQ 1 180 mode $me -R 
    }
    set -u3 %anticlonesx.query $calc(%anticlonesx.query + 1)
  }
}
ctcp 1:anticlones:*: { .timerAC.CTCP 1 2 .quote NOTICE $nick :ANTICLONES anticlonesx - Version: $readini(%anticlonesx.dir, anticlonesx, version) - Estado: $iif(%anticlonesx.estado == on, ACTIVADO, DESACTIVADO) - Bloqueos: %anticlonesx.exito }
on *:LOAD: {
  set %anticlonesx.dir $script
  set %anticlonesx.estado on
  set %anticlonesx.query.limite 8
  set %anticlonesx.numeroclones 3
  echo 2 
  echo 2 2 [?] anticlones: $iif(%anticlonesx.estado == on, 3ACTIVADO, 4DESACTIVADO) 2 version:12  $+ $readini(%anticlonesx.dir, anticlonesx, version) $+ .2 Con  /anticlonesx  se activa o desactiva.
  echo 2 
}
on *:UNLOAD: {
  echo 2 
  echo 2 2 [?] anticlones3  $+ $readini(%anticlonesx.dir, anticlonesx, version) $+  2DESinstalado correctamente.
  echo 2 
  unset %anticlonesx.*
}
alias ac.fin {
  mode $1 -RM
  msg $1 2  [!] 2Ataque a $1 bloqueado. v $+ $readini(%anticlonesx.dir, anticlonesx, version) 12 Clones: $calc(%anticlonesx.clones + (%anticlonesx.numeroclones - 1))  Hosts: %anticlonesx.hosts  Tipo: %anticlonesx.ataque %anticlonesx.ataque.nicks - 2Addon Anticonesx by: http://gonzo.teoriza.com
  inc %anticlonesx.exito 1
  unset %anticlonesx.ac
  unset %anticlonesx.num
  unset %anticlonesx.ataque
  unset %anticlonesx.clones
  unset %anticlonesx.hosts
  unset %anticlonesx.ataque.nicks
  unset %anticlonesx.mass
  unset %anticlonesx.extra
  unset %anticlonesx.clon
  unset %anticlonesx.cadahost
}
alias ac.banea {
  mode $1-
  unset %anticlonesx.ac
  unset %anticlonesx.num
}
alias anticlonesx {
  if (%anticlonesx.estado == on) {
    echo 2   [?] Anticlones esta ahora:4 DESACTIVADO
    .timerABAN off
    .timerFIN off
    set %anticlonesx.estado off
    unset %anticlonesx.ac
    unset %anticlonesx.num
    unset %anticlonesx.ataque
    unset %anticlonesx.clones
    unset %anticlonesx.hosts
    unset %anticlonesx.ataque.nicks
    unset %anticlonesx.mass
    unset %anticlonesx.extra
    unset %anticlonesx.clon
    unset %anticlonesx.cadahost
  }
  else {
    echo 2   [?] Anticlones esta ahora:3 ACTIVADO
    set %anticlonesx.estado on
  }
}
[anticlonesx]
autor=GONZO
email=gonzomail@gmail.com
web=http://gonzo.teoriza.com
version=1.3
fecha=11/07/2006
fechacreacion=28/12/2004
descripcion=Detecta ataques de clones de tipo ClonesX en todas sus versiones y algunos mas, sella el canal durante 60 segundos y banea los host. A�adido un antiquerys masivos.
instalacion=Copiar anticlonesx.ini al raiz del mIRC y cargar ejecutando /load 
