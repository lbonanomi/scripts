function scripto() {
    [[ ! -r ~/.netrc.gpg ]] && [[ ! -r ~/.netrc ]] && echo "No .netrc, no gisted scriptfile" && return
    GISTID=$(curl -nksd '{"files":{"sfile":{"content":"scriptfile in-flight"}}}' https://api.github.com/gists | awk -F"\"" '$2 == "id" {print $4}' | head -1);
    git clone -q "https://gist.github.com/"$GISTID".git" ~/$GISTID;
    script -f $GISTID/sfile && (cd ~/$GISTID && git add * && git commit -m "." && git push origin && rm -rf ~/$GISTID/.git ~/$GISTID/sfile && rmdir ~/$GISTID);
    curl -nks -X PATCH -d '{ "files":{ "sfile": { "filename":"'$(hostname)' typescript"}}}' https://api.github.com/gists/$GISTID >/dev/null
}
