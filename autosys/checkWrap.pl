#!/usr/local/bin/perl 

# Grand Unified Check Script
#
# This is an attempt to create a single, configurable script 
# to check the output of all not-collections jobs
#

use File::Basename;

### Gather data for script run

$scriptName = shift(@ARGV);
$scriptArgs = join(' ', @ARGV);

$base = basename($scriptName);

$exit = 0;

($sos) = split(' ', `/usr/local/bin/date +%s`);

local $| = 1; 	# Autoflush

$outfile = $ENV{ '__std_out_file' };
$outfile =~ s/^>//;

unless (-f $scriptName) {
	print "$scriptName not found\n";
	exit(99); 
}

## Get config file for checks

if (-d "/ilx/ops/etc/GUCS/") {
	
	print "Looking for check config in /ilx/ops/etc/GUCS/\n";

	foreach my $candidate (glob("/ilx/ops/etc/GUCS/*")) {
		next unless ($candidate =~ /$base$/);
		print "Parsing $candidate\n\n";
		$topMsg .= "ConfigFile:\t$candidate\n\n";

		($fatal, $warning, $success, $log, $doneFile, $startFile) = &parseConfig($candidate);

	}
}
else {
	print "/ilx/ops/etc/GUCS/ is missing? No checks will be possible\n";
}

############################################
# In case of defined required start files, #
# make sure they are in place first.	   #
############################################

@starterFiles = split(/\,/, $startFile);

foreach my $startFile (@starterFiles) {
	$startFile =~ s/\|$//;

	if ($startFile =~ /\|/) {
		($startFile, $variance) = split(/\|/, $startFile);
	}

	unless(-f $startFile) {
		print "Required start file [$startFile] is unavailable.\n\n";
		&bailOut(7);
	}

	$depthFile = $startFile;

	if ($depthFile =~ /20[0-9][0-9][0-9][0-9]/) {
		($depthFile) = split(/20[0-9][0-9][0-9][0-9]/, $depthFile);
	}

	if (length($variance)) {

		print "Checking for depth of $startFile with status of $depthFile*\n\n";

		# 'DONE' files must NOT be counted.

		$depthCount = 0;
		$deepTot = 0;
		$deepStat = 0;

		open($DEPTH, "ls -ltr $depthFile*|");
		while (<$DEPTH>) {
			chomp;

			next if (/done$/);

			$depthCount++;

			@deepLs = split(' ');
			$deepStat = $deepLs[4];
			$deepTot = $deepTot + $deepStat;
		}
		close($DEPTH);

		$depthAvg = $deepTot / $depthCount;

		$op = $depthAvg / 100;  # Get one percent size.
		$byteVari = $variance * $op;

		$floor  = $depthAvg - $byteVari;
		$ceil   = $depthAvg + $byteVari;

		if ($deepStat > $ceil) {
			print "\n\nStart File $startFile is more than $variance% larger than average!\n";
			$exit++;
		}
		elsif($deepStat < $floor) {
			print "\n\nStart File $startFile is more than $variance% smaller than average!\n";
			$exit++;
		}
		else {
			print "Start File $startFile is present\n";
		}
	}
}

&bailOut($exit) if ($exit > 0);

print "Running $scriptName $scriptArgs\n\n";
$topMsg = "Running $scriptName $scriptArgs\n\n";

if (defined($fatal) && length($fatal)) {
	$topMsg .= "This wrapped-run of '$scriptName $scriptArgs' will fail with the following REGEX: $fatal\n\n";
}
if (defined($warning) && length($warning)) {
	$topMsg .= "This wrapped-run of '$scriptName $scriptArgs' will ignore all instances of: $warning\n\n";
}
if (defined($success) && length($success)) {
	$topMsg .= "This wrapped-run of '$scriptName $scriptArgs' requires $success messages to exit as a success\n\n";
}
if (defined($startFile) && length($startFile)) {
	$cleanStartFile = $startFile;
	$cleanStartFile =~ s/,/\n/g;
	$topMsg .= "This wrapped-run of '$scriptName $scriptArgs' will require the presence of file(s):\n$cleanStartFile\n\nTo Begin\n\n";
}
if(defined($log) && length($log)) {
	$topMsg .= "This wrapped-run of '$scriptName $scriptArgs' will also check contents of :$log\n\n";
}
if (defined($doneFile) && length($doneFile)) {
	$cleanDoneFile = $doneFile;
	$cleanDoneFile =~ s/,/\n/g;
	$topMsg .= "This wrapped-run of '$scriptName $scriptArgs' will check for presence of:\n$cleanDoneFile\n\n";
}

