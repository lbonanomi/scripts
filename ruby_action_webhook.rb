#!/opt/chef/embedded/bin/ruby
#

require 'base64'
require 'digest/sha1'
require 'json'
require 'octokit'
require 'sinatra'

$ghe_uri = ''
$ghe_username = ''
$ghe_token = ''

$ghe_org = ''
$ghe_org = ''
iam = $ghe_username

set :bind, '0.0.0.0';
set :port, 7070;

$ghe_handle = Octokit::Client.new \
	:login => $ghe_username,
	:password => $ghe_token,
	:api_endpoint => $ghe_uri+'/api/v3'


def dupe_checker(content)
	content_arr = content.split("\n")
	uniq_arr = content_arr.uniq

	if (content_arr.length != uniq_arr.length)
		dup = content_arr.select{|element| content_arr.count(element) > 1 }
		return(dup)
	else
		unique = Array.new()
		return(unique)
	end
end


def rstrt(repo_name, pull_number, ref, head_sha)
	puts "ENTERING RSTRT PROCESSOR WITH NEW VALUE #{repo_name} INSTEAD OF #{$source_repo_name}!\n\n"

	$duplicated = Array.new()
	$changesets =  Array.new()

	fail_comment = ""
	file_path = ""

	$ghe_handle.pull_request_files(repo_name, pull_number).each do |pullfile|
		pull_attribute = pullfile['filename']

		if (pullfile['filename']  =~ /rstrt/)
			$duplicated = Array.new()

			filename_arr  = pullfile['filename'].split('/')
			file_path = pullfile['filename']

			filename = filename_arr.pop()
			scope = pullfile['filename'].split('/')

			puts "FILE #{filename} CHANGED FOR #{scope}\n\n"

			$adds = Array.new()
			$deletes = Array.new()

			patchcat = pullfile.patch
			patcharr = patchcat.split("\n")

			patcharr.each do |chg|
				if (chg =~ /^\+/ && chg.length > 1)
					chg.sub!('+','')
					$adds.push(chg)
				end

				if (chg =~ /^\-/ && chg.length > 1)
					chg.sub!('-','')
					$deletes.push(chg)
				end
			end

			content_obj = $ghe_handle.contents( $source_repo_name, :path => pull_attribute, :ref => ref)	  # Needs $source_repo_name not repo_name!

			content = Base64.decode64(content_obj.content())

			hook_start_flag = 0
			hook_stop_flag = 0
			procmgr_flag = 0

			content_arr = content.split("\n")
			content_arr.each do |line|
				if (line =~ /systems_hook_rstrt_begin/)
					hook_start_flag = 1
				elsif (line =~ /systems_hook_rstrt_end/)
					hook_stop_flag = 1
				elsif (line =~ /procmgr/)
					procmgr_flag = 1
				end
			end
		end
	end

	if (fail_comment.length() > 0)
		puts "MARKING CHECKS FAILED FOR RSTRT!"
		puts fail_comment
		$ghe_handle.create_status(repo_name, head_sha, "failure", :context => "RSTRT", :description => "RSTRT Checks FAILED" )
		$ghe_handle.create_pull_request_comment(repo_name, pull_number, fail_comment, head_sha, file_path, 1)
	else
		puts "MARKING CHECKS OKAY FOR RSTRT!"
		$ghe_handle.create_status(repo_name, head_sha, "success", :context => "RSTRT", :description => "RSTRT Checks PASSED" )
	end
end


