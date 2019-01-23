#!/bin/bash

# Assume a streaming STDIN, and write data to buffer
TMPF=$(mktemp)
while read time value
do
        echo "$time $value" >> $TMPF
done

# Clip at (COLUMNS/2)-5 columns
WINWIDTH=$(($(($(tput cols)/2))-5))
tail -$WINWIDTH $TMPF > $TMPF.2 && mv $TMPF.2 $TMPF

# Scale data
BIGGEST=$(cat $TMPF | awk '{ print $NF }' | sort -n | tail -1)

[[ $(($BIGGEST%4)) -gt 0 ]] && ROWSTART=$(($(($BIGGEST/4))+1))
[[ $(($BIGGEST%4)) -gt 0 ]] || ROWSTART=$(($BIGGEST/4))

# Clip at 25 rows, unless user says '-0'
#
echo "$@" | fgrep -q '0' && ROWEND="0"
echo "$@" | fgrep -q '0' || ROWEND=$(($ROWSTART-25))

for row in $(seq $ROWEND $ROWSTART | tac)
do
        # Justify Y legend
        #
        [[ $(($row%5)) -eq 0 ]] && printf "%-5s" "$(($row*4))"
        [[ $(($row%5)) -eq 0 ]] || printf "%-5s" "    "

	if [[ "$row" -ge 1 ]]
	then

        for col in $(seq 1 $(cat $TMPF | wc -l))
        do
                rval=$(cat $TMPF | awk '{ print $NF }' | head -$col | tail -1)

                if [[ $rval -ge $(($row*4)) ]]
                then
                        printf "\u2847\e[0m "                   # quad-dot
                elif [[ $rval -eq $(($(($row*4))-1)) ]]
                then
                        printf "\u2846\e[0m "                   # triple-dot
                elif [[ $rval -eq $(($(($row*4))-2)) ]]
                then
                        printf "\u2844\e[0m "                   # double-dot
                elif [[ $rval -eq $(($(($row*4))-3)) ]]
                then
                        printf "\u2840\e[0m "                   # single-dot
                else
                        printf "\e[2m\u2810\e[0m "              # dim-dot, 3-row braille
                fi
        done

        echo

	fi
done

# Labels


nl $TMPF | awk '{ print $1 }'  | while read LN
do
	[[ $(($LN%5)) -eq 0 ]] && printf "%5s" "|";
	printf " "
done

printf "\n%4s"

nl $TMPF | awk '{ print $1 }'  | while read LN
do
	printf " "
	LB=$(head -$LN $TMPF | tail -1 | awk '{ print $1 }')
	[[ $(($LN%5)) -eq 0 ]] && printf "%5s" "$LB";
done

rm $TMPF

printf "\n\n"
