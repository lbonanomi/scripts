function scripto() {
    # Sane API token?
    curl -Insw "%{http_code}" https://api.github.com/user | tail -1 | grep -q 200 || (echo "Can't reach API" && return 1)

    # Instance a gist and clone it
    GISTID=$(curl -nksd '{"files":{"sfile":{"content":"scriptfile in-flight"}}}' https://api.github.com/gists | awk -F"\"" '$2 == "id" {print $4}' | head -1);
    git clone -q "https://gist.github.com/"$GISTID".git" ~/$GISTID &>/dev/null;

    # API and gist can use the same token but need different addresses, check we can push back a complete gist
    if (cd ~/$GISTID && git push &>/dev/null || return 2)
    then
	script -qf ~/$GISTID/sfile && (cd ~/$GISTID && git add * && git commit -m "." && git push origin && rm -rf ~/$GISTID/.git ~/$GISTID/sfile && rmdir ~/$GISTID);
	curl -nks -X PATCH -d '{ "files":{ "sfile": { "filename":"'$(hostname)' typescript"}}}' https://api.github.com/gists/$GISTID >/dev/null
    else
	echo "No token for gist.github.com"
        rm -rf ~/$GISTID/.git ~/$GISTID/sfile && rmdir ~/$GISTID
    fi
}