def circular_checker(content, filename)
	#
	# Good idea, bad execution.
	#
	# Adding support to ignore comments and comments to the right-side of a line.
	#

	content_arr = content.split("\n")

	content_arr.each do |entry|
		if (entry =~ /#/)
			line_arr = entry.split(/#/)
			entry = line_arr[0]
		end

		if (entry =~ /#{filename}\b/)    # REMOVING ENDING '$' IN-FAVOR OF \b
			if (entry =~ /[[:graph:]]#{filename}\b/)
				puts "PROBABLY OKAY\n"
			else
				puts "DANGERZONE! CIRCULAR LOGIC CHECK FOR #{filename} LINE VALUE: #{entry}\n"
				if (entry !~ /dblist.bas.dwn.d/ and entry !~ /dblist.bas.up.d/)
					print "SWAT THIS DOWN HARD"
					return('swat')
				end
			end
		end
	end
end


def swat_down_pr(repo_name, pull_number, ref, head_sha, reason)
	silly = $ghe_handle.pull_request(repo_name, pull_number)

	title = silly.title
	body = silly.body

	puts "DO SWAT"
	$ghe_handle.update_pull_request(repo_name, pull_number, options = { :title => "Rejected: #{title}", :body => "#{reason}", :state => "closed"})

	halt 220, "Pull rejected: #{reason}"
end


#
# The *check* router is called at PR-creation
#

def check_router(repo_name, pull_number, ref, head_sha)
	check_rstrt = 0

	$ghe_handle.pull_request_files(repo_name, pull_number).each  do |pull|
		pull.each do |pull_attribute|
			if (pull_attribute[0] =~ /filename/)

				#
				# Do file-specific checks
				#

				path_arr = pull_attribute[1].split('/')
				target_file = path_arr.pop()

				puts "Route file #{target_file}"

				case target_file
					when "dblist.bas.up"
						check_bas = 1
					when "dblist.bas.dwn"
						check_bas = 1
					when "dblist.comdb2"
						check_comdb2 = 1
					when "dblist.comdbg"
						print "COMDBG CHECKS NEED WRITING"
					when "tim.que"
						check_tim = 1
					when "rstrt"
						check_rstrt = 1
					when "dbdwn"
						check_dbdwn = 1
					when "rmtdb.all.files"
						check_rmtdb = 1
				end
			end
		end
	end

	if (check_rstrt == 1)
		$ghe_handle.create_status(repo_name, head_sha, "pending", :context => "RSTRT", :description => "RSTRT Checks Pending" )
		rstrt(repo_name, pull_number, ref, head_sha)
	else
		$ghe_handle.create_status(repo_name, head_sha, "success", :context => "RSTRT", :description => "RSTRT Checks Skipped" )
	end
end


def known_file(repo_name, pull_number, ref, head_sha)
	$found = 0

	puts "ghe_handle.pull_request_files(#{repo_name}, #{pull_number})\n\n"

	changeset = $ghe_handle.pull_request_files(repo_name, pull_number)
	changeset.each do |changed_file|
		puts changed_file.filename

		$found = 0

		changeset_path_arr = changed_file.filename.split('/')
		foo = changeset_path_arr.pop()
		changeset_path = changeset_path_arr.join('/')

		scope_arr = changeset_path_arr
		name = scope_arr.pop()
		scope = scope_arr.pop()


		manifest_path = changeset_path+"/Manifest"

		begin
			manifest_data = $ghe_handle.contents( repo_name, :path => manifest_path, :ref => 'master')

			manifest_data.each do |manifesto|
				if (manifesto[0] =~ /content/)
					content = Base64.decode64(manifesto[1])

					content_arr = content.split("\n")
					content_arr.each do |line|
						if line =~ /#{foo}/
							$found = 1
						end
					end
				end
			end

			if ($found == 0)
				$ghe_handle.create_status(repo_name, head_sha, "failure", :context => "Known file:", :description => "File #{foo} is unknown and will-not be restored" )
			else
				$ghe_handle.create_status(repo_name, head_sha, "success", :context => "Known file:", :description => "File #{foo} is known and will be restored" )
			end
		rescue
			$ghe_handle.create_status(repo_name, head_sha, "failure", :context => "Known file:", :description => "No restore manifest for #{changeset_path}" )
		end
	end
end


def publisher(request_payload)
	# Scrape
	#

	repo_name = request_payload['repository']['full_name']
	short_name = request_payload['repository']['name']
	sha = request_payload['head_commit']['id']

	system("curl -s -k -L -u #{$ghe_username}:#{$ghe_token} #{$ghe_uri}/api/v3/repos/#{repo_name}/tarball > /var/tmp/#{sha}")

	if (File.size?("/var/tmp/#{sha}") > 1)
		puts "Snagged /var/tmp/#{sha}!\n\n"
	else
		$return = $return + "Couldn't get a tarball from GHE!"
		halt 510, "#{$return}"
	end

	# Shove
	#

	push_json = JSON.parse(`curl -s -k -u $ARTIFACTORY_USER:$ARTIFACTORY_TOKEN --data-binary @/var/tmp/#{sha} -X PUT https://$ARTIFACTORY/#{short_name}.tar`)

	puts "\n\nPUSHER: #{push_json}\n\n"

	artifactory_uri = push_json['uri']

	if (artifactory_uri =~ /\/artifactory\//)
		$return = $return + "Pushed #{short_name}.tar to Artifactory #{artifactory_uri}\n"
		File.unlink("/var/tmp/#{sha}")
		if (File.exists?("/var/tmp/#{sha}"))
			$return = $return + "Could not unlink tempfile /var/tmp/#{sha}!"
		end
	else
		$return = $return + "Artifactory push FAILED!\n\nTarball @ /var/tmp/#{sha}\n\nURI: #{artifactory_uri}"
		halt 505, "#{$return}"
	end

	"#{$return}"
end


post '/' do
	request.body.rewind
	request_payload = JSON.parse(request.body.read)

	$event = request.env["HTTP_X_GITHUB_EVENT"]

	$return = ""

	$action = "flounder"

	if (defined?request_payload['action'])
		$action = request_payload['action']
	end


	puts "\n\n\nEVENT: #{$event}\nACTION: #{$action}\n\n\n"

	if ($action == "created")
		halt 240, "Hush."
	elsif ($action == "opened" || $action == "reopened" || $action == "synchronize")
		if (defined?(request_payload['pull_request']['head']))
			#puts JSON.pretty_generate(request_payload)

			$source_repo_name = request_payload['pull_request']['head']['repo']['full_name'];

			## BELOW VALUES ARE OKAY FOR IN-BROWSER CHANGES BY AN ADMIN!
			repo_name = request_payload['pull_request']['base']['repo']['full_name'];
			pull_number = request_payload['pull_request']['number']

			# THESE ARE EXPERIMENTAL!!
			#
			$fork_repo_name = request_payload['pull_request']['head']['repo']['full_name'];
			$fork_pull_number = request_payload['pull_request']['number']


			merged = request_payload['pull_request']['merged']
			sha = request_payload['pull_request']['merge_commit_sha']

			ref = request_payload['pull_request']['head']['ref']
			head_sha = request_payload['pull_request']['head']['sha']   # For comments

			puts "\n\nINTO TOP WITH\n\n"
			puts "repo_name: #{repo_name}\npull_number: #{pull_number}\nmerged: #{merged}\nsha: #{sha}\nref: #{ref}\nhead_sha: #{head_sha}"	# CHANGED repo_name -> source_repo_name
																																			#
			$return = $return + "Making a known-file check"																					#
			known_file(repo_name, pull_number, ref, head_sha)																				# CHANGED repo_name -> source_repo_name
																																			#
			puts "ROUTING AS check_router(#{repo_name}, #{pull_number}, #{ref}, #{head_sha})"												# CHANGED repo_name -> source_repo_name
			check_router(repo_name, pull_number, ref, head_sha)																			    # CHANGED repo_name -> source_repo_name

	    state = $ghe_handle.combined_status(repo_name, head_sha).state()
	    if (state.eql?("success"))
		puts "Auto-approving!"
		merger = $ghe_handle.merge_pull_request(repo_name,pull_number,"Auto-Merged")
	    end

			puts "All routed-out"
			halt 200, "All checks passed"

		elsif (defined?(request_payload['ref_type']) && request_payload['ref_type'].eql?("branch"))
			halt 203, "Branch Opened"
		else
			puts "X MARKS THE SPOT"
		end
	elsif (request_payload['ref'].eql?("refs/heads/master"))
		$return = $return + "Master ref changed. No verification.\n\n"

		committing = request_payload['commits'][0]['author']['username']
		pushing = request_payload['commits'][0]['committer']['username']

		repo_name = request_payload['repository']['full_name']

		puts "DIRECTION! repo_name: #{repo_name} pull_number: #{pull_number} ref: #{ref} head_sha: #{head_sha} COMITTER: #{committing} PUSHER: #{pushing}\n\n"

		if committing != pushing and committing == "testadmn"
			puts "Looks-like a safe* tools push. This should be super-difficult to screw-up, no checks."
		else

			puts "Admin-push? Grind-out checks before publishing and bust-chops of committer #{committing}!"

			head_sha = request_payload['head_commit']['id']
			try = $ghe_handle.commit(repo_name, head_sha)
			file = try.files

			file.each do |whee|
				puts whee.patch
			end

			puts "CHECKING-OUT STATUS API FOR #{ref}?"
		end

		publisher(request_payload)

	elsif (defined?(request_payload['ref_type']) && request_payload['ref_type'].eql?("branch"))
		halt 203, "Branch Opened"
	elsif (request_payload['deleted'].eql?("true"))
		halt 205, "Branch Deleted"
	else
		halt 205, "Misc."
		#puts JSON.pretty_generate(request_payload)
	end
end

get '/' do
	"AUDIT & PEN-TEST GROUPS this is an appliance for running web-hooks on GHE."
end

