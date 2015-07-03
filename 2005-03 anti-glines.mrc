on 1:TEXT:BLOCK*:#opers-notif: { 
  if ($nick == oper) {
    var %g 1
    while ($read(anti-glines.txt,%g)) {
      if ($gettok($read(anti-glines.txt,%g),1,32) isin $remove($7,$chr(42),$chr(64),$chr(40),$chr(41))) { 
        echo 4 $active  <anti-gline> $remove($7,$chr(42),$chr(64),$chr(40),$chr(41)) ( $+ $gettok($read(anti-glines.txt,%g),2-,32) $+ )  14 /msg oper ungline $remove($7,$chr(42),$chr(64),$chr(40),$chr(41))
        halt
      }
      inc %g
    }
  }
}
