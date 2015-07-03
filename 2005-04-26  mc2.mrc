dialog mc {
  title "matachinches 2"
  size -1 -1 278 242
  option dbu
  button "Cuidadin!", 30, 5 201 53 27, flat
  edit "", 1, 5 32 51 10, autohs center
  radio "Nick", 2, 5 4 20 10, group
  radio "Identd", 3, 5 13 27 10
  check "+r visibles", 4, 6 82 36 10
  button "Who", 5, 34 5 23 17, default flat
  list 6, 62 8 216 233, size extsel vsbar
  box "", 7, 3 0 57 45
  box "Filtros", 8, 3 57 57 110
  button "*!a1234@*", 9, 6 111 51 9, flat
  button "*!O12345678@*", 10, 6 120 51 9, flat
  box "", 11, 3 196 57 45
  box "", 12, 3 181 57 17
  edit "0/0", 13, 40 186 19 10, read center
  button "hblock", 15, 7 203 25 13, hide
  button "block", 16, 33 203 24 23, hide
  edit "Host utilizado para ataques mediante clones.", 17, 5 229 53 10, autohs
  text "Select/Hosts:", 19, 5 188 32 8
  check "IP Log", 20, 7 171 25 10
  button "Log", 21, 39 170 18 11, flat
  button "Clear", 22, 3 46 34 10, flat
  edit "1111", 23, 12 217 20 10, hide autohs right
  text "+", 24, 8 219 4 7, hide
  radio "Realname", 25, 5 22 36 10
  box "", 27, 3 165 57 18
  text "/who * %nucfhrs", 26, 234 0 42 8, disable
  text "#Canal Nick Identd IPvirtual Servidor Realname", 28, 63 0 114 8
  button "spamers [beta]", 29, 6 156 51 9, flat
  button "abcdef r", 31, 6 138 51 9, flat
  button "realnames", 32, 6 129 51 9, flat
  check "Filtrar servidores", 33, 6 91 50 10
  check "Mostrar parts", 34, 6 100 50 10
  edit "", 35, 6 72 51 10, autohs center
  text "Filtrar canal:", 36, 6 64 30 8
  button "abcd123!ab ab", 14, 6 147 51 9, flat
  button "viewip", 18, 37 46 22 10, flat
}

on 1:PART:#: {
  if (($dialog(mc)) && ($chan == $active) && ($did(mc,34).state == 1)) {
    if (%mc.masspart >= 3) {
      set %mc.filtro who
      who $nick nx%nucfhrs
    }
    set -u2 %mc.masspart $calc(%mc.masspart + 1)
  }
}

