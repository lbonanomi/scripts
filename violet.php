#!/bin/php
<?php

// Tool VIOLET: Copy all saved filters and boards between instances that match "--project_key"

$shortopts = "";

$longopts = array(
    "dest_instance:",
    "dest_user:",
    "dest_password:",
    "source_instance:",
    "source_user:",
    "source_password:",
    "project_key:",
    "rapidViewID:",
    "board_name:"
);

$options = getopt($shortopts, $longopts);

$dest_instance = $options['dest_instance'];
$dest_instance = preg_replace("/\/$/", "", $dest_instance);
$dest_user     = $options['dest_user'];
$dest_password = $options['dest_password'];

$source_instance = $options['source_instance'];
$source_instance = preg_replace("/\/$/", "", $source_instance);
$source_user     = $options['source_user'];
$source_password = $options['source_password'];

$project_key = $options['project_key'];

$rapidViewID = $options['rapidViewID'];
$board_name  = $options['board_name'];


function getDestBoardID($board_name)
{
    //
    global $dest_user;
    global $dest_password;
    global $dest_instance;
    global $board_name;
    
    $json = `curl -s -k -u $dest_user:$dest_password "$dest_instance/rest/greenhopper/1.0/rapidviews/viewsData"`;
    
    $decoded = json_decode($json, true);
    
    $views = $decoded['views'];
    
    foreach ($views as $view) {
        $this_board_name = $view['name'];
        
        print "\nWANT $board_name, GOT $this_board_name\n";
        
        if ($this_board_name === $board_name) {
            $sourceRapidviewID = $view['id'];
            $name              = $view['filter']['name'];
            $owner             = $view['filter']['owner']['userName'];
            
            return ($sourceRapidviewID);
        }
    }
}




function translate($source_instance, $dest_instance, $skey) // 'translate' issue keys between source and destination
{
    global $source_user;
    global $source_password;
    
    global $dest_user;
    global $dest_password;
    
    print "TRANSLATE AS curl -s -k -u $source_user:$source_password  \"$source_instance/rest/api/2/issue/$skey\"\n";
    
    $translation_json   = `curl -s -k -u $source_user:$source_password  "$source_instance/rest/api/2/issue/$skey"`;
    $translation_decode = json_decode($translation_json, true);
    
    $flashback      = $translation_decode['fields']['summary'];
    $orig_flashback = $translation_decode['fields']['summary'];
    
    // ENCODE FLASHBACK AS UTF-8
    
    $flashback = preg_replace("/\"/", '\\\\u0022', $flashback);
    $flashback = preg_replace("/\*/", '\\\\\*', $flashback);
    
    $flashback = preg_replace("/\[/", '\\\\\[', $flashback);
    $flashback = preg_replace("/\]/", '\\\\\]', $flashback);
    
    $flashback = preg_replace("/\?/", '\\\\\?', $flashback);
    $flashback = preg_replace("/\!/", '\\\\\!', $flashback);
    $flashback = preg_replace("/\-/", '\\\\\-', $flashback);
    
    $flashback = preg_replace("/\(/", '\\\\\(', $flashback);
    $flashback = preg_replace("/\)/", '\\\\\)', $flashback);
    
    
    $flashback_jql = 'summary ~ "' . $flashback . '"';
    
    $flashback_enc = urlencode($flashback);
    
    print "TRANSLATE WITH curl -s -k -u $dest_user:$dest_password  \"$dest_instance/rest/api/2/search?jql=summary%20~%20\\\"$flashback_enc\\\"\"\n";
    
    $flashback_key    = `curl -s -k -u $dest_user:$dest_password  "$dest_instance/rest/api/2/search?jql=summary%20~%20\\"$flashback_enc\\"" 2>&1`;
    $flashback_decode = json_decode($flashback_key, true);
    
    $return_key = $flashback_decode['issues'][0]['key'];
    
    if (!strlen($return_key)) {
        
        // If the issue cannot be found, try searching for similar issues based on levenshtein distance between summaries
        
        //print "TANKED IN-FUNCTION.\n";
        
        $keyArr = explode('-', $skey);
        
        $full_dump = `curl -s -k -u $dest_user:$dest_password  "$dest_instance/rest/api/2/search?jql=project%20=%20$keyArr[0]&maxResults=1000" 2>&1`;
        $full_deco = json_decode($full_dump, true);
        
        
        // This is shameful.
        //
        
        foreach ($full_deco as $decoded) {
            foreach ($decoded as $stupid) {
                
                if (is_array($stupid)) {
                    foreach ($stupid as $stupider) {
                        if (isset($stupider['summary']) && strlen($stupider['summary'])) {
                            $score = levenshtein($stupider['summary'], $orig_flashback, 0, 10, 100);
                            
                            if ($score === 0) {
                                // Texts are similar-enough to match. Something is missing fron src to dest, likely ctrl characters.
                                print "SUSPECT KEY " . $stupid['key'] . "\n\n";
                                $return_key = $stupid['key'];
                            }
                        }
                    }
                } // end-if
            }
        }
    }
    return ($return_key);
}



