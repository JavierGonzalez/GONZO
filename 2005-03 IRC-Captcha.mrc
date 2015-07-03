; ############## Captcha IRC 1.0 ###############
; Creado por GONZO (Javier González)
; http://gonzo.teoriza.com - gonzomail@gmail.com
; /validar NICK ¿NUMERO_RAND?
; Detecta: Renderiza en modo texto un numero aleatorio 
; de forma ofuscada y con aleatorias fuentes con el 
; objetivo de comprobar si es humano.
;
; Tiene permiso para modificar y utilizar este código 
; como mejor le parezca siempre y cuando no lo
; publique como suyo. No tiene derecho a publicar 
; este programa sin hacer referencia a la unica fuente
; original que es http://gonzo.teoriza.com
;
; Creado en Marzo de 2005
; Publicado el 25 de Noviembre de 2007
; ##############################################


on 1:TEXT:*:?: {
  if (($1 == !validar) && (!$2) && (.irc-hispano.org isin $gettok($address,2,64))) { .timerVALIDAR 1 1 validar $nick }  
  var %validok = $readini(validaciones.ini,validaciones,$encode($lower($nick),m))
  if (($gettok(%validok,1,58) == $nick) && ($1 isnum) && ($gettok(%validok,2,58) == $1) && ($gettok($readini(validaciones.ini,validaciones,$encode($lower($nick),m)),5,58) != ok)) {
    ; ### Validacion OK ###
    msg $nick 3 Validado ok.  Gracias, que disfrutes.
    writeini validaciones.ini validaciones $encode($lower($nick),m) $nick $+ : $+ $gettok($readini(validaciones.ini,validaciones,$encode($lower($nick),m)),2,58) $+ : $+ $gettok($readini(validaciones.ini,validaciones,$encode($lower($nick),m)),3,58) $+ : $+ $gettok($readini(validaciones.ini,validaciones,$encode($lower($nick),m)),4,58) $+ : $+ ok $+ :
  }
  ; else { .timerVALIDAR 1 2 validar $nick }
}
alias validar {
  if ($1) {
    unset %linea.*
    set %mensaje 2 $+ Hola $1 $+ , si eres humano teclea este numero por favor.
    if (!$2) { var %codigo = $mid($rand(1,9) $+ $rand(1,9) $+ $rand(1,9) $+ $rand(1,9) $+ $rand(1,9) $+ $rand(1,9),1,$rand(4,4)) }
    else { var %codigo = $2 }
    set %tinta 1#0
    set %color 0,0
    var %caracter = $gettok($chr(36) $+ : $+ $chr(37) $+ : $+ $chr(35) $+ : $+ $chr(64),$rand(1,4),58)
    writeini validaciones.ini validaciones $encode($lower($1),m) $1 $+ : $+ %codigo $+ : $+ $ctime $+ : $+ $calc($gettok($readini(validaciones.ini,validaciones,$encode($lower($1),m)),4,58) + 1) $+ : $+ sinvalidar $+ :
    var %numero 1
    while ($mid(%codigo,%numero,1)) {
      set %espacio $mid(..........,1,$rand(1,4))
      var %fuente = $rand(1,$ini(fuentes.ini,0))
      var %linea 1
      while (%linea <= 10) {
        var %lalinea = $readini(fuentes.ini, $ini(fuentes.ini,%fuente),$mid(%codigo,%numero,1) $+ . $+ %linea)
        set %linea. [ $+ [ %linea ] ] %linea. [ $+ [ %linea ] ]  $+ %espacio $+ $replace($iif(!%lalinea,$mid(..........,1,$len($readini(fuentes.ini, $ini(fuentes.ini,%fuente),$mid(%codigo,%numero,1) $+ .1))),%lalinea),$chr(35),%tinta,.,$chr(35))
        inc %linea
      }
      inc %numero
    }
    unset %espacio
    ; msg $1 %color %linea.1 $+ %espacio,$chr(35),%tinta,.,$chr(35))
    msg $1 %mensaje
    msg $1 %color $+ $replace(%linea.1,.,$chr(35))
    msg $1 %color $+ $replace(%linea.2,.,$chr(35))
    msg $1 %color $+ $replace(%linea.3,.,$chr(35))
    msg $1 %color $+ $replace(%linea.4,.,$chr(35))
    msg $1 %color  $+ $replace(%linea.5,.,$chr(35))
    $iif( isin %linea.6, msg $1 %color $+ $replace(%linea.6,.,$chr(35)),$null)
    $iif( isin %linea.7, msg $1 %color $+ $replace(%linea.7,.,$chr(35)),$null)
    $iif( isin %linea.8, msg $1 %color $+ $replace(%linea.8,.,$chr(35)),$null)
    $iif( isin %linea.9, msg $1 %color $+ $replace(%linea.9,.,$chr(35)),$null)
    if (1 == $rand(0,1)) { msg $1 0,0 $+ $replace($strip(%linea.9),.,$chr(35)) }
  }
}