; Servidores filtrados: leda, urano, thebe, luna, sinope, jupiter2, neptuno
on 1:dialog:mc:init:0: {
  unset %mc.filtro
  set %mc.who u
  did -c mc 3
  did -c mc 34
  if (%mc.ip == on) { did -c mc 20 }
  set %mc.servers .leda.urano.thebe.luna.sinope.jupiter2.neptuno.dune.
}
on 1:dialog:mc:sclick:6: {
  unset %mc.hosts
  unset %mc.vhosts
  var %mc.listc 1
  while (%mc.listc <= $did(mc,6,0).sel) {
    if ($remove($gettok($did(mc,6,$did(mc,6,%mc.listc).sel).text,4,32),.virtual) !isin %mc.vhosts) {
      set %mc.vhosts %mc.vhosts $remove($gettok($did(mc,6,$did(mc,6,%mc.listc).sel).text,4,32),.virtual)
      inc %mc.hosts
    }
    inc %mc.listc
  }
  did -i mc 13 1 $did(mc,6,0).sel $+ / $+ %mc.hosts
}
on 1:dialog:mc:sclick:*: {
  if ($did == 5) {
    did -r mc 6
    set %mc.filtro who
    did -i mc 13 1 0/0
    who $$did(mc,1)  %mc.who $+ x% $+ nucfhrs
  }
  if ($did == 18) {
    unset %mc.disparo
    var %mc.viewip 1
    while (%mc.viewip <= $did(mc,6,0).sel) {
      msg nick viewip $gettok($did(mc,6,$did(mc,6,%mc.viewip).sel).text,2,32)
      inc %mc.viewip
    }
  }
  if ($did == 32) {
    did -r mc 6
    set %mc.filtro who
    did -i mc 13 1 0/0
    who ?1?? xn%nucfhrs | who ?2?? xn%nucfhrs | who ?3?? xn%nucfhrs | who ?4?? xn%nucfhrs | who ?5?? xn%nucfhrs | who ?6?? xn%nucfhrs | who ?7?? xn%nucfhrs | who ?8?? xn%nucfhrs | who ?9?? xn%nucfhrs
    who ?1??? xn%nucfhrs | who ?2??? xn%nucfhrs | who ?3??? xn%nucfhrs | who ?4??? xn%nucfhrs | who ?5??? xn%nucfhrs | who ?6??? xn%nucfhrs | who ?7??? xn%nucfhrs | who ?8??? xn%nucfhrs | who ?9??? xn%nucfhrs
    who ?[????]  xu%nucfhrs
    who Mozilla/4.0?(compatible;?MSIE 6.0;* xr%nucfhrs
    who jndcjn xr%nucfhrs
    who *CentralFLU* xr%nucfhrs
    who IRcap[7.5]?4o?www.ircap.net xr%nucfhrs
    who IRcap[7.5] xr%nucfhrs
    who *|0????? xn%nucfhrs
    who *|1????? xn%nucfhrs
    who *|2????? xn%nucfhrs
    who *|3????? xn%nucfhrs
    who *|4????? xn%nucfhrs
    who *|5????? xn%nucfhrs
    who *|6????? xn%nucfhrs
    who *|7????? xn%nucfhrs
    who *|8????? xn%nucfhrs
    who *|9????? xn%nucfhrs
    who *|0????? xn%nucfhrs
  }
  if ($did == 30) {
    mc.tapa off
    .timerTAPA 1 10 mc.tapa on
  }
  if ($did == 10) {
    did -r mc 6
    set %mc.filtro o12345678
    did -i mc 13 1 0/0
    who O???????? xu%nucfhrs
    who O??????? xu%nucfhrs
  }
  if ($did == 14) {
    did -r mc 6
    set %mc.filtro AbCdEfn
    did -i mc 13 1 0/0
    who ????1?? xn%nucfhrs
    who ????2?? xn%nucfhrs
    who ????3?? xn%nucfhrs
    who ????4?? xn%nucfhrs
    who ????5?? xn%nucfhrs
    who ????6?? xn%nucfhrs
    who ????7?? xn%nucfhrs
    who ????8?? xn%nucfhrs
    who ????9?? xn%nucfhrs
    who ????0?? xn%nucfhrs
  }
  if ($did == 31) {
    did -r mc 6
    set %mc.filtro Rabcdef
    did -i mc 13 1 0/0
    who a????? xr%nucfhrs
    who b????? xr%nucfhrs
    who c????? xr%nucfhrs
    who d????? xr%nucfhrs
    who e????? xr%nucfhrs
    who f????? xr%nucfhrs
    who g????? xr%nucfhrs
    who h????? xr%nucfhrs
    who i????? xr%nucfhrs
    who j????? xr%nucfhrs
    who k????? xr%nucfhrs
    who l????? xr%nucfhrs
    who m????? xr%nucfhrs
    who n????? xr%nucfhrs
    who o????? xr%nucfhrs
    who p????? xr%nucfhrs
    who q????? xr%nucfhrs
    who r????? xr%nucfhrs
    who s????? xr%nucfhrs
    who t????? xr%nucfhrs
    who u????? xr%nucfhrs
    who v????? xr%nucfhrs
    who w????? xr%nucfhrs
    who x????? xr%nucfhrs
    who y????? xr%nucfhrs
    who z????? xr%nucfhrs
  }
  if ($did == 29) {
    did -r mc 6
    set %mc.filtro spamers
    who ??????0? xn%nucfhrs
    who ??????1? xn%nucfhrs
    who ??????2? xn%nucfhrs
    who ??????3? xn%nucfhrs
    who ??????4? xn%nucfhrs
    who ??????5? xn%nucfhrs
    who ??????6? xn%nucfhrs
    who ??????7? xn%nucfhrs
    who ??????8? xn%nucfhrs
    who ??????9? xn%nucfhrs
  }
  if ($did == 2) { set %mc.who n }
  if ($did == 3) { set %mc.who u }
  if ($did == 25) { set %mc.who r }
  if ($did == 20) { set %mc.ip $iif($did(mc,20).state == 1,on,off) }
  if ($did == 22) { did -r mc 6 }
  if ($did == 9) { 
    did -r mc 6
    set %mc.filtro a1234
    did -i mc 13 1 0/0
    who ?1?? xu%nucfhrs | who ?2?? xu%nucfhrs | who ?3?? xu%nucfhrs | who ?4?? xu%nucfhrs | who ?5?? xu%nucfhrs | who ?6?? xu%nucfhrs | who ?7?? xu%nucfhrs | who ?8?? xu%nucfhrs | who ?9?? xu%nucfhrs
    who ?1??? xu%nucfhrs | who ?2??? xu%nucfhrs | who ?3??? xu%nucfhrs | who ?4??? xu%nucfhrs | who ?5??? xu%nucfhrs | who ?6??? xu%nucfhrs | who ?7??? xu%nucfhrs | who ?8??? xu%nucfhrs | who ?9??? xu%nucfhrs
  }
  if ($did == 21) { run $mircdir $+ mc.IPs.log }
  if ($did == 15) { 
    set -u20 %mc.disparo on
    ; HBLOCK
    unset %mc.hblock.hosts
    if ($did(mc,20).state == 0) {
      var %mc.hblock 1
      while (%mc.hblock <= $did(mc,6,0).sel) {
        if ($remove($did(mc,6,$did(mc,6,%mc.hblock).sel).text,4,32) !isin %mc.hblock.hosts) {
          msg creg hblock + $+ $$did(mc,23).text $gettok($did(mc,6,$did(mc,6,%mc.hblock).sel).text,2,32) $$did(mc,17).text
          set %mc.hblock.hosts %mc.hblock.hosts $gettok($did(mc,6,$did(mc,6,%mc.hblock).sel).text,4,32)
        }
        inc %mc.hblock
      }
      unset %mc.hblock.hosts
    }
    elseif ($did(mc,20).state == 1) {
      var %mc.hblock 1
      while (%mc.hblock <= $did(mc,6,0).sel) {
        if ($gettok($did(mc,6,$did(mc,6,%mc.hblock).sel).text,4,32) !isin %mc.hblock.hosts) {
          msg nick viewip $gettok($did(mc,6,$did(mc,6,%mc.hblock).sel).text,2,32)
          set %mc.hblock.hosts %mc.hblock.hosts $remove($gettok($did(mc,6,$did(mc,6,%mc.hblock).sel).text,4,32),.virtual)
        }
        inc %mc.hblock
      }
      unset %mc.hblock.hosts
      var %mc.hblock 1
      while (%mc.hblock <= $did(mc,6,0).sel) {
        if ($gettok($did(mc,6,$did(mc,6,%mc.hblock).sel).text,4,32) !isin %mc.hblock.hosts) {
          if (. $+ $gettok($did(mc,6,$did(mc,6,%mc.hblock).sel).text,2,32) $+ . !isin ._antispam.shadow.) { msg creg hblock + $+ $$did(mc,23).text  $gettok($did(mc,6,$did(mc,6,%mc.hblock).sel).text,2,32) $$did(mc,17).text }
          set %mc.hblock.hosts %mc.hblock.hosts $gettok($did(mc,6,$did(mc,6,%mc.hblock).sel).text,4,32)
        }
        inc %mc.hblock
      }
    }
    unset %mc.hblock.hosts
    mc.tapa on
  }
  if ($did == 16) { 
    set -u20 %mc.disparo on
    ; BLOCK
    unset %mc.block.hosts
    if ($did(mc,20).state == 0) {
      var %mc.block 1
      while (%mc.block <= $did(mc,6,0).sel) {
        if ($gettok($did(mc,6,$did(mc,6,%mc.block).sel).text,4,32) !isin %mc.block.hosts) {
          if (. $+ $gettok($did(mc,6,$did(mc,6,%mc.hblock).sel).text,2,32) $+ . !isin ._antispam.shadow.) { msg creg block $gettok($did(mc,6,$did(mc,6,%mc.block).sel).text,2,32) $$did(mc,17).text }
          set %mc.block.hosts %mc.block.hosts $gettok($did(mc,6,$did(mc,6,%mc.block).sel).text,4,32)
        }
        inc %mc.block
      }
    }
    elseif ($did(mc,20).state == 1) {
      var %mc.block 1
      while (%mc.block <= $did(mc,6,0).sel) {
        if ($gettok($did(mc,6,$did(mc,6,%mc.block).sel).text,4,32) !isin %mc.block.hosts) {
          msg nick viewip $gettok($did(mc,6,$did(mc,6,%mc.block).sel).text,2,32)
          set %mc.block.hosts %mc.block.hosts $gettok($did(mc,6,$did(mc,6,%mc.block).sel).text,4,32)
        }
        inc %mc.block
      }
      unset %mc.block.hosts
      var %mc.block 1
      while (%mc.block <= $did(mc,6,0).sel) {
        if ($gettok($did(mc,6,$did(mc,6,%mc.block).sel).text,4,32) !isin %mc.block.hosts) {
          msg creg block $gettok($did(mc,6,$did(mc,6,%mc.block).sel).text,2,32) $$did(mc,17).text
          set %mc.block.hosts %mc.block.hosts $gettok($did(mc,6,$did(mc,6,%mc.block).sel).text,4,32)
        }
        inc %mc.block
      }
    }
    unset %mc.block.hosts
    mc.tapa on
  }
}
on 1:TEXT:IP?real*:?: { 
  if ((%mc.disparo == on) && ($nick == nick) && (@ isin $3) && ($dialog(mc)) && ($strip(IP real:) == $1-2)) { 
    var %mc.ip 1
    while (%mc.ip <= $did(mc,6,0).lines) {
      if ($gettok($did(mc,6,%mc.ip),2,32) == $gettok($strip($3),1,33)) { write mc.IPs.log $ctime - $gettok($$did(mc,6,%mc.ip),5,32) - $3 }
      inc %mc.ip
    }
  } 
}
raw 315:*: { if $dialog(mc) { haltdef } }
raw 354:*: {
  if ($dialog(mc) && ($8)) {
    if ($dialog(mc) && ($8) && (%mc.filtro == who)) { mc.mostrar $1- }
    elseif (%mc.filtro == a1234) { if (($left($3,1) isalpha) && ($left($3,1) islower) && ($right($3,3) isnum) && ($len($3) <= 5) && (smircv !isin $8)) { mc.mostrar $1- } }
    elseif (%mc.filtro == o12345678) { if ((!$9) && ($left($6,1) === O) && ($left($3,1) === O) && ($right($6,7) isnum) && ($right($3,7) isnum)) { mc.mostrar $1- } }
    elseif (%mc.filtro == spamers) {  if (($right($6,2) isnum) && ($left($6,6) isalpha) && ($left($6,6) islower) && ($3 isalpha) && ($3 islower)) { mc.mostrar $1- } }
    elseif (%mc.filtro == Rabcdef) { if ((!$9) && ($3 != $6) && ($6 != $8) && ($3 != $8) && ($8 isalpha) && ($8 islower) && ($len($remove($8,a,e,i,o,u)) >= 3) && (xxx !isin $8) && (aaa !isin $8) && (asd !isin $8) && (jaja !isin $8) && (lala !isin $8) && (wewe !isin $8)) { mc.mostrar $1- } }
    elseif (%mc.filtro == AbCdEfn) { if (($len($3) == 2) && ($3 islower) && ($3 isalpha) && ($3 != $8) && ($8 islower) && ($8 isalpha)) { mc.mostrar $1- } }
    else { mc.mostrar $1- }
    .timerMC.FILTRO 1 4 unset %mc.filtro
  }
  halt
}
alias mc { if (!$dialog(mc)) { dialog -dm mc mc | mode $me +k } | else { dialog -v mc } }
alias mc.mostrar { 
  if ($8) { 
    if ($did(mc,4).state == 0) { 
      if (r !isincs $7) { 
        if ($did(mc,33).state == 1) { if (. $+ $remove($5,.irc-hispano.org) $+ . isin %mc.servers) { if (!$did(mc,35)) { did -a mc 6 $2 $6 $3 $remove($4,.virtual) $remove($5,.irc-hispano.org) $8-  } | elseif ($did(mc,35) == $2) { did -a mc 6 $2 $6 $3 $remove($4,.virtual) $remove($5,.irc-hispano.org) $8- }  } }
        else {
          if (!$did(mc,35)) { did -a mc 6 $2 $6 $3 $remove($4,.virtual) $remove($5,.irc-hispano.org) $8-  } | elseif ($did(mc,35) == $2) { did -a mc 6 $2 $6 $3 $remove($4,.virtual) $remove($5,.irc-hispano.org) $8- }
        }
      }
    }
    else { 
      ; Muestra todos
      if ($did(mc,33).state == 1) { if (. $+ $remove($5,.irc-hispano.org) $+ . isin %mc.servers) { if ($did(mc,34).state == 0) { did -a mc 6 $2 $6 $3 $remove($4,.virtual) $remove($5,.irc-hispano.org) $8-  } | elseif ($did(mc,35) == $2) { did -a mc 6 $2 $6 $3 $remove($4,.virtual) $remove($5,.irc-hispano.org) $8- }  } }
      else {
        if (!$did(mc,35)) { did -a mc 6 $2 $6 $3 $remove($4,.virtual) $remove($5,.irc-hispano.org) $8-  } | elseif ($did(mc,35) == $2) { did -a mc 6 $2 $6 $3 $remove($4,.virtual) $remove($5,.irc-hispano.org) $8- }
      }
    }
  }
}
alias mc.tapa {
  if ($1 == on) { did -v mc 30 | did -h mc 16 | did -h mc 15 | did -h mc 23 | did -h mc 24 }
  if ($1 == off) { did -h mc 30 | .timerTAPA16 -m 1 200 did -v mc 16 | .timerTAPA15 -m 1 200 did -v mc 15 | .timerTAPA23 -m 1 200 did -v mc 23 | .timerTAPA24 -m 1 200 did -v mc 24 }
}
unglines { 
  var %un 1
  while ($read(unglines.txt,%un)) {
    msg oper ungline $gettok($read(unglines.txt,%un),2,64)
    inc %un
  }
}