$dest_board_id = getDestBoardID($board_name);
print "Sprints to board ID $dest_board_id\n";


$project_json    = `curl -s -k -u $source_user:$source_password "$source_instance/rest/api/2/project/$project_key"`;
$project_decoded = json_decode($project_json, true);
$project_name    = $project_decoded['name'];

$sprint_list = `curl -s -k -u $source_user:$source_password "$source_instance/rest/greenhopper/1.0/sprintquery/$rapidViewID?includeFutureSprints=true&includeHistoricSprints=true"`;
$decoded     = json_decode($sprint_list, true);

print "EYE: curl -s -k -u $source_user:$source_password \"$source_instance/rest/greenhopper/1.0/sprintquery/$rapidViewID?includeFutureSprints=true&includeHistoricSprints=true\"\n\n";

$sprint_list = $decoded['sprints'];

foreach ($sprint_list as $sprint) {
    //print_r($sprint);
    
    $sprintID    = $sprint['id'];
    $sprintName  = $sprint['name'];
    $sprintState = $sprint['state'];
    
    $newSprint = 'yes';
    
    //Ping for sprint!
    
    //curl -s -k -u testadmn:975zpb336 http://100.127.5.190:8080/rest/greenhopper/1.0/sprintquery/13?includeFutureSprints=true
    
    $sprint_ping = `curl -s -k -u $dest_user:$dest_password "$dest_instance/rest/greenhopper/1.0/sprintquery/$dest_board_id?includeFutureSprints=true"`;
    $ping_deco   = json_decode($sprint_ping, true);
    
    $sprints_deco = $ping_deco['sprints'];
    
    foreach ($sprints_deco as $sprint_datum) {
        if ($sprint_datum['name'] === $sprintName) {
            print "DON'T CREATE SPRINT $sprintName\n";
            $newSprint   = 'no';
            $dest_sprint = $sprint_datum['id'];
        }
    }
    
    
    if ($newSprint === 'yes') {
        // Instance this sprint
        print "curl -s -k -u $dest_user:$dest_password -X POST \"$dest_instance/rest/greenhopper/1.0/sprint/$dest_board_id\"\n";
        
        $instance_sprint = `curl -s -k -u $dest_user:$dest_password -X POST "$dest_instance/rest/greenhopper/1.0/sprint/$dest_board_id"`;
        $instance_json   = json_decode($instance_sprint, true);
        
        print "INSTANT from curl -s -k -u $dest_user:$dest_password -X POST \"$dest_instance/rest/greenhopper/1.0/sprint/$dest_board_id\"\n";
        print_r($instance_json);
        
        $dest_sprint = $instance_json['id'];
    }
    
    
    // Name this sprint. LATER, NAME AND *DATE*
    //$name_sprint = `curl -s -k -u $dest_user:$dest_password -H 'Content-Type: application/json' -X PUT -d '{"name":"$sprintName" }' "$dest_instance/rest/greenhopper/1.0/sprint/$dest_sprint"`;
    
    
    // Get all issues in source sprint
    
    print "LIST AS curl -s -k -u $source_user:$source_password \"$source_instance/rest/greenhopper/1.0/rapid/charts/sprintreport?rapidViewId=$rapidViewID&sprintId=$sprintID\"\n\n";
    
    $source_issue_list = `curl -s -k -u $source_user:$source_password "$source_instance/rest/greenhopper/1.0/rapid/charts/sprintreport?rapidViewId=$rapidViewID&sprintId=$sprintID"`;
    $source_issue_json = json_decode($source_issue_list, true);
    
    //print_r($source_issue_json);
    
    if ($newSprint === 'yes') {
        // Date this sprint
        
        $dates_arr = $source_issue_json['sprint'];
        
        $sprintStart = $dates_arr['startDate'];
        $sprintEnd   = $dates_arr['endDate'];
        
        //print "DATE WITH curl -s -k -u $dest_user:$dest_password -H 'Content-Type: application/json' -X PUT -d '{\"name\":\"$sprintName\", \"startDate\": \"$sprintStart\", \"endDate\": \"$sprintEnd\" }' \"$dest_instance/rest/greenhopper/1.0/sprint/$dest_sprint\"\n";
        $name_sprint = `curl -s -k -u $dest_user:$dest_password -H 'Content-Type: application/json' -X PUT -d '{"name":"$sprintName", "startDate": "$sprintStart", "endDate": "$sprintEnd" }' "$dest_instance/rest/greenhopper/1.0/sprint/$dest_sprint"`;
    } //                                                                            endOf pinged.
    
    
    //incompletedIssues
    
    foreach ($source_issue_json as $source_issue) {
        $incompletes = $source_issue['incompletedIssues'];
        
        if (is_array($incompletes)) {
            foreach ($incompletes as $incomplete_item) {
                $key = $incomplete_item['key'];
              
                $new_key = translate($source_instance, $dest_instance, $key);
                
                
                if (strlen($new_key)) {
                    $shover = `curl -s -k -u $dest_user:$dest_password -H 'Content-Type: application/json' -X PUT  -d '{"idOrKeys":["$new_key"],"customFieldId":10100,"sprintId":$dest_sprint,"addToBacklog":false}'  "$dest_instance/rest/greenhopper/1.0/sprint/rank"`;
                    
                    if (preg_match("/errorMessage/", $shover)) {
                        print "SHOVER: curl -s -k -u $dest_user:$dest_password -H 'Content-Type: application/json' -X PUT  -d '{\"idOrKeys\":[\"$new_key\"],\"customFieldId\":10100,\"sprintId\":$dest_sprint,\"addToBacklog\":false}'  \"$dest_instance/rest/greenhopper/1.0/sprint/rank\"\n";
                    }
                } else {
                    print "SKIPPING $key!\n";
                }
            }
        }
        
        $completes = $source_issue['completedIssues'];
        
        if (is_array($completes)) {
            foreach ($completes as $complete_item) {
                $key = $complete_item['key'];
                
                $new_key = translate($source_instance, $dest_instance, $key);
                                
                $shover = `curl -s -k -u $dest_user:$dest_password -H 'Content-Type: application/json' -X PUT  -d '{"idOrKeys":["$new_key"],"customFieldId":10100,"sprintId":$dest_sprint,"addToBacklog":false}'  "$dest_instance/rest/greenhopper/1.0/sprint/rank"`;
                print "SHOVER: $shover\n\n";
                
                if (preg_match("/errorMessage/", $shover)) {
                    print "curl -s -k -u $dest_user:$dest_password -H 'Content-Type: application/json' -X PUT  -d '{\"idOrKeys\":[\"$new_key\"],\"customFieldId\":10100,\"sprintId\":$dest_sprint,\"addToBacklog\":false}'  \"$dest_instance/rest/greenhopper/1.0/sprint/rank\"\n";
                }
            }
        }
    }
    
    // Its *possible* to close sprints, but seems pointless, as this throws issues into the backlog again. Lets not do that.
    
    $close_sprints = 0;
    
    if ($sprintState === "CLOSED" && $close_sprints) {
        
        print "STARTING SPRINT $sprintName\n";
        $sprint_starter = `curl -s -k -u $dest_user:$dest_password -H 'Content-Type: application/json' -X PUT -d '{"sprintId":"$dest_sprint", "rapidViewId":"$dest_board_id","startDate": "$sprintStart", "endDate": "$sprintEnd","name":"$sprintName" }' "$dest_instance/rest/greenhopper/1.0/sprint/$dest_sprint/start"`;
        print "STARTER: $sprint_starter\n";
        
        print "CLOSE SPRINT $sprintName\n";
        $sprint_closer = `curl -s -k -u  $dest_user:$dest_password -H 'Content-Type: application/json' -X PUT -d '{"sprintId":"$dest_sprint", "rapidViewId":"$dest_board_id" }' "$dest_instance/rest/greenhopper/1.0/sprint/$dest_sprint/complete"`;
        print "CLOSER: $sprint_closer\n";
    }
}
?>
