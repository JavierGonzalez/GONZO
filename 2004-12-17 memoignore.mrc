; ############## memoignore ##############
; Programado por GONZO para IRC-Hispano.org
; Programa de libre distribución y modificación
; siempre que se respete la autoría del autor.
; http://gonzo.Teoriza.com - gonzomail@gmail.com
; 1.0 - 17/12/2004

on ^*:TEXT:Tienes un mensaje nuevo de*:?: { if (($network == IRC-Hispano) && ($nick == memo) && ($strip(. $+ $6) isin %memo.ignores)) { .msg memo del $11 | set -u2 %memo.borra $11 | closemsg memo | halt } }
on ^*:TEXT:Mensaje*ha sido borrado.:?: { if (($network == IRC-Hispano) && ($nick == memo) && (%memo.borra == $strip($2))) { closemsg memo | unset %memo.borra | halt } }
alias memoignore { 
  if (($1 == add) && ($2)) { set %memo.ignores $iif(%memo.ignores,%memo.ignores,.) $+ $2 $+ . | echo 2 Los memos del nick $2 han sido ignorados. Lista: $replace(%memo.ignores,.,$chr(32)) }
  elseif (($1 == del) && ($2)) { set %memo.ignores $remove(%memo.ignores,$2 $+ .) | echo 2 Se ha quitado el ignore al nick $2 Lista: $replace(%memo.ignores,.,$chr(32)) }
  else { echo 2 Lista de memoignores: $replace(%memo.ignores,.,$chr(32)) }
}

[memoignore]
autor=GONZO
email=gonzomail@gmail.com
web=http://gonzo.teoriza.com
version=1.0
fecha=17/12/2004
descripcion=Ignora los memos de nicks en la lista de ignores borrandolos y silenciandolos. (solo mientras estes conectado)
instalacion=Copiar memoignore.mrc al raiz del mIRC y cargar ejecutando /load -rs memoignore.mrc