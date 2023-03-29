#!/bin/bash

logdir=logs
logfile=logfile.txt
testdir=tests
testfile=testfile
gendir=gen
prompt="minishell"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

comp_test(){ # args: [1]test number, [2]expected return status, [3]expected stdout, [4]expected stderr
	# echo "/// TEST $1 ///"
	ok=0
	r=$(./minishell <"$testfile" 1> $logdir/out_$1 2> $logdir/err_$1; echo $?)
	if [ $r -ne $2 ]; then echo "$1: Unexpected return status ($r!=$2)"; ((ok++)); fi
	out=$(<$logdir/out_$1 tr -d '\0' | grep -av "$prompt")
	outfound=$(echo "$out" | grep -F -- "$3")
	expout=$(echo "$3" | tr '☃' '\n' | cat)
	# printf "test $1 \$?=$? \n out is [$out] \n outfound is [$outfound]\n"
	if [ -z "$3" ] && [ -n "$out" ];
	then echo "$1: Expected no output but found [$out]"; ((ok++))
	# elif [ -n "$3" ] && [ -z "$outfound" ]
	elif [ -n "$3" ] && [ "$expout" != "$out" ]
	then echo "$1: Expected [$expout] output but found [$out]"; ((ok++))
	fi
	err=$(<$logdir/err_$1 tr -d '\0')
	errfound=$(echo "$err" | grep -F -- "$4")
	experr=$(echo "$4" | tr '☃' '\n' | cat)
	# printf " err is [$err] \n errfound is [$errfound]\n"
	if [ -z "$4" ] && [ -n "$err" ];
	then echo "$1: Expected no error output but found [$err]"; ((ok++))
	# elif [ -n "$4" ] && [ -z "$errfound" ]
	elif [ -n "$4" ] && [ "$experr" != "$err" ]
	then echo "$1: Expected [$experr] error output but found none"; ((ok++))
	fi
	# echo "test 0 yielded $r status"
	return $ok
	# echo "/// TEST $1 ///"
}

	# turn multiple test, status, expected output and expected error files into a single file
	# useful to reduce number of files, or get copied colums from excel files into single document
unite_tests(){
	for arr in "test" "stat" "out" "err";
	do
	[ ! -f "$testdir"/"$1"_"$arr" ] && echo "$1"_"$arr" "required for unification not found :/" > /dev/stderr && return 1
	readarray arr_"$arr" < "$testdir"/"$1"_"$arr"
	done
	[ -f "$testdir"/"$1" ] && [ -n "$(cat "$testdir"/"$1")" ] && rm "$testdir"/"$1";
	len=$(cat "$testdir"/"$1"_test | wc -l)
	for (( test=0; test<$len; test++ ))
	do
		echo -n "${arr_test[$test]}${arr_stat[$test]}${arr_out[$test]}${arr_err[$test]}" >> "$testdir"/"$1"
	done
	echo "Unification of $1 tests successful! :D"
	return 0
}

	# turn a single file into multiple test, status, expected output and expected error files
	# useful to get all tests in different files to copy them into an excel document's columns
split_tests(){
	[ ! -f "$testdir"/"$1" ] && echo "$1" "required for splitting not found :/" > /dev/stderr && return 1
	for arr in "test" "stat" "out" "err"; # clear out existing files
	do
	[ -f "$testdir"/"$1"_"$arr" ] && rm "$testdir"/"$1"_"$arr"; # && [ -n "$(cat "$testdir"/"$1"_"$arr")" ]
	done
	len=$(cat "$testdir"/"$1" | wc -l)	
	readarray arr < "$testdir"/"$1"
	for (( test=0; test<$len; ))
	do
		echo -n "${arr[((test++))]}" >> "$testdir"/"$1"_test
		echo -n "${arr[((test++))]}" >> "$testdir"/"$1"_stat
		echo -n "${arr[((test++))]}" >> "$testdir"/"$1"_out
		echo -n "${arr[((test++))]}" >> "$testdir"/"$1"_err
	done
	echo "Splitting of $1 tests successful! :D"
	return 0
}

# add_test(){
# 	# add arg 2 to testname_test file
# }

