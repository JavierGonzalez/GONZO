<?php

function nextMove($player, $board) {
    
    $targets = array(
        // Diagonal
        array('00', '11', '22'),
        array('02', '11', '20'),
        
        // Horizontal
        array('00', '10', '20'),
        array('01', '11', '21'),
        array('02', '12', '22'),
        
        // Vertical
        array('00', '01', '02'),
        array('10', '11', '12'),
        array('20', '21', '22'),
    );
    
    
    // Analyze board
    $turn = 0;
    foreach ($board AS $x=>$row)
        foreach (str_split($row) AS $y=>$p) {            
            if ($p!='_') {
                $turn++;
                $g[$x.$y] = $p;
            } 
            foreach ($targets AS $target_ID=>$target)
                if (in_array($x.$y, $target))
                    $s[$p][$target_ID]++;
        }
    
    
    // Win or Survive
    foreach (array($player, ($player!='O'?'O':'X')) AS $p)
        foreach ((array)$s[$p] AS $target_ID=>$num)
            if ($num==2)
                foreach ($targets[$target_ID] AS $xy)
                    if (!$g[$xy]) {
                        $xy = str_split($xy);
                        return $xy[0].' '.$xy[1];
                    }
    
    
    // Adaptative strategies: Win
    if ($turn==0)
        return '2 2';
        
    if ($turn==2 AND $g['22']==$player AND $g['11'])
        return '0 0';
    
    if ($turn==2 AND $g['22']==$player AND $g['00'])
        return '0 1';
    
    
    // Adaptative strategies: Survive
    if ($turn==1 AND !$g['11'])
        return '1 1';

    if ($turn==3 AND $g['11']==$player)
        if (($g['00'] AND $g['22']) OR ($g['02'] AND $g['20']))
            return '0 1';
    
    
    // Capture Corners
    foreach (array('22', '00', '20', '02') AS $xy)
        if (!$g[$xy]) {
            $xy = str_split($xy);
            return $xy[0].' '.$xy[1];
        }
    
    
    // Capture Lateral
    foreach (array('21', '10', '12', '01') AS $xy)
        if (!$g[$xy]) {
            $xy = str_split($xy);
            return $xy[0].' '.$xy[1];
        }
}







///// HackerRank:
$fp = fopen("php://stdin", "r");
fscanf($fp, "%s", $player);
$board = array();
for ($i=0; $i<3; $i++) { 
    fscanf($fp, "%s", $board[$i]);
}
echo nextMove($player,$board);