$fatal =~ s/\(/\\\(/;	# Escape parens
$fatal =~ s/\)/\\\)/;

# Run script.

open ($SCRIPT, "$scriptName $scriptArgs 2>&1|");
while (<$SCRIPT>) {
	chomp;

	if (/$fatal/) {

		if (/$warning/ && length($warning)) {
			print "CAUGHT ERROR:\t$_ \n";
			$topMsg .= "CAUGHT ERROR AT LINE $.:\t$_\n";
		}
		else {
			$_ =~ s/^\n//g;		# UGLY
			$_ =~ s/\n$//g;		# FIX

			print "PROVISIONAL FATAL ERROR:\t$_\n";
			$newPrevLine = $_;
			$newPrevLine =~ s/\*/\\\*/g;
			$safeTopMsg .= "FATAL ERROR AT LINE $.:\t$_\n";
			$wcl = $.;
		}
	}

	# REVISION: a fail regex will check the NEXT LINE for an exception.

	if (length($prevLine) && !/$prevLine/ && length($_)) {
		if (/$warning/ && length($warning)) {
			print "CAUGHT ERROR:\t$prevLine\n";
			$topMsg .= "CAUGHT ERROR AT LINE $wcl:\t$_\n";
		}
		else {
			print "CONFIRMED WITH [$_].\n";
			$topMsg = $safeTopMsg;
			$errorCount++;
		}
	undef($prevLine);
	}

	$prevLine = $newPrevLine;

	# heuristic for finding references to a log file...
	if (/\/ilx/ && /log/) {
		$logSieve .= $_.' ';
	}
	print "$_\n";
}
close(SCRIPT);

#Cut losses and exit now  if the actual script failed.

$exit = $?;
&bailOut($exit) if ($exit > 0);

print "LOG IS: $log\n\n";

if ($log =~ /heuristic/i) {
	@sieve = split(' ', $logSieve);

	foreach my $sievedLog (@sieve) {
		if (-f $sievedLog && $sievedLog =~ /log/i) {
			$sieveHash{ $sievedLog } = 1;
		}
	}
	foreach(keys(%sieveHash)) {
		push( @cleanSieve, $_);
	}
}

foreach my $sievedLog (@sieve) {
	($sievedLog) = split(' ', $sievedLog);
	($hardLog) = split(' ',   $hardLog);

	if (!-f $sievedLog && ($sievedLog eq $hardLog)) {
		$errorCount++;
		print "\n\nRequired file $hardLog does NOT EXIST\n\n";
	}
	elsif (-f $sievedLog && ($sievedLog =~ /$hardLog/)) {
		# A hard log must be newer than the outfile, or it is stale.

		if ((stat($outfile))[9] > (stat($hardLog))[9]) {
		}
	}
	elsif (-f $sievedLog) {
		print "CHECKING SIEVED LOG $sievedLog\n";

		open ($LOGS, "/usr/bin/cat $sievedLog|");
		while (<$LOGS>) {
			chomp;

			if (/$fatal/ || /$warning/) {
				if (/$warning/ && length($warning)) {
					print "CAUGHT ERROR: $_ IN $sievedLog\n";
					$topMsg .= "CAUGHT ERROR AT LINE $. OF $sievedLog:\t$_\n";
				}
				else {
					chomp;
					print "FATAL ERROR: $_ IN $sievedLog\n";
					$errorCount++;
					$topMsg .= "FATAL ERROR AT LINE $. OF $sievedLog:\t$_\n";
				}
			}
		}
		close($LOGS);
	}
}

