#!/opt/chef/embedded/bin/ruby

require 'time'
require 'sinatra'
require 'rest-client'
require 'net/ldap'
require 'date'

set :bind, '0.0.0.0';
set :port, 8086;

# Crowd configs
$crowd_uri = 'http://$A_CROWD_URL:8095'
$crowd_username = 'curl'
$crowd_password = 'curl'


def mineAD(wantedEmail)
        ldap = Net::LDAP.new

        ldap.host = "$AN_ACTIVE_DIRECTORY_HOST"
        ldap.port = "389"
        ldap_username = "$AN_ACTIVE_DIRECTORY_USER"
        ldap_password = "$THEIR_PASSWORD"

        ldap.auth ldap_username, ldap_password


        attrs = ["sAMAccountName", "sn", "givenName", "mail", "objectClass", "pwdLastSet" ]
        base = "DC=addev,DC=bloomberg,DC=com"

        filter = Net::LDAP::Filter.eq('mail', wantedEmail )

        $enabled_samaccountname = ''
        $samaccountname = ''
        ldap.search( :base => 'DC=$DEVELOPMENT,DC=$YOYODYNE,DC=com', :filter => filter,  :attrs => attrs, :return_result => true ) do |entry|
                $samaccountname = entry.samaccountname[0]
                $first_name = entry.givenName[0]
                $last_name = entry.sn[0]
                $email = entry.mail[0]
                $last_reset = entry.pwdlastset[0]
        end

        fine_text = "(&(objectCategory=user)(memberOf=cn=$DEVGRU,OU=Groups,DC=$DEVELOPMENT,DC=$YOYODYNE,DC=com)(mail=#{wantedEmail}))"

        fine_filter = Net::LDAP::Filter.eq('mail', wantedEmail )

        ldap.search( :base => "OU=Accounts,DC=$DEVELOPMENT,DC=$YOYODYNE,DC=com", :attributes => attrs, :filter => fine_filter, :return_result => true ) do |entry|
                $enabled_samaccountname = entry.samaccountname[0]
                puts $enabled_samaccountname
        end

        # Fun factoid: Crowd defaults to checking its internal directory before Active Directory.
        # Don't allow enabled users (who should already appear in Atlassian apps like JIRA) to be recreated in the internal directory.
        #

        if $samaccountname.to_s == ''
                return "nouser"
        elsif $samaccountname === $enabled_samaccountname
                puts "\n\nLAST PASSWORD RESET #{$last_reset}\n\n"
                if $last_reset == "0"
                        return "expired"
                else
                        $last_reset = $last_reset.to_i
                        base = Date.new(1601, 1, 1)
                        base += $last_reset / (60 * 10000000 * 1440)
                        last_reset_epoch = base.to_time.to_i

                        now = Date.today.to_time.to_i

                        diff = now - last_reset_epoch

                        if (diff > 7689600)
                                return "expired"
                        else
                                return "existing"
                        end
                end
        else
                # Okay by AD to create, check to see if user already created in Crowd

                puts "Okay! Creating user."

                resource = RestClient::Resource.new( $crowd_uri, $crowd_username, $crowd_password )
                admin_resource = RestClient::Resource.new( $crowd_uri, $crowd_username, $crowd_password )

                puts "#{$crowd_uri} as #{$crowd_username},#{$crowd_password}"

                check_string = "crowd/rest/usermanagement/latest/user?username=#{$samaccountname}"

                checker = resource[check_string].get{|response, request, result| response }

                if checker.code === 200
                        return "existing_crowd"
                else
                        createJSON = "{\"name\":\"#{$samaccountname}\", \"first-name\":\"#{$first_name}\",\"last-name\":\"#{$last_name}\",\"email\":\"#{$email}\",\"password\":{\"value\":\"derp\"}, \"active\":\"true\"}"
                        poster = resource['crowd/rest/usermanagement/latest/user'].post createJSON, :content_type => 'application/json'

                        groupJSON = "{\"name\":\"NOTRND\"}"
                        assembler = "crowd/rest/usermanagement/latest/user/group/direct?username=#{$samaccountname}"
                        grouper = resource[assembler].post groupJSON, :content_type => 'application/json'

                        reset_string = "crowd/rest/usermanagement/latest/user/mail/password?username=#{$samaccountname}"
                        reseter = resource[reset_string].post "{}", :content_type => 'application/json'

                        return "created"
                end
        end
end

def displayHtml(htmlText, jqueryText="")
        output= <<EOS
