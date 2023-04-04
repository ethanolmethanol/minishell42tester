#!/bin/bash

logdir=logs
logfile=logfile.txt
testdir=tests
testfile=testfile
gendir=gen
stadir=stash
pckdir=".pack"
# make a description array to describe each test in usage
testarray=("syntax" "echo" "dollar" "envvar" "cdpwd" "exit" "pipe" "parandor")
prompt="minishell"
RED='\033[0;31m'
GRN='\033[0;32m'
NC='\033[0m'

comp_stat(){ # $1 testnb  $2 expected stat  $3 actual stat
	local expstat=$(echo "$2" | tr '☃' '\n' | tail -1)
	if [[ $3 -ne $expstat ]]; then
		echo -n "$1: Expected [$expstat] status but found [$3]";
		[ $3 -eq 139 ] && echo " A.K.A. SIGSEGV or SEGMENTATION FAULT or CRASH !!!"
		echo ""
		return 1
	fi
	return 0
}

comp_out(){ # $1 testnb  $2 expected out  $3 output type
	local output_name="output"
	local out=$(<$logdir/$3_$1 tr -d '\0')
	if [ "$3" = "err" ]; 
	then	output_name="error output"
	else	out=$(echo "$out" | grep -av "^$prompt") # remove minishell prompts from stdout
	fi
	local expout=$(echo "$2" | tr '☃' '\n')
	local outfound=$(echo "$out" | grep -F -- "$expout")
	# printf "test $1 \$?=$? \n out is [$out] \n outfound is [$outfound]\n"
	if [ -z "$2" ] && [ -n "$out" ]; then
		echo "$1: Expected no $output_name but found [$(echo "$out" | head -5)]"
		return 1
	# elif [ -n "$3" ] && [ -z "$outfound" ]
	elif [ -n "$2" ] && [ "$expout" != "$out" ] && [ -z "$outfound" ]; then
		echo "$1: Expected [$(echo "$expout" | head -5)] $output_name but found [$(echo "$out" | head -5)]"
		return 1
	fi
	return 0
}

