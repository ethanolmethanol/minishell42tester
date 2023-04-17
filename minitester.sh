#!/bin/bash

# FILES
logdir=logs
logfile=logfile.txt
testdir=tests
testfile=testfile
gendir=gen
stadir=stash
pckdir=".pack"
ignfile=".testignore"
savedir=save
# BATCHES
testarray=("syntax" "echo" "dollar" "envvar" "cdpwd" "exit" "pipe" "tricky" "redir" "heredoc" "parandor" "wildcard")
ocdarray=("wildcard" "dollar" "tricky" "heredoc" "exit" "pipe" "syntax" "parandor" "cdpwd" "redir" "echo" "envvar")
mandarray=("syntax" "echo" "dollar" "envvar" "cdpwd" "exit" "pipe" "tricky" "redir")
bonuarray=("parandor" "wildcard")
hardarray=("tricky" "hardcore")
# IMPORTANT STUFF
# the path to your minishell executable.
minishell="./minishell"
# the path to your minishell directory, where the executable can be copied from.
fetchpath=".."
# array for modifiers
mod=()
# var used for env -i shenanigans
env=""
# your minishell's prompt (needs to match whatever your prompt is from the BEGINNING of the line)
prompt="minishell" # in my minishell's case, the prompt is 'minishell$ '
# COLOURS
RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[0;33m'
BLU='\033[0;34m'
MAG='\033[0;35m'
ORN='\033[38;2;255;165;0m'
NC='\033[0m'

prompt_choice(){
	echo -e "~ $1 ~"
	shift
	local prompt=$(
		local n=1;
		for option in "$@"; do
		printf "$([ $(( $n%2 )) -eq 1 ] && printf "${RED}" || printf "${GRN}") $n)${NC} $option    "; let "n++"
		[ $# -gt 4 ] && [ $# -ge $n ] && echo
		done
		printf "\n> "
		)
	read -p "$prompt" choice
	[ "${choice}" = "quit" ] && exit 1
	if ! echo "$(seq 1 $#)" | grep -q -P "^${choice}$";
	then prompt_choice "Wrong choice. Type 'quit' if you wish to exit." "$@"
	fi
	return $choice
}

user_interface(){
	local choices=()
	local end=()
	[ ! -d $stadir ] && echo "First time use ? Might want to use 'set' as a first command. A good starting point."
	prompt_choice "Hi! I'm ${RED}mini${GRN}tester${NC}. What can ${RED}I${NC} do for ${GRN}you${NC} ? [enter number]" "${RED}test ${ORN}your ${GRN}minishell${NC}" "${BLU}run ${MAG}a ${YEL}command${NC}"
	[ $? -eq 1 ] && {
		while true; do
		prompt_choice "Select a ${BLU}mode${NC}, ${MAG}test unit batch${NC} and/or ${YEL}modifier${NC} ?" "${BLU}mode${NC}" "${MAG}test unit batch${NC}" "${YEL}modifier${NC} " "${GRN}all done${NC}" "${RED}abort${NC}"
		case $? in
			1)
				prompt_choice "What ${BLU}mode${NC} ?" "normal" "bash" "best of 2"
				case $? in 2) choices+=("bash");; 3) choices+=("bo2");; esac
				;;
			2)
				prompt_choice "What ${MAG}units${NC} ?" "all" "all, but ordered" "mandatory part" "bonus part" "hard stuff" "choose"
				case $? in 2) choices+=("ocd");; 3) choices+=("m");; 4) choices+=("b");; 5) choices+=("h");;
					6)
					local prompt="$(printf "Enter the name(s) of the ${MAG}unit(s)${NC} you wish to run.\nAvailable ${MAG}units${NC}: ${testarray[*]} \n> ")"
					read -p "$prompt" -a units
					[ ${#units[@]} -eq 0 ] && echo "Need at least one test unit." && continue
					for a in "${units[@]}"
					do	[ $(ls $mode$stadir 2> /dev/null | grep "^${a}_test$" | wc -c) -eq 0 ] && echo "'$a' test unit not found. Be sure to set a mode." && continue
					done
					end+=("o" "${units[@]}")
					;;
				esac
				;;
			3)
				prompt_choice "What ${YEL}modifier${NC} ?" "mini" "quiet" "valgrind" "noskip" "noenv"
				case $? in 1) choices+=("mini");; 2) choices+=("quiet");; 3) choices+=("val");;
				4) choices+=("noskip");; 5) choices+=("noenv");; esac
				;;
			4) break ;;
			5) echo "Goodbye!"; exit 1 ;;
		esac
		done
	} || {
		local cmd=("set" "ignore" "notignore" "clean" "fclean" "man" "peek" "save")
		prompt_choice "Which ${YEL}command${NC} ?" "${cmd[@]}"
		local nb=$?
		choices+=("${cmd[$(( $nb-1 ))]}")
		case $nb in
			1 | 2 | 3 | 7 | 8)
				local stuff=""
				case $nb in 1) stuff="mode";; 2 | 3 | 7) stuff="testunit ['all'/testnb...]";; 8) stuff="log file name";; esac
				read -p "Specify ${cmd[$(( $?-1 ))]} args [$stuff]: " -a end ;;
		esac
	}
	choices+=("${end[@]}")
	echo
	echo "Next time, to skip this interface you can use \` ./minitester.sh ${choices[@]} ' :D"
	echo
	main "${choices[@]}"
}

