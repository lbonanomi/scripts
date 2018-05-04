#!/usr/local/bin/perl

################################
#
# This tool was developed under the name 'Big Idea', it is an attended power-tool for an analyst to make coordinated scheduling changes between 2 streams of an autosys 
# schedule to allow for the addition and removal of markets and for changes in operating hours.
#
# The tool is predicated on Autosys correctly maintaining a schedule for every market in that market's local time. This tool will re-arrange and re-index the 
# corresponding EOD job for said market to execute at the same (UTC) time while maintaining the briefest pssoible list of dependencies between EOD jobs. 
#
# Supplementary jobs to complete a geographic region's processing are also automatically scheduled after all of a region's EOD jobs are complete.
#
# Used in conjunction with a custom file watching script, custom dumpfile generation script, and custom SOD script the schedule created by Big Idea consistently 
# completed approximately 5 hours faster than the human-orchestrated schedule on a parallel silo and without circular logic alarms.
#
################################

# 
# Tool locations
#

$autorep = '/home/l/lukeb/auto_tools/libexec/autorep';
$jobDepends = '/home/l/lukeb/auto_tools/libexec/job_depends';

$roll_in_out = "REDACTED: location of config file for database dump filenames";

$positive_banned_file_names = "REDACTED: file name REGEXes that should not appear in the dump filename list";
$negative_banned_file_names = "REDACTED: file name REGEXes that MUST appear in the dump filename list";

$rollout_pattern = "REDACTED: Autosys stream name denoting collection system dumpfile generation";

@regions = ('AM', 'PR', 'EA1', 'EA2', 'AS', '24');

###################################
# Get rollouts in a region first. #
###################################

open (RIO, "$roll_in_out");
while (<RIO>) {
	chomp;

	next if (/$positive_banned_file_names/ || !/$negative_banned_file_names/);

	($ro,$reg,$subreg) = split(/\|/);
	$ro =~ s/$positive_banned_file_names//;

	$reg = 2 if ($subreg == 1);
	$reg = 3 if ($subreg == 2);

	$regName = $regions[$reg];
	push(@$regName, $ro);

	undef($ro);
	undef($reg);
	undef($subreg);
}
close(RIO);

############################################################

open (REP, "$autorep -J $rollout_pattern%|");
while (<REP>) {
	chomp;

	next unless (/^  01/);				# All jobs in this stream are labelled numerically first
	($job, $tmp, $gmtStart) = split(' ');
	$gmtStart = substr($gmtStart,0,5);

	$uniq{ $gmtStart.'.'.$job } = 1;
	$times{ $gmtStart } = 1;
}
close(REP);

foreach(keys(%uniq)) {
	push(@jobs, $_);
}

@jobs = sort(@jobs);

foreach $job (@jobs) {
	($startTime,$job) = split(/\./, $job);

	open (BOXREP, "$autorep -J $job -q|");
	while (<BOXREP>) {
		chomp;
		next unless (/box_name: /);
		($tmp, $gtpBox) = split(' ');
	}
	close(BOXREP);

	# CONFIRM THAT THERES A CORRESPONDING EOD BOX.

	open (DEP, "$jobDepends -J $gtpBox -c |");
	while (<DEP>) {
		chomp;
	
		next unless (/$gtpBox/ && /EOD/);

		$job = uc($job);
		$job =~ s/TSC_//;	
		@_ = split(/_/, $job);
	
		$gleodBox = 'GLEOD:_'.$_[1].'_'.$_[2].'_BEAST';

		$mktCode = $_[1];
	}
	close(DEP);

	if(length($startTime) && length($gleodBox)) {
		push(@boxes, $startTime.'.'.$gleodBox);

		# Push this code to a clean history array here.

		foreach $region (@regions) {
			foreach $mkt (@$region) {
				if ($mkt eq $mktCode) {
					$arr = "clean$region";
					push(@$arr, $mkt);
				}
			}
		}
	}

	undef($startTime);
	undef($gleodBox);
}

@boxes = sort(@boxes);

$found = 0;

foreach(@boxes) {
	if (/GLEOD:_VN_/) {	# BOX THAT STARTS THE SCHEDULE...
		$found = 1;
	}
	if (!$found) 	{ push(@tail, $_); }
	else 		{ push(@head, $_); }
}

@boxes = ();
@boxes = (@head, @tail);

$c = 100;

$cc = 0;

