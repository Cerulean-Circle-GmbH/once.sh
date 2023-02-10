echo "stdout"
>&2 echo "stderr"
echo "/dev/tty" >/dev/tty

#./tty-test.sh > stdout.log
#./tty-test.sh 2> stderr.log
#./tty-test.sh > std-all.log 2>&1

# Does not work
#export LOG_DEVICE=&1
#export LOG_DEVICE=\&1
#export LOG_DEVICE="&1"
#export LOG_DEVICE=stdout