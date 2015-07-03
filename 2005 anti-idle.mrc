on ^1:OPEN:?:*a: { if ($nick == $me) { haltdef } }
alias antiidle {
  if (%antiidle) {
    echo 3 anti-idle activado
    .timerANTIIDLE 0 9 .msg $me a
    unset %antiidle
  }
  else {
    echo 4 anti-idle desactivado
    .timerANTIIDLE off
    set %antiidle on
  }
}