# add 'cleanup tests' that delete any created files from prior tests,
# not to interfere with ls or other tests involving present files
# add sanity check by just packing and unpacking and doing a diff -ru stash/ tmppack/
main(){
	local mode=""
	while [ $# -ne 0 ]
	do
	case "$1" in 
		# "gen")		generate_test_expectancies $2; exit $?;;
		# "unite")	unite_tests $2; exit $?;;
		# "split")	split_tests $2; exit $?;;
		# "pack")		pack_tests; exit $?;;
		# "unpack")	unpack_tests; exit $?;;
		# "check")	sanity_check; exit $?;;
		# "rep")	re_place_holder; exit $?;;
		"save")		save_log "$2"; exit $?;;
		"u" | "user" | "guide" | "showmetheway")
			user_interface;
			exit $?
			;;
		"p" | "peek")
			shift
			peek_test "$mode" "$@";
			exit $?
			;;
		"i" | "ignore")
			shift
			ignore_tests "$@"
			exit $?
			;;
		"n" | "notignore")
			shift
			notignore_tests "$@"
			exit $?
			;;
		"c" | "clean" | "fclean")
			rm -rf $logdir* a b c bonjour hola hey pwd
			[ "$1" = "fclean" ] && rm -rf $logfile $testfile $testdir* ?*$stadir
			echo "All $1!"
			exit 0
			;;
		"s" | "set")
			switch_mode "$2"
			exit $?
			;;
		"r" | "run" | "ocd")
			testarray=("${ocdarray[@]}")
			;;
		"m" | "mandatory")
			testarray=("${mandarray[@]}")
			;;
		"b" | "bonus")
			testarray=("${bonarray[@]}")
			;;
		"h" | "hard")
			testarray=("${hardarray[@]}")
			;;
		"o" | "only")
			shift
			[ $# -eq 0 ] && die "Only: need at least one test unit to work."
			for a in $@
			do	[ $(ls $mode$stadir 2> /dev/null | grep "$a"_test | wc -c) -eq 0 ] && echo "'$a' test unit not found. Be sure to set a mode." && exit 1
			done
			testarray=("$@")
			break
			;;
		"bo2" | "quiet" | "mini" | "val" | "noskip" | "noenv")
			[ "$1" = "noenv" ] && env="env -i"
			mod+=("$1")
			;;
		"-h" | "--help" | "help" | "usage" | "man" | "i'm lost" | "wtf" | "RTFM")
			get_man
			exit $?
			;;
		*)
		[ -d "$1$stadir" ] && mode="$1" && shift && continue
		is_shell "$1" && die "Need to set bash if you wanna use bash mode"
		die "Whoops! Not a valid argument. Try 'man' if you're lost, or 'user' to be guided."
		;;
	esac
	shift
	done
	echo -e "/^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^ ^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^\\"
	echo -e "|\t~/~\t~/~\t${RED}MINI${GRN}TESTER${NC}\t~\\~\t~\\~\t| ~ By emis. With love."
	echo -e "\\_ __ __ __ __ __ __ __ __ _ _ __ __ __ __ __ __ __ __ _/\n"
	fetch_last
	[ ! -f "$minishell" ] && die "Minishell executable not found. Copy it in this dir or change \$fetchpath."
	modifier_set "bo2" && best_of_2 && exit $?
	tester $mode
	exit $?
}

fetch_last(){
	[ ! -d $fetchpath ] && return 1
	[ ! -f $fetchpath/minishell ] && return 1
	cp $fetchpath/minishell . || die "Fetch fail :("
	echo "Minishell executable was successfully fetched from $fetchpath !"
	return 0
}

function die(){
	local status=1
	case $1 in
		[0-9]) status="$1"; shift 1;;
	esac
	test $status -eq 0 && return 0
	local message="$*"
	[ -z "$message" ] && message="Died"
	[ $status -ne 1 ] && message="${BASH_SOURCE[1]}: line ${BASH_LINENO[0]}: ${FUNCNAME[1]}: $message."
	echo $message >&2
	exit $status
}

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
	if [ -z "$2" ] && [ -n "$out" ]; then
		echo "$1: Expected no $output_name but found [$(echo "$out" | head -5)]"
		return 1
	elif [ -n "$2" ] && [ "$expout" != "$out" ] && [ -z "$outfound" ]; then
		echo "$1: Expected [$(echo "$expout" | head -5)] $output_name but found [$(echo "$out" | head -5)]"
		return 1
	fi
	return 0
}

val_check_for(){ # $1 testnb  $2 check keyword
	local check=$(grep "$2" $logdir/val_$1)
	[ -n "$check" ] && echo "$1: Valgrind: $2 : $(echo "$check" | head -1)" && return 1
	return 0
}

