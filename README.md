#      Presentation

### Why ?

**42 School's *minishell*** is an undoubtedly tricky and vast project.

As I happen to be a lazy overachiever, I decided against testing *by hand* a ton, and I **mean** a ***ton*** of different commands and functionalities.

Therefore I made `minitester.sh`, my little monstrosity of a tester. **Over 700 tests on (almost) all aspects** of *minishell*. Can run valgrind's memcheck memory leak detection on all tests. Or run them with `env -i` aka no environment variables. Or both.

### How ?

Clone this repo in your minishell directory. Then use `set`.

I would explain the usage a little, but since I made a whole [man](https://github.com/ethanolmethanol/minishell42tester#usage-aka-man), I assume you know what to do. RTFM. Looks even nicer in the terminal. `./minitester.sh man` :D

Although if you're *lazy* like me, let me tell you I made a cute ***interface*** just for you, dear potential user. `./minitester.sh user`

As for how it works inside, well, bash. Run minishell in a script, i.e. feed it a file containing the lines you want to test, say *testfile*, and gather the stdout and stderr in other file, like so `./minishell < testfile 1> output 2> erroutput`.
Then it's a matter of comparing the output, error output and return status gathered with either pre-existing files with expected results, or with files generated in a similar fashion, but using bash as a reference. If the files somewhat match, the test is ***OK***, otherwise it is ***KO***.

### Who ?

Me, [Ethan](https://github.com/ethanolmethanol). Hello. Nice to meet you.

### Which ?

Well, I will admit I started out thinking the *normal mode* would work nicely, and only made the *bash mode* as a fun side mode. But, as it turned out, bash mode outperforms normal mode in many areas.

But then *bash mode* sometimes compares cases outside the scope of *minishell*'s subject, and, unless your minishell is actually bash in disguise, you may get ***KO***'d.

Eventually, I decided. **Both. Both is good.** *Best of 2 mode* runs both modes allowing you to see which tests are ***OK*** in at least one, or ***KO*** in both.

### When ?

Erm, April 2023 ?

### What for ?

To test minishell. How bad is your attention span ?

### Where ?

...

You may be wondering how I found all those tests. Did I mention my being [lazy](https://github.com/vietdu91/42_minishell#notre-sainte-bible-tant-convoitee-%EF%B8%8F-) ?

#      Appearance

### Interface for newbies
![](https://github.com/ethanolmethanol/minishell42tester/blob/main/img/interface.png)
### Setup
![](https://github.com/ethanolmethanol/minishell42tester/blob/main/img/setbash.png)
### Minimalism, bash mode
![](https://github.com/ethanolmethanol/minishell42tester/blob/main/img/bashmini.png)
### Minimalism, bo2 mode
![](https://github.com/ethanolmethanol/minishell42tester/blob/main/img/bo2mini.png)
### Same, but no skip
![](https://github.com/ethanolmethanol/minishell42tester/blob/main/img/bo2mininoskip.png)
### No env, valgrind
![](https://github.com/ethanolmethanol/minishell42tester/blob/main/img/noenvvalheredoc.png)
### No env, valgrind, quiet
![](https://github.com/ethanolmethanol/minishell42tester/blob/main/img/noenvvalquietdollar.png)

#      Usage aka MAN

## minitester.sh - test your minishell, test it well.

## SYNOPSIS
>       ./minitester.sh options [mode] [batch] [modifier] ...

>       ./minitester.sh command [command args]

## DESCRIPTION
**minitester**.sh tests your minishell by giving it a plethora of commands and comparing its output with either **normal** or **bash** mode's expected output, depending on which was set.

## OPTIONS
**Options** are *associative* (with the exception of the **only** modifier) and thus can be combined many ways to achieve many different testing results.

### Mode

       [no mode]
              Normal mode, tester runs minishell against expected results.

       bash
              Bash mode, tester runs minishell against results generated when the set command is used,
              therefore tests containing any variable expansion or file exploring

       bo2
              Best Of 2; run normal and bash modes simultaneously.
              Useful to check which tests pass either, or fail both.

### Test unit batches

       r, run, ocd
              Run all test units this tester has, in increasing number of tests order.

       m, mandatory
              Run all mandatory part test units.

       b, bonus
              Run all bonus part test units.

### Modifiers
   
       o, only testunit1 testunit2 ...
              Run all test units specified after only or o keyword. See examples.

       mini
              Minimalism.

       quiet
              Just the results. Error messages are found in logfile.txt.

       val
              Valgrind. Slows down the tester considerably.  Have yourself a coffee in the meantime.
              Recommend using with noskip as the ignored tests may have leaks you're unaware of.

       noskip
              Run without skipping any unit or test from ignore list.

       noenv
              Run with env -i aka empty env variable. Useful to check for leaks with missing/unset env variables.

## COMMANDS
**Commands** are handy and necessary tools for *extensive testing*.

### Setup
   
       s, set [bash]
              Prepare or generate test files for normal or bash mode.

### Filtering
   
       i, ignore testunit [ testnb ] ...
              A more permanent alternative to only modifier. Specify a test unit and which test number
              to skip or keyword all to skip the unit altogether.

       n, notignore testunit [ testnb ] ...
              Remove units/tests from ignore list.

### Cleanup
   
       c, clean
              A classic. Cleans up individual logs and other test-related files.

       fclean
              Thorough cleaning. Deletes logfile and all log and generated stash directories.

### Info
   
       man, usage, -h, --help, help, i'm lost, wtf, RTFM
              You're reading it.

       u, user, guide, showmetheway
              As an attempt at simplifying the learning curve for this tester, this simple user interface  allows  you  to
              run any options or command (except itself of course) by answering simple questions.

       p, peek testunit [ testnb ] ...
              Have a peek at a test and what outputs it expects. Specify a test unit , one or many test number
              or keyword all to see all tests. Specify bash before peek to see bash's generated expectancies instead.

       save [ logname ]
              Save your logfile.txt in the save directory. Specify a name after save keyword,
              default name will look like log_DD_MM_YYYY@HHhMMmSSs.txt otherwise.

## TEST UNITS
       syntax
              General syntaxic tests for minishell.
       echo
              Echo builtin.
       dollar
              $ aka environment variable expansions.
       envvar
              Builtin functions env, export and unset.
       cdpwd
              Builtin functions cd & pwd.
       exit
              Builtin function exit.
       pipe
              Various tests for pipes.
       tricky
              Tricky stuff.
       redir
              Redirections and other < > >> shenanigans.
       heredoc
              Here documents.  Heredocs.  <<.
       parandor
              Bonus part.  Parentheses, && and || operators.
       wildcard
              Bonus part.  Wildcard.  Jack of all trades.  Like me.

## EXAMPLES
Here is where all your copypasting needs shall be fulfilled.

For starters, run ./minitester.sh set or ./minitester.sh set bash to set a mode.

Then, if you are bold enough to try all tests, you can run ./minitester.sh run or ./minitester.sh r for short.

Granted, this approach might overwhelm your terminal for a bit.  How about something more pallatable, then ?

A touch of minimalism will yield a lovely ./minitester mini command.

If, say, you wish to use the bo2 (Best Of Two) mode, with minimalism in mind again, and only on the bonus part units, ./minitester b mini bo2 or ./minitester mini b bo2 or ./minitester bo2 mini b and so on are equivalent.

However,  the  only  filter does not allow any other modifier after it, it can only be followed by test units by design : ./minitester mini bo2 only syntax echo envvar or ./minitester quiet o parandor echo tricky are valid, yet ./minitester o mini man prout is
       bound to fail. If mandatory or bonus part units are specified before the only keyword, they shall be overturned by only's specified units.

Here is a random example for each option. My treat.

              none        ./minitester.sh noenv noskip val o dollar envvar

              bash        ./minitester.sh bash o dollar

              bo2         ./minitester.sh bo2 mini o echo

              run         ./minitester.sh ocd mini

              mandatory   ./minitester.sh m mini

              bonus       ./minitester.sh bonus quiet

              only        ./minitester.sh only dollar wildcard tricky

              mini        ./minitester.sh mini bo2 o envvar parandor

              quiet       ./minitester.sh quiet mandatory

              val         ./minitester.sh val m

              noenv       ./minitester.sh noenv noskip val o dollar envvar

              noskip      ./minitester.sh noskip mini val

              set         ./minitester.sh s bash

              ignore      ./minitester.sh i wildcard all

              notignore   ./minitester.sh n wildcard all

              clean       ./minitester.sh c

              fclean      ./minitester.sh fclean

              man         ./minitester.sh wtf

              user        ./minitester.sh showmetheway

              peek        ./minitester.sh bash peek echo 1 2 3 7 9 32

              save        ./minitester.sh save veryusefullogfilename.txt

Go crazy, go stupid. I'm not your dad. Best of all, good luck on your debugging.

## BUGS
Please keep in mind this is my third ever bash script, I am still learning, and would love any feedback or bug report.

Legend says using run and man in that order can cause weird stuff to happen to test units section.  Or any test unit specifier before any command for that matter.

## AUTHOR
Ethan Mis <https://github.com/ethanolmethanol>

## SEE ALSO
push_swap42tester, philosophers42tester
