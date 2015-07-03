; Nick: GONZO (gonzomail@gmail.com)
concurso4 {
  var %t = $ticks
  unset %palabras
  var %b = 1,%f = a
  hmake palabras
  while (%f) {
    var %bb = 1,%p = $gettok(%f,1,32),%f = $remove($read(refranes.txt,%b),¿,!,.,:,;,?,$chr(44))
    while (%p) {
      if !$hget(palabras,%p) {  hadd -m palabras %p a | inc %palabras }
      var %p = $gettok(%f,%bb,32)
      inc %bb
    }
    inc %b
  }
  hfree palabras | echo GONZO: Palabras: %palabras - Tiempo: $calc($ticks - %t) $+ ms
}