if (defined($doneFile) && ($doneFile =~ /[A-z]/)) {
	@doneFileArray = split(/,/, $doneFile);

	foreach my $doneFile (@doneFileArray) {
		($doneFile) = split(' ', $doneFile);

		($doneFile,$variance) = split(/\|/, $doneFile);

		print "Looking for [$doneFile] ";
		print "within $variance percent of average" if (length($variance));
		print "\n";

		$now =  (stat($outfile) )[9];
		$then = (stat($doneFile))[9];
	
		print "\nSOS: $sos NOW: $now THEN: $then VARI REQ: $variance\n\n";
	
		if ($sos > $then) {
			print "$doneFile timestamp is older than the start of this wrapped run. THATS TOO OLD\n";
			$exit++;
		}
		elsif (length($variance) && ($variance =~ /[0-9]/)) {
			$depthFile = $doneFile;

			$depthCount = 0;
			$deepTot = 0;
			$deepStat = 0;

			open($DEPTH, "ls -ltr $depthFile*|");
			while (<$DEPTH>) {
				chomp;
				$depthCount++;
				@deepLs = split(' ');
				$deepStat = $deepLs[4];
				$deepTot = $deepTot + $deepStat;
			}
			close($DEPTH);

			$depthAvg = $deepTot / $depthCount;

			$op = $depthAvg / 100;	# Get one percent size.
			$byteVari = $variance * $op;
		
			$floor 	= $depthAvg - $byteVari;
			$ceil   = $depthAvg + $byteVari;

			if ($deepStat > $ceil) {
				print "\n\nFile $doneFile is more than $variance% larger than average!\n";
				$exit++;
			}
			elsif($deepStat < $floor) {
				print "\n\nFile $doneFile is more than $variance% smaller than average!\n";
				$exit++;
			}
		}
	}
}

#Cut losses and exit now if a watch failed.
&bailOut($exit) if ($exit > 0);

$exit = $?;

#Cut losses and exit now  if the actual script failed.
&bailOut($exit) if ($exit > 0);

foreach my $term (split(/\|/, $success)) {
	next unless length($term);

	print "HUNT FOR [$term]\n";

	$counter = 1;

	if (length($log)) {
		open ($OUTFILE, "cat $outfile; cat $log 2>&1|");
	}
	else {
		open ($OUTFILE, "cat $outfile|");	# This cat CANNOT BE MESSED WITH.
	}						# Using a regular perl open will
	while (<$OUTFILE>) {				# create a loop. cat creates a snapshot.
		chomp;

		next unless(/$term/ && !/^SUCCESS MESSAGE REGEX:/ && !/^Found success keyword $term/);
		print "Found success keyword $term in line $. of $outfile\n";
		$counter = 0;
	}
	close($OUTFILE);

	if ($counter) {
		print "COULD NOT FIND KEYWORD $term\n";
	}

	$exit = $exit + $counter;
}
$exit = $exit + $errorCount;

print "Done.\n";

&bailOut($exit);

sub bailOut {
	# This function will replace the usual script exit();
	($code) = @_;

	unless(-t) {
		$outFileContents = `cat $outfile | strings`;
		$outFileContents =~ s/\001//g;
		unlink($outfile);
	}

	open ($OUT, '>', $outfile);

	print $OUT "=======================================================\n";
	print $OUT "$topMsg\n\n";
	print $OUT "=======================================================\n\nRaw Outfile Below\n\n$outFileContents\n\n";

	close($OUT);

	if ($code > 0) {
		($stamp) = split(' ', `/usr/local/bin/date +%Y%m%d%H%M`);
		system("cp $outfile $outfile.FAILURE_AT_".$stamp);
		die "$code";
	}

	return(0);
}