valbase=("--suppressions=ignore_rl_leaks.supp")
valmedi=("--leak-check=full" "--show-leak-kinds=all" "--track-origins=yes")
valhard=("--track-fds=yes") #"--trace-children=yes"
comp_val(){
	local ok=0
	valargs=(${valbase[@]} ${valmedi[@]} ${valhard[@]})
	r=$($env valgrind --log-file=$logdir/val_$1 ${valargs[@]} $minishell <"$testfile" 1> $logdir/out_$1 2> $logdir/err_$1; echo $?)
	comp_stat $1 $2 $r; let "ok+=$?"
	comp_out "$1" "$3" "out"; let "ok+=$?"
	comp_out "$1" "$4" "err"; let "ok+=$?"
	sed -i "s/==[[:digit:]]\+== //g" $logdir/val_$1
	local leak=$(grep -n "LEAK SUMMARY" $logdir/val_$1 | head -1 | sed 's@\([0-9]\+\).*@\1@')
	for (( l=$leak+1;l<$leak+5;l++ ))
	do
		local line=$(get_nth_line $logdir/val_$1 $l)
		if [ $(echo $line | sed 's@^[^0-9]*\([0-9]\+\).*@\1@') -ne 0 ];then
			echo "$1: Valgrind: memory leak: ${line##*( )}"; let "++ok"
		fi
	done
	for keyword in " read" " write" "uninitialised" " free()"
	do val_check_for $1 "$keyword"; let "ok+=$?"
	done
	local fds=$(grep -A 1 "^Open file descriptor " $logdir/val_$1)
	[ -n "$(grep "open" <(echo "$fds"))" ] && echo "$1: Valgrind: track fd: $(echo "$fds" | head -1)" && let "++ok"
	return $ok
}

val_error(){
	modifier_set "val" || return 0
	[ -n "$(grep "Valgrind:" <$logfile)" ] && echo -e "${RED}VALGRIND ERRORS${NC} DETECTED! CHECK LOGFILE! X(" && return 1
	echo -e "${GRN}No valgrind error detected.${NC} All good :)"
	return 0
}

comp_test(){ # args: [1]test number, [2]expected return status, [3]expected stdout, [4]expected stderr
	local ok=0
	modifier_set "val" && { comp_val "$1" "$2" "$3" "$4"; return $?; }
	r=$($env $minishell <"$testfile" 1> $logdir/out_$1 2> $logdir/err_$1; echo $?)
	comp_stat $1 $2 $r; let "ok+=$?"
	comp_out "$1" "$3" "out"; let "ok+=$?"
	comp_out "$1" "$4" "err"; let "ok+=$?"
	return $ok
}

get_nth_line(){ # $1 is file  $2 is line nb
	sed "${2}q;d" "$1"
}

