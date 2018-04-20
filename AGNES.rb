#!/opt/chef/embedded/bin/ruby

require 'pp'
require 'digest/md5'
require 'time'
require 'rest-client'
require 'net/ldap'
require 'date'


ldap = Net::LDAP.new

ldap.host = "addev.$EMPLOYER.com"
ldap.port = "636"
ldap.encryption :simple_tls

ldap_username = "CN=ADMIN_USERNAME, OU=Enabled Accounts,DC=ADDEV,DC=bloomberg,DC=com"
ldap_password = "LULZNOPASSWORDZ"

ldap.auth ldap_username, ldap_password


# Find role DN and their last password set-time.
#

forceReset = ARGV.shift

if (forceReset != "true")
        sAMAccountName = forceReset
else
        sAMAccountName = ARGV.shift
end

if (sAMAccountName.nil?)
        puts "I need an argument to get started"
        exit 1
end

attrs = ["sAMAccountName", "objectClass", "pwdLastSet", "mail", "pwdLastSet" ]
base = "DC=,DC=bloomberg,DC=com"

filter = Net::LDAP::Filter.eq('sAMAccountName', sAMAccountName )

$enabled_samaccountname = ''
$samaccountname = ''
ldap.search( :base => 'OU=Accounts,DC=$DEVELOPMENT,DC=$YOYODYNE,DC=com', :filter => filter,  :attrs => attrs, :return_result => true ) do |entry|
        $last_reset = entry.pwdlastset[0]
        $samaccountname = entry.samaccountname[0]
        $dn = entry.dn
end


# Select a password. You don't have to use it.
#

$noo = ""

# /usr/share/lib/dict for Solaris
# /usr/share/dict/words for Linux

dict = open("/usr/share/lib/dict/words", "r")
file_size = File.stat("/usr/share/lib/dict/words").size
0.upto(2) do
        amount = (dict.tell + rand(file_size - 1)) % file_size
        dict.seek(amount)
        line = dict.readline
        hash = Digest::MD5.hexdigest(line)
        $noo = $noo + line + hash
end

$noo = $noo[0..11]

$noo.gsub!("\n", "")
$noo.gsub!("a", "A")
$noo.gsub!("a", "A")
$noo.gsub!("e", "E")
$noo.gsub!("i", "I")
$noo.gsub!("o", "O")
$noo.gsub!("u", "U")
$noo = $noo.prepend('Z')


# Encode password for Active Directory
#

def self.str2unicodePwd(str)
    ('"' + str + '"').encode("utf-16le").force_encoding("utf-8")
end

if $samaccountname.to_s == ''
        puts "no such user"
        exit
else
        if $last_reset == "0"
                ldap.replace_attribute $dn, :unicodePwd, self.str2unicodePwd($noo)
                puts "SET #{$noo}\n"
        else
                $last_reset = $last_reset.to_i
                base = Date.new(1601, 1, 1)
                base += $last_reset / (60 * 10000000 * 1440)
                last_reset_epoch = base.to_time.to_i

                now = Date.today.to_time.to_i

                diff = now - last_reset_epoch


                if (diff > 7689600)
                        puts "User has an expired password. Reset it to #{$noo}"
                        ldap.replace_attribute $dn, :unicodePwd, self.str2unicodePwd($noo)
                        puts "\n"
                elsif (forceReset == "true")
                        puts "Force-resetting password!"
                        ldap.replace_attribute $dn, :unicodePwd, self.str2unicodePwd($noo)
                else
                        puts "TOO NEW TO RESET"
                end
        end
end