sub parseConfig {
	my ($confFile) = @_;

	open ($CONF, $confFile) || print "$confFile is unreadable!!\n";
	while (<$CONF>) {
		chomp;

		next unless (/string/i || /log/i || /File/i || /sizeVariance/i);

		$addTo = 'fail' if (/FailString/i);
		$addTo = 'caught' if (/CaughtString/i);
		$addTo = 'succeed' if (/SuccessString/i);
		$addTo = 'logFile' if (/logFile/i);
		$addTo = 'doneFile' if (/doneFile/i);
		$addTo = 'startFile' if (/startFile/i);

		#remove markup for REGEXP

		if ($addTo =~ /File/) {
			$_ =~ s/<[A-z]*>//;
			$_ =~ s/<\/[A-z]*>//;
			$_ =~ s/\n\//\//g;

			@q = split(' ');
			foreach(@q) {
				# PROBLEM HERE!! TRIM-OUT VARIABLES FIRST THING!!

				($_, $variHolder) = split(/\|/);

				$_ = `echo $_`;
				chomp;

				if ($addTo =~ /startFile/) {
					$$addTo .= $_.'|'.$variHolder.','; # ADDED SPACES
				}
				elsif (-f $_ && length($_)) {
					$$addTo .= $_.'|'.$variHolder.',';
				}
				elsif(/heuristic/) {
					$$addTo .= 'heuristic';
				}
			}
		}
		else {
			$_ =~ s/<[A-z]*>/"/; 
			$_ =~ s/<\/[A-z]*>/"/;

			$_ = `echo $_`;
			chomp;

			$$addTo .= $_.'|' if (length($_)); #TRYING
		}
	}
	close($CONF);

	# Create Failure Rexexp

	foreach(split(/"/, $fail)) {
		next unless (/[A-z]/);
		$failRegexp .= '|'.$_;
	}
	$failRegexp =~ s/\|//;

	# Create Caught Regexp
	foreach(split(/"/, $caught)) {
		next unless (/[A-z]/);
		$caughtRegexp .= '|'.$_;
	}
	$caughtRegexp =~ s/\|//;

	# Create Success Regexp
	foreach(split(/"/, $succeed)) {
		next unless (/[A-z]/);
		$successRegexp .= '|'.$_;
	}

	$logFile =~ s/,$//;
	# allow for a knowlege of 'my script name'.

	@getName = split(/\//, $scriptName);
	$logName = pop(@getName);

	if ($logFile =~ /\$/) {
		($tmp, $holder) = split(/\$/, $logFile);
		($holder) = split(/\.|\-/, $holder) if ($holder =~ /\.|\-/);
		$sub = &autovar($holder);
		$logFile =~ s/\$$holder/$sub/;
	}

	# allow for a single variable in a done file name.
	# FIXME: This is obviously a bad thing.

	if ($doneFile =~ /\$/) {
		($tmp, $holder) = split(/\$/, $doneFile);
		($holder) = split(/\.|\-/, $holder) if ($holder =~ /\.|\-/);
		$sub = &autovar($holder);
		$doneFile =~ s/\$$holder/$sub/;
	}

	$failRegexp   =~ s/\|$//;
	$caughtRegexp =~ s/\|$//;
	$successRegexp =~ s/\|$//;
	
	print "RETURN LOG AS [$logFile]\n\n";

	return($failRegexp, $caughtRegexp, $successRegexp, $logFile, $doneFile, $startFile);
}

sub autovar {
	($filter) = @_;
	local $ENV{LD_LIBRARY_PATH}="/opt/autotree/autosys/lib";
	local $ENV{AUTOSYS}="/opt/autotree/autosys";
	local $ENV{AUTOUSER}="/opt/autotree/autouser";
	local $ENV{ISDBGACTIV}="0";
	local $ENV{SYBASE}="/opt/autotree/sadb";
	local $ENV{DSQUERY}="AUTOSYS_SHADOW";

	($hostname) = split(' ', `hostname`);

	$filter =~ s/\%/\?/g;
	$filter =~ s/\?$//;

	open ($VAREP, "/opt/autotree/autosys/bin/autorep -G $_[0] 2>&1|");
	while (<$VAREP>) {
		chomp;

		if (/$filter/) { 
			($lbl, $var) = split(' ');
			return($lbl,$var) if (length($lbl) && length($var));
		}
	}
	close($VAREP);

	return(0);
}
