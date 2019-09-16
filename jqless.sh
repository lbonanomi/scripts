function jqless() {
    if [[ -e "$1" ]]
    then
        /bin/less "$@"
    else
        read -u 0 -n2 X
        [[ $(echo "$X" | tr -d [:space:] | cut -c1,2 | egrep "\[|\"|{"{2}) ]] &&\
        (((echo -n "$X" && cat) | jq . | /bin/less ) || (echo -n "$X" && cat) | /bin/less ) ||\
        (echo -n "$X" && cat) | /bin/less
    fi
}