<HTML>
<HEAD>
<TITLE>Create New JIRA User</TITLE>
<link rel="stylesheet" href="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.0/jquery.min.js"></script>
<script src="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"></script>
<style>
html, body
{
        background: #2e2d2b;
}
.well
{
        background: #F09000;
}
.blinker {
  animation: blinker 1s infinite;
  color: red
}
@keyframes blinker {
  50% { opacity: 0.0; }
}
</style>
<SCRIPT LANGUAGE="JavaScript">
$(document).ready(function () {
        #{jqueryText}
        });
        </SCRIPT>
        </HEAD>
        <BODY>
        <div class="container">
        <br/>
        <br/>
        <br/>
        <div class="row">
        <p class="col-sm-2" />
        <div class="well well-lg col-sm-8">
        <h3>#{htmlText}<\h3>
        </div>
        <p class="col-sm-2" />
        </div>
        </div>
        </BODY>
        </HTML>
EOS

end

get '/bizuser/*' do;
        $email = params['splat'][0]
        createStatus = mineAD($email)

        puts createStatus
        if createStatus === "existing"
                redirect "/reset_question/#{$samaccountname}/existing"
        elsif createStatus === "expired"
                redirect "/reset_question/#{$samaccountname}/expired"
        elsif createStatus === "existing_crowd"
                redirect "/reset_question/#{$samaccountname}/existing_crowd"
        elsif createStatus === "nouser"
                displayHtml("No user can be found in the Bloomberg directory with email address: '#{$email}'")
        elsif createStatus === "created"
                displayHtml("<p>Your username is '#{$samaccountname}'.</p><p>A password reset link has been sent to your email: '#{$email}'.</p>" +
                    "<div class='blinker'>After resetting your password, your login may not work for up to 2 hours!</div>")
        end
end

get '/reset_crowd_user/*' do;
        $samaccountname = params['splat'][0]
        resource = RestClient::Resource.new( $crowd_uri, $crowd_username, $crowd_password )
        admin_resource = RestClient::Resource.new( $crowd_uri, $crowd_username, $crowd_password )
        reset_string = "crowd/rest/usermanagement/latest/user/mail/password?username=#{$samaccountname}"
        reseter = resource[reset_string].post "{}", :content_type => 'application/json'
        displayHtml("A password reset link has been sent to your email: '#{$email}'" +
                "<div class='blinker'>After resetting your password, your login may not work for up to 2 hours!</div>")
end

get '/reset_question/*/*' do;

        $samaccountname = params['splat'][0]
        createStatus = params['splat'][1]

        resetUrl = ""
        additionalText = ""
        if createStatus === "existing"
                resetUrl = "$PASSWORD_RESET_URL"
        elsif createStatus === "expired"
                additionalText = "You currently cannot log on since your Active Directory password has expired."
                resetUrl = "$PASSWORD_RESET_URL"
        elsif createStatus === "existing_crowd"
                resetUrl = "/reset_crowd_user/#{$samaccountname}"
        end

        htmlText = <<HTML
        <h3>JIRA username '#{$samaccountname}' already exists.<\h3>
        <h3>#{additionalText}<\h3>
        <button type="button" class="btn btn-danger" id="resetButton" name="resetButton">Reset my Active Directory password</button>
HTML

        jQueryCode = <<JQUERY
        $(document).on("click", "#resetButton", function(e){
                location.href = "#{resetUrl}";
                });
JQUERY

        displayHtml(htmlText, jQueryCode)

end

get '/' do;

        htmlText = <<HTML
        <form id="userform" class="form-horizontal" role="form">
        <div class="form-group">
        <p><b><i>Note:</i></b></p>
        <br/>
        <p>Please note that access to JIRA now requires an active Unix ID.</p>
        <p>Active Directory passwords expire every three months. If you need to reset your Active Directory Password, click <a href="$PASSWORD_RESET_URL">here</a>.</p>
        <br/>
        <!--input type="text" class="form-control" style="color: grey; background-color: #F0F0F0;" name="inputbmx" id="inputbox" VALUE="" disabled/--><P/>
        <br/>
        <!--input type="button" class="btn btn-success" id="submitButton" name="button" Value="Create My Account&lt;GO&gt;" disabled/-->
        </div>
        </form>
HTML

        jQueryCode = <<JQUERY
        function submit()
        {
                var username = $("#inputbox").val();
                var addUserUri = '/bizuser/' + username;
                location.href = addUserUri;
        }
        $(document).on("submit", "#userform", function() {
                event.preventDefault();
                submit();
                });
                $(document).on("click", "#submitButton", function(e){
                        event.preventDefault();
                        submit();
                        });
JQUERY

        displayHtml(htmlText, jQueryCode)

end
