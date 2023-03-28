#!/bin/bash

logdir=logs
logfile=$logdir/logfile.txt
testdir=tests
testfile=testfile
prompt="minishell\$"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

comp_test(){ # args: [1]test number, [2]expected return status, [3]expected stdout, [4]expected stderr
	# echo "/// TEST $1 ///"
	ok=0
	r=$(./minishell <"$testfile" 1> $logdir/out_$1 2> $logdir/err_$1; echo $?)
	if [ $r -ne $2 ]; then echo "$1: Unexpected return status ($r!=$2)"; ((ok++)); fi
	out=$(<$logdir/out_$1 tr -d '\0' | grep -av "minishell")
	outfound=$(printf "$out" | grep "$3")
	# printf "test $1 \$?=$? \n out is [$out] \n outfound is [$outfound]\n"
	if [ -z "$3" ] && [ -n "$out" ];
	then echo "$1: Expected no output but found one"; ((ok++))
	elif [ -n "$3" ] && [ -z "$outfound" ]
	then echo "$1: Expected output but found none"; ((ok++))
	fi
	err=$(<$logdir/err_$1 tr -d '\0')
	errfound=$(printf "$err" | grep "$4")
	# printf " err is [$err] \n errfound is [$errfound]\n"
	if [ -z "$4" ] && [ -n "$err" ];
	then echo "$1: Expected no error output but found one"; ((ok++))
	elif [ -n "$4" ] && [ -z "$errfound" ]
	then echo "$1: Expected error output but found none"; ((ok++))
	fi
	# echo "test 0 yielded $r status"
	if [ $ok -eq 0 ]; then
		echo -e "$GREEN/// TEST $1  OK ///$NC" > /dev/stderr
	else
		# echo -e "$1: "$(cat < "$testfile")"\nStatus [$r] expected [$2]\nStdout [$outfound] expected [$3]\nStderr [$errfound] expected [$4]\n"
		echo -e "$RED/// TEST $1 KO ///$NC" > /dev/stderr
	fi
	# echo "/// TEST $1 ///"
}

tester(){
	rm -rf $logdir
	[ -d $logdir ] || mkdir $logdir;
	for testname in "syntax"
	do
		for arr in "test" "stat" "out" "err"; do readarray -t arr_"$arr" < "$testdir"/"$testname"_"$arr"; done

		len=$(cat "$testdir"/"$testname"_test | wc -l)
		for (( test=0; test<$len; test++ ))
		do
			printf "${arr_test[$test]}" > $testfile
			(comp_test $test ${arr_stat[$test]} "${arr_out[$test]}" "${arr_err[$test]}") | tee -a $logfile
		done
	done
	# (comp_test 0 127 "" "command not found") | tee -a $logfile
	# (comp_test 1 0 "lol" "bruh not found") | tee -a $logfile
}

if [ -n $1 ] && [ $1 = "clean" ]; then rm -rf $logdir; else tester; fi
