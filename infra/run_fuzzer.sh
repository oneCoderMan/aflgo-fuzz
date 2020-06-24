#!/bin/bash -eu

################################################################################

# Fuzzer runner. Appends .options arguments and seed corpus to users args.
# Usage: $0 <fuzzer_name> <fuzzer_args>

#export PATH=$OUT:$PATH
#cd $OUT
#echo $#
#echo $1
FUZZER=$1
#echo $2
export OUT=$2
#echo $3
export IN=$3
export PATH=$OUT:$PATH
shift 3
#echo $@
cd $OUT
#rm -rf /tmp/input/ && mkdir /tmp/input/
#cp -pr /in/*  /tmp/input    #初始种子
#echo "----------------"
#ls -l  /tmp/input


# https://chromium.googlesource.com/chromium/src/+/master/third_party/afl/src/docs/env_variables.txt
export ASAN_OPTIONS="$ASAN_OPTIONS:abort_on_error=1:symbolize=0"
export MSAN_OPTIONS="$MSAN_OPTIONS:exit_code=86:symbolize=0"
export UBSAN_OPTIONS="$UBSAN_OPTIONS:symbolize=0"
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
export AFL_SKIP_CPUFREQ=1
#  rm -rf /tmp/afl_output && mkdir /tmp/afl_output
  # AFL expects at least 1 file in the input dir.
#  echo input > /tmp/input/input
#  CMD_LINE="$OUT/afl-fuzz $AFL_FUZZER_ARGS -i /tmp/input -o /tmp/afl_output $@ $OUT/$FUZZER"
export AFL_FUZZER_ARGS="-m none -z exp -c 45m"
CMD_LINE="/root/aflgo/afl-fuzz $AFL_FUZZER_ARGS -i $IN -o $OUT  ./$FUZZER $@"


echo $CMD_LINE
bash -c "$CMD_LINE"