generate_test_expectancies(){
	# | tr '\n' '☃'
	[ ! -f "$testdir"/"$1"_test ] && echo "$1"_test "required for test generation not found :/" > /dev/stderr && return 1
	rm -rf $gendir "/tmp/gentest/"
	mkdir -p $gendir "/tmp/gentest/" "/tmp/gentest/stat/" "/tmp/gentest/out/" "/tmp/gentest/err/"
	readarray arr_test < "$testdir"/"$1"_test
	# echo $? "${arr_test[@]}"
	for (( test=0; test<${#arr_test[@]}; test++ ))
	do
		# echo "for$test" > /dev/stderr
		echo -n "${arr_test[$test]}" | tr '☃' '\n' > "/tmp/gentest/$1"
		fullnb=$(printf "%03d" $test) # Without leading zeros, ls takes the files 0 then 1 then 10 then 100 then 101 ... etc
		s=$(bash < "/tmp/gentest/$1" 1> "/tmp/gentest/out/"$1"_out_"$fullnb"" 2> "/tmp/gentest/err/"$1"_err_"$fullnb""; echo $?)
		# s=$(bash -c "$(cat "/tmp/gentest/$1")" 1> "/tmp/gentest/out/"$1"_out_"$fullnb"" 2> "/tmp/gentest/err/"$1"_err_"$fullnb""; echo $?)
		echo "$s" > "/tmp/gentest/stat/"$1"_stat_"$fullnb""
	done
	for stat in $(LANG=C ls "/tmp/gentest/stat/")
	do
		cat /tmp/gentest/stat/"$stat" >> "$gendir"/"$1"_stat
	done
	for out in $(LANG=C ls "/tmp/gentest/out/")
	do
		cat /tmp/gentest/out/"$out" | tr '\n' '☃' >> "$gendir"/"$1"_out
		echo "" >> "$gendir"/"$1"_out
	done
	for err in $(LANG=C ls "/tmp/gentest/err/")
	do
		cat /tmp/gentest/err/"$err" | tr '\n' '☃' >> "$gendir"/"$1"_err | sed 's/bash: line 1/minishell/g'
		echo "" >> "$gendir"/"$1"_err
	done
	rm -rf "/tmp/gentest/"
	echo "Generation of $1 tests' expectancies successful! :D"
	return 0
}

tester(){
	rm -rf $logdir $logfile
	[ -d $logdir ] || mkdir $logdir;
	testnb=0
	rate=0
	for testname in "syntax" "echo"
	do
		for arr in "test" "stat" "out" "err"; do readarray -t arr_"$arr" < "$testdir"/"$testname"_"$arr"; done
		printf "/// $testname tests ///\n" | tee -a $logfile
		len=$(cat "$testdir"/"$testname"_test | wc -l)
		for (( test=0; test<$len; test++ ))
		do
			((testnb++))
			echo -n "${arr_test[$test]}" > $testfile
			(comp_test "$testnb" "${arr_stat[$test]}" "${arr_out[$test]}" "${arr_err[$test]}") | tee -a $logfile
			if [ ${PIPESTATUS[0]} -eq 0 ]; then
				[ ! -n "$1" ] && echo -e "$GREEN/// TEST $testnb  OK ///$NC" > /dev/stderr
			else
				echo -e "$RED/// TEST $testnb  KO  ($testname nb $test)///$NC" > /dev/stderr
			fi
		done
	done
	# (comp_test 0 127 "" "command not found") | tee -a $logfile
	# (comp_test 1 0 "lol" "bruh not found") | tee -a $logfile
}

if [ -n "$1" ] && [ "$1" = "gen" ] && [ -n "$2" ]; then generate_test_expectancies $2; exit $?; fi
if [ -n "$1" ] && [ "$1" = "unite" ] && [ -n "$2" ]; then unite_tests $2; exit $?; fi
if [ -n "$1" ] && [ "$1" = "split" ] && [ -n "$2" ]; then split_tests $2; exit $?; fi
if [ -n "$1" ] && [ "$1" = "clean" ]; then rm -rf $logdir; else tester $1; fi