comp_test(){ # args: [1]test number, [2]expected return status, [3]expected stdout, [4]expected stderr
	local ok=0
	r=$(./minishell <"$testfile" 1> $logdir/out_$1 2> $logdir/err_$1; echo $?)
	comp_stat $1 $2 $r; let "ok+=$?"
	comp_out "$1" "$3" "out"; let "ok+=$?"
	comp_out "$1" "$4" "err"; let "ok+=$?"
	return $ok
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
	for (( test=0; test<${#arr_test[@]}; test++ ))
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
	readarray arr < "$testdir"/"$1"
	for (( test=0; test<${#arr[@]}; ))
	do
		echo -n "${arr[((test++))]}" >> "$testdir"/"$1"_test
		echo -n "${arr[((test++))]}" >> "$testdir"/"$1"_stat
		echo -n "${arr[((test++))]}" >> "$testdir"/"$1"_out
		echo -n "${arr[((test++))]}" >> "$testdir"/"$1"_err
	done
	echo "Splitting of $1 tests successful! :D"
	return 0
}

pack_tests(){
	mkdir -p $pckdir/
	cp $stadir/* $pckdir/ || { echo "Cannot pack: copy error" > /dev/stderr && return 1; }
	for p in $(ls $pckdir/ | grep _test)
	do
		local testname=$(sed 's/_test//' <(echo "$p"))
		(testdir=$pckdir/ ; unite_tests "$testname") || { echo "Error encountered during unification" > /dev/stderr && return 1; }
		rm $pckdir/"$testname"_*
	done
	echo "Packing of $1 tests successful! :D"
}

unpack_tests(){
	mkdir -p $stadir/
	cp $pckdir/* $stadir/ || { echo "Cannot unpack: copy error" > /dev/stderr && return 1; }
	for p in $(ls $stadir/)
	do
		(testdir=$stadir"up"/ ; split_tests "$p") || { echo "Error encountered during splitting" > /dev/stderr && return 1; }
		rm $stadir/"$p"
	done
	echo "Unpacking of $1 tests successful! :D"
}

# add_test(){
# 	# add arg 2 to testname_test file
# }

is_shell(){ # simple test to determine if executable is a shell
	local shname="$1"
	local result=$("$shname" -ic "echo I am a shell ! " 2> /dev/null)
	if [ $? -ne 0 ] || [ "$result" != "I am a shell !" ]; then return 1; fi
	return 0
}

generate_test_expectancies(){
	# | tr '\n' '☃'
	[ -z "$2" ] && shname="bash"
	{ [ -n "$2" ] && is_shell "$2" && shname="$2" ;} || { echo "Shell name provided does not work as a shell" > /dev/stderr && return 1 ;}
	[ ! -f "$testdir"/"$1"_test ] && echo "$1"_test "required for test generation not found :/" > /dev/stderr && return 1
	rm -rf $gendir "/tmp/gentest/"
	mkdir -p $gendir "/tmp/gentest/" "/tmp/gentest/stat/" "/tmp/gentest/out/" "/tmp/gentest/err/"
	readarray arr_test < "$testdir"/"$1"_test
	# echo $? "${arr_test[@]}"
	for (( test=0; test<${#arr_test[@]}; test++ ))
	do
		# echo "for$test" > /dev/stderr
		echo "unset command_not_found_handle" > "/tmp/gentest/$1"
		echo -n "${arr_test[$test]}" | tr '☃' '\n' >> "/tmp/gentest/$1"
		fullnb=$(printf "%03d" $test) # Without leading zeros, ls takes the files 0 then 1 then 10 then 100 then 101 ... etc
		s=$($shname -i < "/tmp/gentest/$1" 1> "/tmp/gentest/out/"$1"_out_"$fullnb"" 2> "/tmp/gentest/err/"$1"_err_"$fullnb""; echo $?)
		# s=$(bash -c "$(cat "/tmp/gentest/$1")" 1> "/tmp/gentest/out/"$1"_out_"$fullnb"" 2> "/tmp/gentest/err/"$1"_err_"$fullnb""; echo $?)
		echo "$s" > "/tmp/gentest/stat/"$1"_stat_"$fullnb""
	done
	for stat in $(ls "/tmp/gentest/stat/")
	do
		cat /tmp/gentest/stat/"$stat" >> "$gendir"/"$1"_stat # | tr '\n' '☃' 
		# echo "" >> "$gendir"/"$1"_stat
	done
	for out in $(ls "/tmp/gentest/out/")
	do
		cat /tmp/gentest/out/"$out" | tr '\n' '☃' >> "$gendir"/"$1"_out
		echo "" >> "$gendir"/"$1"_out
	done
	for err in $(ls "/tmp/gentest/err/")
	do
		# need to remove all prompt lines of error output since interactive mode
		# puts prompt lines in error output for some obscure reason
		local content=$(cat /tmp/gentest/err/"$err")
		[ -n "$content" ] && content=$(echo -n "$content" | grep -v "$(echo $content | head -1 | head -c 10)")
		echo -n "$content" | tr '\n' '☃' | sed "s/$shname: //g" >> "$gendir"/"$1"_err # | sed '1d' | sed '$d'
		echo "" >> "$gendir"/"$1"_err
	done
	rm -rf "/tmp/gentest/"
	echo "Generation of $1 tests' expectancies successful! :D"
	return 0
}

switch_mode(){
	if [ -n "$1" ] && is_shell "$1";
	then
		mode="$1"
	else
		[ -n "$1" ] && { echo "Cannot switch to mode; input name isn't a shell." > /dev/stderr ; return 1; }
	fi
	[ -z "$1" ] && mode=normal
	mkdir -p "$testdir"
	if [ "$mode" = "normal" ];
	then
		cp $stadir/* $testdir/ || { echo "Copy fail." > /dev/stderr ; return 1 ; }
	else
		for cur in $stadir/*_test
		do
			cp "$cur" $testdir/ || { echo "Copy fail." > /dev/stderr ; return 1 ; }
			generate_test_expectancies $(basename "$cur" | sed 's/_test//') "$mode" || return 1
			cp $gendir/* $testdir/ || { echo "Copy fail." > /dev/stderr ; return 1 ; }
		done
	fi
	rm -rf $gendir/
	echo "Setup complete, $mode mode! :D"
	return 0
}

minimalist_tester(){
	for arr in "test" "stat" "out" "err"; do readarray -t arr_"$arr" < "$testdir"/"$1"_"$arr"; done
	printf "$1" | tee -a $logfile
	local len=$(cat "$testdir"/"$1"_test | wc -l)
	for (( test=0; test<$len; test++ ))
	do
		((testnb++))
		echo -n "${arr_test[$test]}" | tr '☃' '\n' > $testfile
		(comp_test "$testnb" "${arr_stat[$test]}" "${arr_out[$test]}" "${arr_err[$test]}") >> $logfile
		if [ ${PIPESTATUS[0]} -eq 0 ]; then
			((succ++))
			echo -ne "$GRN.$NC" > /dev/stderr
		else
			echo -ne "$RED.$NC" > /dev/stderr
		fi
	done
	echo "" > /dev/stderr
}

full_tester(){
	for arr in "test" "stat" "out" "err"; do readarray -t arr_"$arr" < "$testdir"/"$1"_"$arr"; done
	printf "/// $1 tests ///\n" | tee -a $logfile
	local len=$(cat "$testdir"/"$1"_test | wc -l)
	for (( test=0; test<$len; test++ ))
	do
		((testnb++))
		echo -n "${arr_test[$test]}" | tr '☃' '\n' > $testfile
		(comp_test "$testnb" "${arr_stat[$test]}" "${arr_out[$test]}" "${arr_err[$test]}") | tee -a $logfile
		if [ ${PIPESTATUS[0]} -eq 0 ]; then
			((succ++))
			[ "$2" != "quiet" ] && echo -e "$GRN/// TEST $testnb  OK  ///$NC" > /dev/stderr
		else
			[ "$2" != "quiet" ] && echo -e "$RED/// TEST $testnb  KO  ($1 nb $((test + 1)))///$NC" > /dev/stderr
		fi
	done
}

tester(){ # for sig n heredoc: <&- >&- 2>&- close stdin stdout stderr
	[ ! -d "$testdir" ] && echo "Dir '$testdir' needed for testing missing. Retry after doing 'unpack' then 'set' or 'set bash'" && return 1
	for testname in ${testarray[@]}
	do
		for arr in "test" "stat" "out" "err"
		do	[ ! -f "$testdir"/"$testname"_"$arr" ] && echo "File '$testdir/$testname"_"$arr'" "needed for testing missing. Retry after doing 'unpack' then 'set' or 'set bash'" && return 1
		done
	done
	rm -rf $logdir $logfile
	mkdir -p $logdir;
	testnb=0
	succ=0
	for testname in ${testarray[@]}
	do
		[ "$1" == "mini" ] && minimalist_tester $testname && wait && continue
		# [ "$1" == "load" ] && loading_tester $testname && continue
		full_tester $testname "$1"
	done
	[ -n "$(grep "SEGV" <$logfile)" ] && echo "SEGFAULT DETECTED! CHECK LOGFILE! X("
	echo -e "Your minishell succeeded $GRN$succ$NC out of $testnb tests! :D" > /dev/stderr
}

loader(){
	local load=(
		"~~~~~~~~~~~~~~~~~~~~~~~~~"
		"/^\\_/^\\_/^\\_/^\\_/^\\_/^\\_/"
		".:*~*:._.:*~*:._.:*~*:._."
		"✎﹏﹏﹏﹏﹏﹏﹏﹏﹏﹏﹏﹏"
		"▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰"
		"•:•:•:•:•:•☾☼☽•:•.•:•.•:•"
		"═════════════════════════"
		"· ·─────── ·𖥸· ───────· ·"
		"•────────•°•❀•°•────────•"
		"•☽──────✧˖°˖☆˖°˖✧──────☾•"
		"══════════ ⋆★⋆ ══════════"
	)
	local a=0
	local b=0
	echo
	while $(kill -0 $@ 2> /dev/null)
	do printf "\rLoading ${load[$b]::((a%50))} $b "; let "a++"; let "b=(a/50)%${#load[@]}"; sleep .025
	done
	echo; echo "All done !"
}

best_of_2(){ # two modes at once. Bow to my superior thinking, puny mortal!
	rm -rf $logdir $logfile result1 result2
	mkdir -p $logdir;
	(
		logfile=bo2.txt; logdir="$logdir"2; testdir="$testdir"2; gendir=gen2; testfile=testfile2;
		[ -d $testdir ] || switch_mode "bash" > /dev/null
		tester 2>&1 | cat > result2 # | grep "/// TEST"
		rm -rf $gendir $logfile $testfile
	) &
	local pid1=$!
	(
		logfile=bo1.txt; logdir="$logdir"1; testdir="$testdir"1; gendir=gen1; testfile=testfile1;
		[ -d $testdir ] || switch_mode > /dev/null
		tester 2>&1 | cat > result1 # | grep "/// TEST"
		rm -rf $gendir $logfile $testfile
	) &
	local pid2=$!
	# wait
	loader $pid1 $pid2
	local goodstuff=0
	local n=1
	for (( ; n<=$( <result1 grep "/// TEST" | wc -l ); n++ )) #-${#testarray[@]}
	do
		stat1=$(grep "TEST $n  OK" <result1 >/dev/null; echo $?)
		stat2=$(grep "TEST $n  OK" <result2 >/dev/null; echo $?)
		if [ $stat1 -eq 0 ] || [ $stat2 -eq 0 ]; then
			((goodstuff++))
			[ "$1" = "mini" ] && [ $(( $n%80 )) -eq 0 ] && echo "" | tee -a $logfile
			[ "$1" = "mini" ] && echo -ne "$GRN.$NC" > /dev/stderr && continue
			echo -e "$GRN/// TEST $n  $([ $stat1 -eq 0 ] && echo -n "OK" || echo -n "KO" ) $([ $stat2 -eq 0 ] && echo -n "OK" || echo -n "KO" ) ///$NC" | tee -a $logfile
		else
			$(grep "TEST $n  KO" <result1 >>$logfile; grep "^$n:" <result1 >>$logfile; grep "^$n:" <result2 >>$logfile)
			[ "$1" = "mini" ] && [ $(( $n%80 )) -eq 0 ] && echo ""
			[ "$1" = "mini" ] && echo -ne "$RED.$NC" > /dev/stderr && continue
			echo -e "$RED/// TEST $n  KO KO ///$NC"
		fi
	done
	rm -f result1 result2
	[ "$1" = "mini" ] && echo ""
	echo -e "\nDone! :D"
	[ -n "$(grep "SEGV" <$logfile)" ] && echo "SEGFAULT DETECTED! CHECK LOGFILE! X("
	echo "$goodstuff tests out of $n are OK in at least one of normal or bash mode. Neat."
}

# add .testignore file that contains tests that get skipped and corresponding command
# add comp_val for valgrind stuff
# add sanity check by just packing and unpacking and doing a diff -ru stash/ tmppack/
# check better for 'only' that all provided args are valid tests
case "$1" in 

	"gen")		generate_test_expectancies $2; exit $?;;
	"unite")	unite_tests $2; exit $?;;
	"split")	split_tests $2; exit $?;;
	"pack")		pack_tests; exit $?;;
	"unpack")	unpack_tests; exit $?;;
	"c" | "clean" | "fclean")
		rm -rf $logdir* a b c bonjour hola hey pwd
		[ "$1" = "fclean" ] && rm -rf $logfile $testdir*
		echo "All $1!"
		exit 0
		;;
	"set")
		switch_mode "$2"
		exit $?
		;;
	"bo2")
		best_of_2 "$2"
		exit $?
		;;
	"r" | "run") tester;;
	"m" | "mandatory")
		testarray=("syntax" "echo" "dollar" "envvar" "cdpwd" "exit" "pipe")
		tester
		;;
	"b" | "bonus")
		testarray=("parandor")
		tester
		;;
	"only" | "quiet" | "mini")
		[ "$1" = "only" ] && [ $(ls $testdir | grep "$2"_test | wc -c) -gt 0 ] && testarray=("${@[@]:1}")
		tester $1
		;;
	"-h" | "--help" | "help" | "usage" | *)
		echo
		echo -e "/^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^ ^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^\\"
		echo -e "|\t~/~\t~/~\t${RED}MINI${GRN}TESTER${NC}\t~\\~\t~\\~\t|\tBy emis aka Ethan. With love."
		echo -e "\\_ __ __ __ __ __ __ __ __ _ _ __ __ __ __ __ __ __ __ _/"
		echo
		echo -e "\tUsage -- modes:"
		echo
		echo " - [r]un	: run all tests this tester has. See test units."
		echo
		echo " - [m]andatory	: run all mandatory part tests."
		echo
		echo " - [b]onus	: run all bonus part tests."
		echo
		echo " - bo2		: Best Of 2; run normal and bash mode simultaneously. Useful to check which tests pass either, or fail both."
		echo "   bo2 mini	: a minimalist, less overwhelming version of bo2."
		echo
		echo " - [c]lean	: A classic. Cleans up individual logs and other test-related files."
		echo
		echo " - fclean	: Thorough cleaning. Deletes logfile and all generated/set test directories."
		echo
		echo -e "\tUsage -- test units:"
		echo
		for testname in ${testarray[@]}
		do	printf " - %-8s	: \n\n" "$testname"
		done
		;;
esac

# if [ -n "$1" ] && [ "$1" = "gen" ] && [ -n "$2" ]; then generate_test_expectancies $2; exit $?; fi
# if [ -n "$1" ] && [ "$1" = "unite" ] && [ -n "$2" ]; then unite_tests $2; exit $?; fi
# if [ -n "$1" ] && [ "$1" = "split" ] && [ -n "$2" ]; then split_tests $2; exit $?; fi
# if [ -n "$1" ] && [ "$1" = "clean" ]; then rm -rf $logdir; else tester $1; fi