foreach $box (@boxes) {

	if ($cc == 5) {
		sleep 5;
		$cc = 0;
	}

	($tmp, $box) = split(/\./, $box);
	$box =~ s/:/$c/;
	$c = $c+2;	

	# box is now labelled and IN ORDER.

	@old = split(/_/, $box);
	$oldBox = $old[1].'_'.$old[2].'_'.$old[3];

	open (OLDREP, "$autorep -J GLEOD[0-9]%$oldBox -L0|");		# <--- CHANGED GLEOD to GLEOD[0-9] TO FIX LU/BLU SCREW
	while (<OLDREP>) {
		chomp;
		next unless(/$oldBox/);
		($oldBox) = split(' ');
	}
	close(OLDREP);

	if ($oldBox ne $box) {
		open (REP, "$autorep -J $oldBox -L0 -q 2>&1|");
		while (<REP>) {
			chomp;

			$_ =~ s/$oldBox/$box/;
			
			if (/days_of_week: /) {
				$_ = 'days_of_week: all';
			}

			if (/condition: /) {
				@depArr = split(' ');
				foreach(@depArr) {
					if (/GLEOD/) {
						$_ = "s($lastBox)";
					}
					$depLine .= "$_ ";
				}
				$_ = $depLine;
				undef($depLine);
			}
			print "$_\n";
		}
		close(REP);

		# Move jobs to new box.
		open (REP, "$autorep -J $oldBox -q 2>&1|");
		while (<REP>) {
			chomp;

			next unless (/^  /);

			if (/insert_job: /) {
				$out = $_;
				$out =~ s/insert_job: /update_job: /;
			}
			if (/box_name: /) {
				$out .= "  box_name: $box\n";
			}

			print "$out\n" if (length($out));
			undef($out);
		}
		close(REP);
	}

	foreach $region (@regions) {
		$regCount = 0;

		$arr = "clean$region";

		foreach $mkt (@$arr) {
			if ($mkt ne $old[1]) {
				push(@tmp, $mkt);
				$regCount++;
			}
		}
		
		if ($regCount == 0) {
			$c = $c+2;

			open (HSTREP, "$autorep -J GLEOD%$region%HST% -L0 -q|");
			while (<HSTREP>) {
				chomp;

				if (/insert_job/) {
					@_ = split(' ');
					$_ = "insert_job: GLEOD".$c."_".$region."_HST_BEAST\t".$_[2]." b\n";
				}
				print "$_\n";
			}
			close(HSTREP);

			$c = $c+2;

			#################
			# Insert report #
			#################

			open (REPREP, "$autorep -J GLEOD%$region%REPORT% -L0 -q|");
			while (<REPREP>) {
				chomp;
				if (/insert_job/) {
					$_ = "insert_job: GLEOD".$c."_".$region."_REPORT_BEAST\t".$_[2]." b\n";
				}

				print "$_\n";
			}
			close(REPREP);

			#$c = $c+2;
			
			open (REPREP, "$autorep -J GLEOD%$region%REPORT% -q|");
			while (<REPREP>) {
				chomp;
				next unless (/^  /);
				if (/insert_job: /) {
					$_ =~ s/insert_job/\n\nupdate_job/g;
				}
				if (/box_name: /) {
					@_ = split(' ');
					$_ = $_[0]." GLEOD".$c."_".$region."_REPORT_BEAST\n";
				}
				print "$_\n";
			}
			close(REPREP);

			$c = $c+2;

			####################
			# GL MASTER
			####################

			# This is UGLY. Region AS re-runs PR Master File.

			if ($region =~ /PR|AS/) {
			$c = $c+2;

			open (REPREP, "$autorep -J GLEOD%$region%MASTER% -L0 -q|");
			while (<REPREP>) {
				chomp;

				if (/insert_job: /) {
					$_ = "insert_job: GLEOD".$c."_".$region."_MASTER_BEAST\t".$_[2]." b\n";	
				}
				print "$_\n";
			}
			close(REPREP);

                        open (REPREP, "$autorep -J GLEOD%$region%MASTER% -q|");
                        while (<REPREP>) {
                                chomp;
                                next unless (/^  /);
                                if (/insert_job: /) {
                                        $_ =~ s/insert_job/\n\nupdate_job/g;
                                }
                                if (/box_name: /) {
                                        @_ = split(' ');
                                        $_ = $_[0]." GLEOD".$c."_".$region."_MASTER_BEAST\n";
                                }
                                print "$_\n";
                        }
                        close(REPREP);
			$c = $c+2;

			}
		}
		else {
			@$arr = @tmp;
			@tmp = ();
		}
	}

	open (COPT, "bigIdea.ConfigOpt");
	while (<COPT>) {
		chomp;
		next if (/^#/);

		($snap, $snapped) = split(/:/);

		if ($box =~ /$snap/) {
			print "SNAPPED ON $_\n";
			print "SCHEDULING $snapped AS GLEOD".$c."$snapped\n";

			open (SNAPREP, "$autorep -J %$snapped% -L0 -q|");
			while (<SNAPREP>) {
				chomp;
				print "SNAP: $_\n";
			}
			close(SNAPPED);
		}
	}
	close(COPT);

	$lastBox = $box;

	$cc++;
}
