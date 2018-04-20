<?
        function jaccard( $item1, $item2, $separator = "," ) {
                $item1 = file($item1);
                $item2 = file($item2);
                //print "1: ".count($item1)." 2: ".count($item2)."\n";
                if (count($item1) > 0 && count($item2) > 0) {
                        $arr_intersection = array_intersect( $item1, $item2 );
                        $arr_union = array_unique(array_merge( $item1, $item2 ));
                        if (count( $arr_intersection ) < count( $arr_union )) {
                                $coefficient = count( $arr_intersection ) / count( $arr_union );
                        }
                        else {
                                $coefficient = count( $arr_union ) / count( $arr_intersection );
                        }
                        $coefficient = round($coefficient, 2);
                        return $coefficient;
                }
        }
        $aye = file($_SERVER['argv'][1]);
        $bee = file($_SERVER['argv'][2]);
        print $_SERVER['argv'][1].' '.$_SERVER['argv'][2]."\t";
        print jaccard($_SERVER['argv'][1], $_SERVER['argv'][2]);
        print "\n";
?>
