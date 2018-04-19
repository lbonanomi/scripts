#!/usr/local/bin/php


//
// My employer's logging strategy is "Throw it in the log dir and ignore it". Logs roll-over to a new timestamp after 
// they cross ~ 30 MB, so we end up with landslides of small files eating an entire mountpoint. This script gathers
// filenames, calculates the metaphone3 value of the name and collects their sizes. After getting a directory's- 
// worth of file sizes a report of "virtual" files is presented, where "files like XYZ.foo" are shown as a single entity  
//

<?

if (isset($_SERVER['argv'][1])) {
    $dir = $_SERVER['argv'][1] . "/*";
    $fs  = $_SERVER['argv'][1];
} else {
    $dir = getcwd() . "/*";
    $fs  = getcwd();
}

$now        = time();
$spewPeriod = 3600;

$spewDiff = $now - $spewPeriod;

$phones      = array();
$exemplars   = array();
$filecounter = array();
$spewStack   = array();

$dirGlob = glob($dir);
foreach ($dirGlob as $globFile) {
    if (is_file($globFile) && !is_link($globFile)) {
        $filename = basename($globFile);
        $statarr  = stat($globFile);
        $fileSize = $statarr[7];
        $stamp    = $statarr[9];
        
        $metaphone = metaphone($filename);
        
        if ($stamp >= $spewDiff) {
            if (strlen($spewStack[$metaphone])) {
                if (($metaphone === $lastPhone) && $stamp >= ($last + 10)) {
                    $stackHolder           = $spewStack[$metaphone] + 1;
                    $spewStack[$metaphone] = $stackHolder;
                }
            } else {
                $spewStack[$metaphone] = 1;
            }
            $last = $stamp;
        }
        
        if (strlen($phones[$metaphone])) {
            $holder                  = $phones[$metaphone] + $fileSize;
            $countHolder             = $filecounter[$metaphone] + 1;
            $filecounter[$metaphone] = $countHolder;
        } else {
            $holder                  = $fileSize;
            $exemplars[$metaphone]   = $filename;
            $filecounter[$metaphone] = 1;
        }
        $phones[$metaphone] = $holder;
    }
    $lastPhone = $metaphone;
}

arsort($phones);

$keys = array_keys($phones);

## DO CALCS FOR DISK SIAZE
$df         = `df -Pk $fs 2>/dev/null ; df -k $fs 2>/dev/null`;
$df         = trim($df);
#
$dftail_arr = explode("\n", $df);
$dftail     = array_pop($dftail_arr);
$size_arr   = preg_split('/\s+/', $dftail);
$size       = $size_arr[1];
##

// Get top-10 high-value metaphone values

for ($i = 0; $i < 10; $i++) {
    $key = $keys[$i];
    unset($out);
    unset($spewFlag);
    
    $ks  = $phones[$key] / 1024;
    $pct = ($ks / $size) * 100;
    $pct = round($pct, 2);
    
    $outCount = 0;
    
    $spew = array();
    
    $groupSize = $phones[$key]; // humanize the size of this group of filenames
    foreach (array(
        'KB',
        'MB',
        'GB'
    ) as $ext) {
        $newSize = $groupSize / 1024;
        if ($newSize > 1) {
            $groupSize = $newSize;
            $useExt    = $ext;
        }
    }
    
    $groupSize = round($groupSize, 2);
    
    if ($groupSize > 0) {
        print "FILES LIKE $exemplars[$key]: $filecounter[$key] files consuming $groupSize $useExt (" . $pct . "% of $fs) ";
        if ($spewStack[$key] >= 5) {
            print "  SPEW WARNING: $spewStack[$key] FILES IN GROUPING WERE RE-GENERATED WITHIN $spewPeriod SECONDS!";
        }
        print "\n";
    }
}
?>
