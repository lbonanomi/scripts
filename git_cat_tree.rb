#!/opt/chef/embedded/bin/ruby

#
# Scrape a GHE repository into flat files, creating a directory tree relative to the current directory. 
# *Requires org/repo as an argument*
#
# Example: service_catter_tree  lbonanomi/scripts
#

require 'base64'
require 'fileutils'
require 'octokit'

ENV["http_proxy"] = ""
ENV["https_proxy"] = ""

$ghe_uri = 'https://$GHE_URL'
$ghe_username = '$Someone'
$ghe_token = ''

$ghe = Octokit::Client.new \
    :login => $ghe_username,
    :password => $ghe_token,
    :api_endpoint => $ghe_uri+'/api/v3'

repo = ARGV[0]

olive = $ghe.branches(repo)

olive.each do |commit|
    sha = commit['commit']['sha']

    tree = $ghe.tree(repo, sha, :recursive => true)

    tree['tree'].each do |twig|
        leaf = $ghe.contents(repo, :path => twig['path'])

        twiggy_arr =  twig['path'].split('/')   #
        twiggy_filename = twiggy_arr.pop()      # Keep these for later
        twiggy_dir = twiggy_arr.join('/')       #
        twiggy_dir = './' + twiggy_dir

        FileUtils.mkdir_p(twiggy_dir)

        begin
            mulcher = Base64.decode64(leaf.content())
            File.open(twig['path'], 'w') { |file| file.write(mulcher) }
        rescue
            next
        end
    end
end