peek_test(){
	local mode="$1";
	[ ! -d "$mode$stadir" ] && die "No stash directory found. Set a mode, and try again."
	shift
	[ -z "$(grep "$1"_ <(ls "$mode$stadir"))" ] && die "Invalid test unit name. Couldn't find."
	[ $# -le 1 ] && die "Specify at least one test to peek."
	local unit="$1"
	shift
	local lines=("$@")
	local display="cat"
	[ "$1" = "all" ] && lines=($(seq 1 "$(cat "$mode$stadir/$unit"_test | wc -l)" | tr '\n' ' '))
	[ ${#lines[@]} -gt 9 ] && display="less"
	(
	for line in "${lines[@]}"
	do
		[ "$line" -eq "$line" ] 2> /dev/null || die "Specified test number '$line' is not a number. Ouch."
		[ $line -le 0 ] && die "Specified test number '$line' is too small. Ouch."
		[ $line -gt $(cat "$mode$stadir/$unit"_test | wc -l) ] && die "Specified test number '$line' is too big. Ouch."
		echo -ne "Test $line for $unit:\t"
		get_nth_line "$mode$stadir/$unit"_test "$line" || die "Error occured" "file $mode$stadir/$unit"_test "line $line"
		echo -ne "Expected stdout:\t"
		get_nth_line "$mode$stadir/$unit"_out "$line" | head -c 100 || die "Error occured" "file $mode$stadir/$unit"_out "line $line"
		echo -ne "Expected stderr:\t"
		get_nth_line "$mode$stadir/$unit"_err "$line" || die "Error occured" "file $mode$stadir/$unit"_err "line $line"
		echo -ne "Expected status:\t"
		get_nth_line "$mode$stadir/$unit"_stat "$line" || die "Error occured" "file $mode$stadir/$unit"_stat "line $line"
		echo
	done
	) | $display
	echo "All done! :D"
}

	# turn multiple test, status, expected output and expected error files into a single file
	# useful to reduce number of files, or get copied colums from excel files into single document
unite_tests(){
	for arr in "test" "stat" "out" "err";
	do
	[ ! -f "$testdir"/"$1"_"$arr" ] && die "$1"_"$arr" "required for unification not found :/"
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
	[ ! -f "$testdir"/"$1" ] && die "$1" "required for splitting not found :/"
	for arr in "test" "stat" "out" "err"; # clear out existing files
	do
	[ -f "$testdir"/"$1"_"$arr" ] && rm "$testdir"/"$1"_"$arr";
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
	cp $stadir/* $pckdir/ || die "Cannot pack: copy error"
	for p in $(ls $pckdir/ | grep _test)
	do
		local testname=$(sed 's/_test//' <(echo "$p"))
		(testdir=$pckdir/ ; unite_tests "$testname") || die "Error encountered during unification"
		rm $pckdir/"$testname"_*
	done
	echo "Packing of $1 tests successful! :D"
}

unpack_tests(){
	mkdir -p $stadir/
	cp $pckdir/* $stadir/ || die $? "Cannot unpack: copy error"
	echo -e "${YEL}"
	for p in $(ls $stadir/)
	do
		(testdir=$stadir/ ; split_tests "$p") || { echo "Error encountered during splitting" > /dev/stderr && return 1; }
		rm $stadir/"$p"
	done
	echo -e "Unpacking of $1 tests successful! :D${NC}"
}

sanity_check(){
	[ ! -d $stadir ] && die "No $stadir dir, cannot check sanity."
	local ori=$stadir
	pckdir=/tmp/mshtstsanitycheckpck
	pack_tests > /dev/null
	stadir=/tmp/mshtstsanitycheckunpck
	unpack_tests > /dev/null
	diff -ru $ori/ $stadir/ > sanichecklog.txt
	rm -rf $pckdir/ $stadir/
	if [ -n "$(cat sanichecklog.txt)" ]; then
		echo "Error detected, check sanichecklog.txt for info..."
		return 1
	fi
	rm sanichecklog.txt
	echo "All good, sanity check OK! :D"
	return 0
}

re_place_holder(){
	[ ! -d "$stadir" ] && echo "Stash dir not found. Cannot replace." && return 1
	echo -e "${MAG}"
	sed -i "s@/mnt/nfs/homes/emis/Documents/minishell42tester@$PWD@g" $stadir/*
	echo "\$PWD is now set as \`$PWD' in normal mode! :D"
	sed -i "s@/mnt/nfs/homes/emis@$HOME@g" $stadir/*
	echo "\$HOME is now set as \`$HOME' in normal mode! :D"
	sed -i "s@emis@$USER@g" $stadir/*
	echo "\$USER is now set as \`$USER' in normal mode! :D"
	sed -i "s@\./minishell@$minishell@g" $stadir/*
	echo "\$minishell is now set as \`$minishell' in normal mode! :D"
	echo -e "Replaced all placeholders! :D${NC}"
	return 0
}

first_set_info(){
	echo
	echo -e "${BLU}Why hello there young minishell enthusiast. Ethan here."
	echo -e "As this is the ${GRN}first time${BLU} you set normal mode, I have some ${RED}valuable info${BLU} for you."
	echo
	echo "Your file management WILL differ from mine."
	echo "If you haven't copied your minishell executable in this repo yet, three options are available:"
	echo "1 - You copy it. Manually. Like a chad."
	echo "2 - You change the \$minishell variable in this script to represent the path to your actual executable."
	echo "3 - You change the \$fetchpath variable to allow this tester to automatically fetch your latest executable for you."
	echo
	echo "Same thing for your minishell prompt. Some people go all out and others just don't."
	echo "In any case make sure the \$prompt variable corresponds to your actual prompt (just the beginning is fine)"
	echo "AND that your prompt cannot confuse the tester,"
	echo "I.E. having '\$' as a prompt might invalidate any tests expecting '\$[...]' as an output"
	echo
	echo "Ignore file. Yeah. Useful to skip tests or whole units."
	echo "Just don't forget to use noskip with val and you should be alright."
	echo "Bash pro tip: {1..5} expands to 1 2 3 4 5. Useful if you wanna peek/skip a bunch of consecutive tests."
	echo
	echo "As for the rest, the user interface and man should help you whenever needed."
	echo "If you find any critical blunder on my part, reach out to me ! Email, discord, SMS. Feedback is appreciated."
	echo -e "${NC}"
}

ignore_tests(){
	if [ ! -f "$ignfile" ]; then
	for testname in ${testarray[@]}; do echo "$testname;" >> "$ignfile"; done
	fi
	[ -z "$(grep "$1" "$ignfile")" ] && die "Invalid test unit name. Couldn't ignore."
	to_ignore="$1"
	shift
	for ignore in "$@";
	do
	is_ignored "$to_ignore" "$ignore" || sed -i "s/$to_ignore;/$to_ignore; $ignore ;/" "$ignfile";
	done
	echo "All done! :D"
}

notignore_tests(){
	[ ! -f "$ignfile" ] && die "Ignore file '$ignfile' not found, nothing to not-ignore."
	[ -z "$(grep "$1" "$ignfile")" ] && die "Invalid test unit name. Couldn't ignore."
	to_ignore="$1"
	shift
	for ignore in "$@";
	do
	is_ignored "$to_ignore" "$ignore" && sed -i "s/^$to_ignore;.*$/$(grep "$to_ignore" "$ignfile" | sed "s/; $ignore ;/;/" )/" "$ignfile";
	done
	echo "All done! :D"
}

is_ignored(){
	[ ! -f "$ignfile" ] && return 1
	modifier_set "noskip" && return 1
	[ -n "$(grep "$1" "$ignfile" | grep "; $2 ;")" ] && return 0
	return 1
}

save_log(){
	mkdir -p $savedir
	local dttm="$1"
	[ -z "$dttm" ] && dttm=$(date +"log_%m_%d_%Y@%Hh%Mm%Ss.txt")
	cp $logfile $savedir/$dttm 2> /dev/null || die "Save error. Make sure there is a logfile to be saved."
	echo "Saved! :D"
}

is_shell(){ # simple test to determine if executable is a shell
	local shname="$1"
	local result=$("$shname" -ic "echo I am a shell ! " 2> /dev/null)
	if [ $? -ne 0 ] || [ "$result" != "I am a shell !" ]; then return 1; fi
	return 0
}

generate_test_expectancies(){
	[ -z "$2" ] && local shname="bash"
	{ [ -n "$2" ] && is_shell "$2" && shname="$2" ;} || die "Shell name provided does not work as a shell"
	[ ! -f "$shname$stadir"/"$1"_test ] && die "$1"_test "required for test generation not found :/"
	rm -rf $gendir "/tmp/gentest/"
	mkdir -p $gendir "/tmp/gentest/" "/tmp/gentest/stat/" "/tmp/gentest/out/" "/tmp/gentest/err/"
	readarray arr_test < "$shname$stadir"/"$1"_test
	for (( test=0; test<${#arr_test[@]}; test++ ))
	do
		echo "unset command_not_found_handle" > "/tmp/gentest/$1"
		echo -n "${arr_test[$test]}" | tr '☃' '\n' >> "/tmp/gentest/$1"
		fullnb=$(printf "%03d" $test) # Without leading zeros, ls takes the files 0 then 1 then 10 then 100 then 101 ... etc
		s=$($env $shname -i < "/tmp/gentest/$1" 1> "/tmp/gentest/out/"$1"_out_"$fullnb"" 2> "/tmp/gentest/err/"$1"_err_"$fullnb""; echo $?)
		echo "$s" > "/tmp/gentest/stat/"$1"_stat_"$fullnb""
	done
	for stat in $(ls "/tmp/gentest/stat/")
	do
		cat /tmp/gentest/stat/"$stat" >> "$gendir"/"$1"_stat
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
	local mode="$1"
	if [ -n "$mode" ] && ! is_shell "$1";
	then
		die "Cannot switch to mode; input name isn't a shell."
	fi
	if [ -z "$mode" ];
	then
		[ ! -d $stadir/ ] && { 
			unpack_tests "all" || die "Unpack fail.";
			re_place_holder || die "Placeholder fail.";
			first_set_info;
		} || echo "[Nothing to be done for normal mode]"
	else
		mkdir -p "$mode$stadir"
		for cur in $stadir/*_test
		do
			cp "$cur" $mode$stadir/ || die "Copy fail."
			generate_test_expectancies $(basename "$cur" | sed 's/_test//') "$mode" || return 1
			cp $gendir/* $mode$stadir/ || die "Copy fail."
		done
	fi
	rm -rf $gendir/
	echo "Setup complete, $([ -z "$mode" ] && echo "normal" || echo $mode) mode! :D"
	return 0
}

modifier_set(){
	printf '%s\n' "${mod[@]}" | grep -q -P "^$1$"
	return $?
}

minimalist_tester(){
	for arr in "test" "stat" "out" "err"; do readarray -t arr_"$arr" < "$2$stadir"/"$1"_"$arr"; done
	printf "$1" | tee -a $logfile; echo >> $logfile
	is_ignored "$1" "all" && printf "$ORN SKIPPED $NC\n" && return 0
	local len=$(cat "$2$stadir"/"$1"_test | wc -l)
	for (( test=0; test<$len; test++ ))
	do
		((testnb++))
		is_ignored "$1" "$((test + 1))" && let "++ign" && echo -ne "$ORN.$NC" > /dev/stderr && continue
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
	for arr in "test" "stat" "out" "err"; do readarray -t arr_"$arr" < "$2$stadir"/"$1"_"$arr"; done
	printf "/// $1 tests ///\n" | tee -a $logfile
	is_ignored "$1" "all" && printf "$ORN/// SKIPPED ///$NC\n" && return 0
	local len=$(cat "$2$stadir"/"$1"_test | wc -l)
	for (( test=0; test<$len; test++ ))
	do
		((testnb++))
		is_ignored "$1" "$((test + 1))" && let "++ign" && echo -e "$ORN/// TEST $testnb SKIP ///$NC" > /dev/stderr && continue
		echo -n "${arr_test[$test]}" | tr '☃' '\n' > $testfile
		(comp_test "$testnb" "${arr_stat[$test]}" "${arr_out[$test]}" "${arr_err[$test]}") | tee -a $logfile
		if [ ${PIPESTATUS[0]} -eq 0 ]; then
			((succ++))
			echo -e "$GRN/// TEST $testnb  OK  ///$NC" > /dev/stderr
		else
			echo -e "$RED/// TEST $testnb  KO  ($1 nb $((test + 1)))///$NC" > /dev/stderr
		fi
	done
}

tester(){
	[ ! -d "$1$stadir" ] && die "Dir '$1$stadir' needed for testing missing. Retry after doing 'set' or 'set bash'"
	for testname in ${testarray[@]}
	do
		for arr in "test" "stat" "out" "err"
		do	[ ! -f "$1$stadir"/"$testname"_"$arr" ] && die "File '$1$stadir/$testname"_"$arr'" "needed for testing missing. Retry after doing 'set' or 'set bash'"
		done
	done
	rm -rf $logdir $logfile
	mkdir -p $logdir;
	touch $logfile
	testnb=0
	succ=0
	ign=0
	for testname in ${testarray[@]}
	do
		modifier_set "mini" && minimalist_tester $testname $1 && wait && continue
		modifier_set "quiet" && full_tester $testname $1 > /dev/null && continue
		full_tester $testname $1
	done
	[ -n "$(grep "SEGV" <$logfile)" ] && echo -e "${RED}SEGFAULT${NC} DETECTED! CHECK LOGFILE! X("
	val_error
	echo -e "Your minishell succeeded $GRN$succ$NC out of $(($testnb-$ign)) tests! :D" > /dev/stderr
}

loader(){
	local load=(
		"~~~~~~~~~~~~~~~~~~~~~~~~~"
		"m~i~n~i~s~h~e~l~l~t~e~s~t"
		"▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰"
		" MINI TESTER MINI TESTER "
		"═════════════════════════"
		"m~i~n~i~t~e~s~t~e~r~.~s~h"
		"/^\\_/^\\_/^\\_/^\\_/^\\_/^\\_/"
		"MINISHELLTESTER BY EMIS<3"
		".:*~*:._.:*~*:._.:*~*:._."
		"minitester+val=coffeetime"
		"✎﹏﹏﹏﹏﹏﹏﹏﹏﹏﹏﹏﹏"
		"Minishell is tricky,     "
		"•:•:•:•:•:•☾☼☽•:•.•:•.•:•"
		"This tester is lovely.   "
		"· ·─────── ·𖥸· ───────· ·"
		"Roses are red,           "
		"•────────•°•❀•°•────────•"
		"Violets are blue,        "
		"•☽──────✧˖°˖☆˖°˖✧──────☾•"
		"RTFM or I'll find you >:)"
		"══════════ ⋆★⋆ ══════════"
	)
	local a=0
	local b=0
	echo
	while $(kill -0 $@ 2> /dev/null)
	do printf "\rLoading... ${load[(($b%${#load[@]}))]::((a%50))} $b "; let "a++"; let "b=a/50"; sleep .025
	done
	echo; echo "All done !"
}

best_of_2(){ # two modes at once. Bow to my superior thinking, puny mortal!
	rm -rf $logdir $logfile result1 result2
	local tmpmod=(); for m in "${mod[@]}"; do [ "$m" != "mini" ] && [ "$m" != "quiet" ] && tmpmod+=("$m"); done
	mkdir -p $logdir;
	(
		mod=("${tmpmod[@]}"); logfile=bo2.txt; logdir="$logdir"2; testdir="$testdir"2; gendir=gen2; testfile=testfile2;
		[ -d "bash$stadir" ] || switch_mode "bash" > /dev/null
		tester "bash" 2>&1 | cat > result2
		rm -rf $gendir $logfile $testfile
	) &
	local pid1=$!
	(
		mod=("${tmpmod[@]}"); logfile=bo1.txt; logdir="$logdir"1; testdir="$testdir"1; gendir=gen1; testfile=testfile1;
		[ -d $stadir ] || switch_mode > /dev/null
		tester 2>&1 | cat > result1
		rm -rf $gendir $logfile $testfile
	) &
	local pid2=$!
	# wait
	loader $pid1 $pid2
	touch $logfile
	local goodstuff=0
	local skp=0
	local n=1
	for (( ; n<=$( <result1 grep "/// TEST" | wc -l ); n++ ))
	do
		local stat1=$(grep "TEST $n  OK" <result1 >/dev/null; echo $?)
		local stat2=$(grep "TEST $n  OK" <result2 >/dev/null; echo $?)
		local skip=$(grep "TEST $n SKIP" <result1 >/dev/null; echo $?)
		if [ $stat1 -eq 0 ] || [ $stat2 -eq 0 ]; then
			((goodstuff++))
			modifier_set "mini" && [ $(( $n%80 )) -eq 0 ] && echo "" | tee -a $logfile
			modifier_set "mini" && echo -ne "$GRN.$NC" && continue
			echo -e "$GRN/// TEST $n  $([ $stat1 -eq 0 ] && echo -n "OK" || echo -n "KO" ) $([ $stat2 -eq 0 ] && echo -n "OK" || echo -n "KO" )  ///$NC"
		else
			$(grep "TEST $n  KO" <result1 >>$logfile; grep "^$n:" <result1 >>$logfile; grep "^$n:" <result2 >>$logfile)
			modifier_set "mini" && [ $(( $n%80 )) -eq 0 ] && echo ""
			[ $skip -eq 0 ] && modifier_set "mini" && echo -ne "$ORN.$NC" && let "++skp" && continue
			[ $skip -eq 0 ] && echo -e "$ORN/// TEST $n  SK IP  ///$NC" && let "++skp" && continue
			modifier_set "mini" && echo -ne "$RED.$NC" && continue
			echo -e "$RED/// TEST $n  KO KO  ///$NC"
		fi
	done
	rm -f result1 result2
	[ "$1" = "mini" ] && echo ""
	echo -e "\nDone! :D"
	[ -n "$(grep "SEGV" <$logfile)" ] && echo -e "${RED}SEGFAULT${NC} DETECTED! CHECK LOGFILE! X("
	val_error
	echo "$goodstuff tests out of $(($n-1-$skp)) are OK in at least one of normal or bash mode. Neat."
}

testdescarray=(
	"General
	.B syntaxic
	tests for minishell."
	".B Echo
	builtin."
	".B $
	aka environment variable expansions."
	"Builtin functions 
	.B env, export
	and
	.B unset."
	"Builtin functions
	.B cd
	&
	.B pwd."
	"Builtin function
	.B exit."
	"Various tests for pipes."
	"Tricky stuff."
	"Redirections and other < > >> shenanigans."
	"Here documents. Heredocs. <<. "
	"Bonus part. Parentheses, && and || operators."
	"Bonus part. Wildcard. Jack of all trades. Like me."
)

# HOMEMADE MAN PAGE YUMMERS
get_man(){
man <(printf "%s\n" ".\" Process this file with
.\" groff -man -Tascii foo.1
.\"
.TH MINITESTER.SH 1 "APRIL 2023" Ethan "User Manuals"
.SH NAME
minitester.sh \- test your minishell, test it well.
.SH SYNOPSIS
.B ./minitester.sh options [mode] [batch] [modifier] ...
 
.B ./minitester.sh command [command args]
.SH DESCRIPTION
.B minitester.sh
tests your minishell by giving it a plethora of commands
and comparing its output with either 
.BR normal
or
.BR bash
mode's expected output, depending on which was set.
.SH OPTIONS
.B Options
are
.I associative
(with the exception of the 
.B only
modifier) and thus can be combined many ways to achieve many different testing results.
 
.SS Mode
.P
.B [no mode]
.RS
Normal mode, tester runs minishell against expected results.
.RE
.P
.B bash
.RS
Bash mode, tester runs minishell against results generated when the
.B set
command is used, therefore tests containing any variable expansion
or file exploring 
.RE
.P
.B bo2 [modifier]
.RS
Best Of 2; run
.B normal
and
.B bash
modes simultaneously. Useful to check which tests pass either, or fail both.
.SS Test unit batches
.P
.B r, run, ocd [modifier]
.RS
Run all
.B test units
this tester has, in increasing number of tests order.
.RE
.P
.B m, mandatory [modifier]
.RS
Run all mandatory part test units.
.RE
.P
.B b, bonus [modifier]
.RS
Run all bonus part test units.
.SS Modifiers
.B o, only 
.I testunit1 testunit2
.B ...
.RS
Run all test units specified after 
.B only
or
.B o
keyword. See examples.
.RE
.P
.B mini
.RS
Minimalism.
.RE
.P
.B quiet
.RS
Just the results. Error messages are found in $logfile.
.RE
.P
.B val
.RS
Valgrind. Slows down the tester considerably.
Have yourself a coffee in the meantime.
Recommend using with
.B noskip
as the ignored tests may have leaks you're unaware of.
.RE
.P
.B noskip
.RS
Run without skipping any unit or test from
.B ignore
list.
.RE
.P
.B noenv
.RS
Run with
.B env -i
aka
.B empty env
variable. Useful to check for leaks with missing/unset env variables.
.SH COMMANDS
.B Commands
are handy and necessary
.I tools
for extensive testing.
 
.SS Setup
.P
.B s, set [bash]
.RS
Prepare or generate test files for normal or bash mode.
.SS Filtering
.B i, ignore
.I testunit
.B [ 
.I testnb
.B ] ...
.RS
A more permanent alternative to
.B only
modifier. Specify a
.I test unit
and which
.I test number
to
.B skip
or keyword
.I all
to
.B skip
the unit altogether.
.RE
.P
.B n, notignore
.I testunit
.B [ 
.I testnb
.B ] ...
.RS
Remove units/tests from ignore list.
.SS Cleanup
.B c, clean
.RS
A classic. Cleans up individual logs and other test-related files.
.RE
.P
.B fclean
.RS
Thorough cleaning. Deletes logfile and all log and generated stash directories.
.SS Info
.B man, usage, -h, --help, help, i'm lost, wtf, RTFM
.RS
You're reading it.
.RE
.P
.B u, user, guide, showmetheway
.RS
As an attempt at simplifying the learning curve for this tester,
this simple user interface allows you to run any options or command
(except itself of course) by answering simple questions.
.RE
.P
.B p, peek
.I testunit
.B [ 
.I testnb
.B ] ...
.RS
Have a peek at a test and what outputs it expects. Specify a
.I test unit
, one or many
.I test number
or keyword
.I all
to see all tests. Specify
.B bash
.I before
.B peek
to see bash's generated expectancies instead.
.RE
.P
.B save [
.I logname
.B ]
.RS
Save your
.I $logfile
in the
.I $savedir
directory. Specify a name after
.B save
keyword, default name will
look like
.B log_DD_MM_YYYY@HHhMMmSSs.txt
otherwise.
.RE
.P
.SH FILES
.I $logfile
.RS
The log file containing all test 
.B results.
Can be kept with
.B save
command.
.RE
.I $savedir/
.RS
This directory is never deleted by
.B clean
or
.B fclean
and can allow you to keep logfiles with the
.B save
utilitary.
.RE
.I $logdir/
.RS
The directory containing all test logs.
.RE
.I $testfile
.RS
The test file in which each test is stored to be sent to minishell.
.RE
.I $testdir/
.RS
The directory containing all dummy files for whichever
.B mode
is
.B set
by user.
Bo2 mode creates separate "$testdir"1 and "$testdir"2 directories.
.RE
.I $stadir/
.RS
The directory containing all test files for
.B normal
mode. Tests are fetched from this directory.
.RE
.I bash$stadir/
.RS
The directory containing all test files for
.B bash
mode, if it was set.
.RE
.I $pckdir/
.RS
The directory containing all test files for
.B normal
mode, but in less files, I.E. 1 file per test unit instead of 4.
.RE
.I $ignfile
.RS
The
.B ignore
file in which the ignored test list is stored.
.RE
.SH TEST UNITS
"$(for (( i;i<${#testarray[@]};i++ ))
do	printf "\n.I %s \n.RS \n %s \n.RE \n" "${testarray[i]}" "${testdescarray[i]}";
done)"
.SH EXAMPLES
Here is where all your copypasting needs shall be fulfilled.
 
For starters, run
.B ./minitester.sh set
or 
.B ./minitester.sh set bash
to set a mode.
 
Then, if you are bold enough to try all tests, you can run 
.B ./minitester.sh run
or 
.B ./minitester.sh r
for short.

Granted, this approach might overwhelm your terminal for a bit.
How about something more pallatable, then ?
 
A touch of minimalism will yield a lovely
.B ./minitester mini
command.
 
If, say, you wish to use the
.B bo2 (Best Of Two)
mode, with minimalism in mind again, and only on the bonus part units,
.B ./minitester b mini bo2
or
.B ./minitester mini b bo2
or
.B ./minitester bo2 mini b
and so on are equivalent.
 
However, the
.B only
filter does not allow any other modifier after it, it can
.B only
be followed by
.I test units
by design :
.B ./minitester mini bo2 only syntax echo envvar
or
.B ./minitester quiet o parandor echo tricky
are valid, yet
.B ./minitester o mini man prout
is bound to fail. If
.B mandatory
or
.B bonus
part units are specified before the
.B only
keyword, they shall be overturned by only's specified units.
 
Here is a random example for each option. My treat.
.RS
.IP none 12
.B ./minitester.sh noenv noskip val o dollar envvar
.IP bash
.B ./minitester.sh bash o dollar
.IP bo2
.B ./minitester.sh bo2 mini o echo
.IP run
.B ./minitester.sh ocd mini
.IP mandatory
.B ./minitester.sh m mini
.IP bonus
.B ./minitester.sh bonus quiet
.IP only
.B ./minitester.sh only dollar wildcard tricky
.IP mini
.B ./minitester.sh mini bo2 o envvar parandor
.IP quiet
.B ./minitester.sh quiet mandatory
.IP val
.B ./minitester.sh val m
.IP noenv
.B ./minitester.sh noenv noskip val o dollar envvar
.IP noskip
.B ./minitester.sh noskip mini val
.IP set
.B ./minitester.sh s bash
.IP ignore
.B ./minitester.sh i wildcard all
.IP notignore
.B ./minitester.sh n wildcard all
.IP clean
.B ./minitester.sh c
.IP fclean
.B ./minitester.sh fclean
.IP man
.B ./minitester.sh wtf
.IP user
.B ./minitester.sh showmetheway
.IP peek
.B ./minitester.sh bash peek echo 1 2 3 7 9 32
.IP save
.B ./minitester.sh save veryusefullogfilename.txt
.RE

Go crazy, go stupid. I'm not your dad. Best of all, good luck on your debugging.
.SH BUGS
Please keep in mind this is my third ever bash script,
I am still learning, and would love any feedback or bug report.
 
Legend says using run and man in that order
can cause weird stuff to happen to test units section.
Or any test unit specifier before any command for that matter.
.SH AUTHOR
Ethan Mis <https://github.com/ethanolmethanol>
.SH \"SEE ALSO\"
.BR push_swap42tester,
.BR philosophers42tester")
}

main "$@"
