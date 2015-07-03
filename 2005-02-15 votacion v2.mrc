
; !votacion <voto1> [voto2] [voto3] ... [voto20]
; !votacion
; !votar <eleccion>

on 1:INPUT:#: {
  if (($1 == !votacion) && ($chan) && ($readini(votar.ini,config,estado) != on) && ($2)) {
    ; Activar votacion
    mode $me +k
    remini votar.ini elecciones
    remini votar.ini votos
    remini votar.ini config
    writeini votar.ini config canal $chan
    writeini votar.ini config estado on
    writeini votar.ini config votos 0
    writeini votar.ini config elecciones $calc($0 - 1)
    var %e 1
    while ($gettok($2-,%e,32)) {
      writeini votar.ini elecciones $gettok($2-,%e,32) 0
      inc %e
    }
    .timer -m 1 100 msg $chan  0,2 ? 2,0 Empieza la votación. 14 !votar <opcion> 2 Opciones: $2-
    ; mode $chan +b *!*@*
  }
  elseif (($1 == !votacion) && ($chan) && ($readini(votar.ini,config,estado) == on)) { 
    ; Desactivar votacion
    writeini votar.ini config estado off
    ; mode $chan -b *!*@*
    var %w 1
    while ($ini(votar.ini,elecciones,%w)) {
      var %r = %r  $ini(votar.ini,elecciones,%w) $+ ( $+ $round($calc(($readini(votar.ini,elecciones,$ini(votar.ini,elecciones,%w)) * 100) / $readini(votar.ini,config,votos)),0) $+ $chr(37) $+ $chr(41) 
      inc %w
    }
    .timer -m 1 100 msg $readini(votar.ini,config,canal)  0,2 ? 2,0 Votacion terminada. Resultados: %r  Total: $readini(votar.ini,config,votos)
  }
}
on 1:TEXT:!votar*:*: {
  if (($1 == !votar) && ($nick isvoice $readini(votar.ini,config,canal)) && ($readini(votar.ini,config,estado) == on) && ($readini(votar.ini,elecciones,$2) isnum) && (!$readini(votar.ini,votos,$encode($lower($nick),m)))) {
    writeini votar.ini votos $encode($lower($nick),m) $ctime
    writeini votar.ini config votos $calc($readini(votar.ini,config,votos) + 1)
    writeini votar.ini elecciones $2 $calc($readini(votar.ini,elecciones,$2) + 1)
    msg $readini(votar.ini,config,canal) 2 Ok $nick ( $+ $readini(votar.ini,config,votos) $+ )
    msg $nick 2 Has votado a $2 correctamente. ( $+ $readini(votar.ini,config,votos) $+ )
  }
  ; else { msg $readini(votar.ini,config,canal) 4 $nick error  }
}
