<?php

function nextMove($n,$x,$y,$grid){

    foreach ($grid AS $y => $fila)
        foreach (str_split($fila) AS $x => $celda)
            if ($celda!='-')
                $t[$celda] = array($x,$y);

    $move_x = ($t['m'][0]-$t['p'][0]);
    $move_y = ($t['m'][1]-$t['p'][1]);
    
    if (abs($move_x)>0)
        echo ($move_x>0?'LEFT':'RIGHT');
    else if (abs($move_y)>0)
        echo ($move_y>0?'UP':'DOWN');

}





///// HackerRank:
$fp = fopen("php://stdin", "r");
fscanf($fp, "%d", $n);
$pos = fgets($fp);
$pos = split(' ', $pos);
$grid = array();
for ($i=0; $i<$n; $i++) {
    fscanf($fp, "%s", $grid[$i]);
}
nextMove($n,$pos[0],$pos[1],$grid);