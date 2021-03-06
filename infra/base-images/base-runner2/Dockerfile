# Copyright 2016 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

FROM hust-fuzz-base/base-clang
MAINTAINER mike.aizatsky@gmail.com
RUN  sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
#RUN apt-get clean
RUN apt-get update

RUN apt-get install -y zip file libunwind8 binutils libblocksruntime0 wget
RUN apt-get install -y git subversion jq python3 zip make libunwind8-dev binutils-dev libblocksruntime-dev gawk python3-pip vim && \
    pip3 install --upgrade pip && \
    pip3 install networkx && \
    pip3 install pydot && \
    pip3 install pydotplus && \
    ln -s $(which python3) /usr/bin/python


COPY bad_build_check llvm-symbolizer reproduce run_fuzzer sancov test_all \
    test_report compile_aflgo compile_afl /usr/local/bin/

RUN chmod +x /usr/local/bin/bad_build_check \
    /usr/local/bin/llvm-symbolizer \
    /usr/local/bin/reproduce \
    /usr/local/bin/run_fuzzer \
    /usr/local/bin/sancov \
    /usr/local/bin/test_all \
    /usr/local/bin/test_report \
    /usr/local/bin/compile_aflgo \
    /usr/local/bin/compile_afl

# Default environment options for various sanitizers.
# Note that these match the settings used in ClusterFuzz and
# shouldn't be changed unless a corresponding change is made on
# ClusterFuzz side as well.
#ENV ASAN_OPTIONS="alloc_dealloc_mismatch=0:allocator_may_return_null=1:allocator_release_to_os_interval_ms=500:check_malloc_usable_size=0:detect_container_overflow=1:detect_odr_violation=0:detect_leaks=1:detect_stack_use_after_return=1:fast_unwind_on_fatal=0:handle_abort=1:handle_segv=1:handle_sigill=1:max_uar_stack_size_log=16:print_scariness=1:quarantine_size_mb=10:strict_memcmp=1:strict_string_check=1:strip_path_prefix=/workspace/:symbolize=1:use_sigaltstack=1"
#ENV MSAN_OPTIONS="print_stats=1:strip_path_prefix=/workspace/:symbolize=1"
#ENV UBSAN_OPTIONS="halt_on_error=1:print_stacktrace=1:print_summary=1:strip_path_prefix=/workspace/:symbolize=1"
#ENV FUZZER_ARGS="-rss_limit_mb=2048 -timeout=25"
#ENV AFL_FUZZER_ARGS="-m none"
ENV AFL_FUZZER_ARGS="-m none -z exp -c 45m"
ENV IN=/in

RUN /usr/local/bin/compile_aflgo
RUN /usr/local/bin/compile_afl
