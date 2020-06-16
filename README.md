# OSS-Fuzz integrated with AFLGo for Patch Testing

1) Install Docker (Ubuntu 16.04):
  Follow instructions in Step.1 and Step.2 <a href="https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04" target="_blank">here</a> or <a href="https://docs.docker.com/engine/installation/" target="_blank">here</a>.
2) Prepare the Docker infrastructure:
```bash
# Checkout our integration
git clone https://github.com/aflgo/oss-fuzz.git
OSS=$PWD/oss-fuzz

# Build necessary Docker images. Meanwhile, go have a coffee ☕️
cd oss-fuzz
infra/base-images/all.sh
```
3) Let us take the <a href="http://www.darwinsys.com/file/" target="_blank">file</a>-utility as subject and focus on commit <a href="https://github.com/file/file/commit/69928a2" target="_blank">69928a2</a>.
```bash
subject=file
commit=69928a2

# Compile the version of file after commit 69928a2
cd $OSS
infra/helper.py build_fuzzers --engine aflgo -c $commit $subject

# Find the compiled binary in the "build" directory. 
ls build/out/$subject/$commit
```

4) If the directory `$OSS/build/out/$subject/$commit` contains the file `distance.cfg.txt`, the instrumentation was successful. The instrumentation may be unsuccessful i) if the commit changes only non-executable lines (e.g., comments), ii) or if the compilation of that version fails. Sometimes older versions cannot be built.

5) Let's try to compile the binaries for the 100 most recent code-changing commits of the <a href="http://www.darwinsys.com/file/" target="_blank">file</a>-utility.
```bash
# Checkout the subject program
git clone https://github.com/file/file.git
SUBJECT=$PWD/file

# Find 100 most recent code-changing commits
cd $SUBJECT
COMMITS=$(git log --pretty=format:"%h" -- "*.c" | head -n 100)

# Build subject binaries for those commits
# Make sure you have enough cores. Otherwise build in batches.
cd $OSS
for commit in $COMMITS; do 

  # Build in detached mode (-d)
  infra/helper.py build_fuzzers -d --engine aflgo -c $commit $subject
  sleep 10
  
done
```
6) Let's start an instance of AFLGo for commit <a href="https://github.com/file/file/commit/69928a2" target="_blank">69928a2</a>.
```bash
subject=file
commit=69928a2
testdriver=magic_fuzzer

# Checkout AFLGo
git clone https://github.com/aflgo/aflgo.git
AFLGO=$PWD/aflgo
cd aflgo && make && cd ..

# Prepare seed corpus for file-utility
mkdir in
find $AFLGO/testcases/ -type f -exec cp {} in \;

# Run the fuzzer
# * We set the exponential annealing-based power schedule (-z exp).
# * We set the time-to-exploitation to 45min (-c 45m), assuming the fuzzer is run for about an hour.
$AFLGO/afl-fuzz -S $commit -i in -o out -m none -z exp -c 45m \
       $OSS/build/out/$subject/$commit/$testdriver
```
7) Let's run AFLGo on all successfully instrumented commits simultaneously, sharing the same queue. Make sure that you have enough cores. Otherwise, e.g., `COMMITS=$(echo "$COMMITS" | head -n$(nproc))`.
```bash
COMMITS=$(find $OSS/build/out/$subject/* -name "distance*" | grep -v master | rev | cut -d/ -f2 | rev)

for commit in $COMMITS; do 
  $AFLGO/afl-fuzz -S $commit -i in -o out -m none -z exp -c 45m \
         $OSS/build/out/$subject/$commit/$testdriver >/dev/null &
  sleep 2
done
```
8) Let's check how our fuzzers are doing. You can kill all instances using `pkill afl`.
```bash
$AFLGO/afl-whatsup out
```
9) You can find all subjects that have been integrated into OSS-Fuzz <a href="https://github.com/google/oss-fuzz/tree/master/projects" target="_blank">here</a>. The corresponding repo can often be found in the project's Dockerfile.
```bash
ls $OSS/projects
tail $OSS/projects/file/Dockerfile
```


# OSS-Fuzz - Continuous Fuzzing for Open Source Software

> *Status*: Beta. We are now accepting applications from widely-used open source projects.

[FAQ](docs/faq.md)
| [Ideal Fuzzing Integration](docs/ideal_integration.md)
| [New Project Guide](docs/new_project_guide.md)
| [Reproducing Bugs](docs/reproducing.md)
| [Projects](projects)
| [Projects Issue Tracker](https://bugs.chromium.org/p/oss-fuzz/issues/list)
| [Glossary](docs/glossary.md)


[Create New Issue](https://github.com/google/oss-fuzz/issues/new) for questions or feedback about OSS-Fuzz.

## Introduction

[Fuzz testing](https://en.wikipedia.org/wiki/Fuzz_testing) is a well-known
technique for uncovering various kinds of programming errors in software.
Many of these detectable errors (e.g. [buffer overflow](https://en.wikipedia.org/wiki/Buffer_overflow)) can have serious security implications.

We successfully deployed 
[guided in-process fuzzing of Chrome components](https://security.googleblog.com/2016/08/guided-in-process-fuzzing-of-chrome.html)
and found [hundreds](https://bugs.chromium.org/p/chromium/issues/list?can=1&q=label%3AStability-LibFuzzer+-status%3ADuplicate%2CWontFix) of security vulnerabilities and stability bugs. We now want to share the experience and the service with the open source community. 

In cooperation with the [Core Infrastructure Initiative](https://www.coreinfrastructure.org/), 
OSS-Fuzz aims to make common open source software more secure and stable by
combining modern fuzzing techniques and scalable
distributed execution.

At the first stage of the project we use
[libFuzzer](http://llvm.org/docs/LibFuzzer.html) with
[Sanitizers](https://github.com/google/sanitizers). More fuzzing engines will be added later.
[ClusterFuzz](docs/clusterfuzz.md)
provides a distributed fuzzer execution environment and reporting.

Currently OSS-Fuzz supports C and C++ code (other languages supported by [LLVM](http://llvm.org) may work too).

## Process Overview

![diagram](docs/images/process.png?raw=true)

The following process is used for projects in OSS-Fuzz:

- A maintainer of an opensource project or an outside volunteer creates
one or more [fuzz targets](http://libfuzzer.info/#fuzz-target) 
and [integrates](docs/ideal_integration.md) them with the project's build and test system.
- The project is [accepted to OSS-Fuzz](#accepting-new-projects).
- When [ClusterFuzz](docs/clusterfuzz.md) finds a bug, an issue is automatically
  reported in the OSS-Fuzz [issue tracker](https://bugs.chromium.org/p/oss-fuzz/issues/list) 
  ([example](https://bugs.chromium.org/p/oss-fuzz/issues/detail?id=9)).
  ([Why use a different tracker?](docs/faq.md#why-do-you-use-a-different-issue-tracker-for-reporting-bugs-in-oss-projects)).
  Project owners are CC-ed to the bug report.
- The project developer fixes the bug upstream and credits OSS-Fuzz for the discovery (commit message should contain
  the string **'Credit to OSS-Fuzz'**).
- [ClusterFuzz](docs/clusterfuzz.md) automatically verifies the fix, adds a comment and closes the issue ([example](https://bugs.chromium.org/p/oss-fuzz/issues/detail?id=53#c3)).
- 30 days after the fix is verified or 90 days after reporting (whichever is earlier), the issue becomes *public*
  ([guidelines](#bug-disclosure-guidelines)).

<!-- NOTE: this anchor is referenced by oss-fuzz blog post -->
## Accepting New Projects

To be accepted to OSS-Fuzz, an open-source project must 
have a significant user base and/or be critical to the global IT infrastructure.
To submit a new project:
- [Create a pull request](https://help.github.com/articles/creating-a-pull-request/) with new 
`projects/<project_name>/project.yaml` file ([example](projects/libarchive/project.yaml)) giving at least the following information:
  * project homepage.
  * e-mail of the engineering contact person to be CCed on new issues. This
    email should be  
    [linked to a Google Account](https://support.google.com/accounts/answer/176347?hl=en)
    ([why?](docs/faq.md#why-do-you-require-an-e-mail-associated-with-a-google-account))
    and belong to an established project committer (according to VCS logs).
    If this is not you or the email address differs from VCS, an informal e-mail verification will be required.
  * Note that `project_name` can only contain alphanumeric characters, underscores(_) or dashes(-).
- Once accepted by an OSS-Fuzz project member, follow the [New Project Guide](docs/new_project_guide.md)
  to configure your project.


## Bug Disclosure Guidelines

Following [Google's standard disclosure policy](https://googleprojectzero.blogspot.com/2015/02/feedback-and-data-driven-updates-to.html)
OSS-Fuzz will adhere to following disclosure principles:
  - **Deadline**. After notifying project authors, we will open reported
    issues to the public in 90 days, or 30 days after the fix is released 
    (whichever comes earlier).
  - **Weekends and holidays**. If a deadline is due to expire on a weekend,
    the deadline will be moved to the next normal work day.
  - **Grace period**. We have a 14-day grace period. If a 90-day deadline
    expires but the upstream engineers let us know before the deadline that a
    patch is scheduled for release on a specific day within 14 days following
    the deadline, the public disclosure will be delayed until the availability
    of the patch.

## More Documentation

* [Glossary](docs/glossary.md) describes the common terms used in OSS-Fuzz.
* [New Project Guide](docs/new_project_guide.md) walks through the steps necessary to add new projects to OSS-Fuzz.
* [Ideal Integration](docs/ideal_integration.md) describes the steps to integrate fuzz targets with your project.
* [Accessing corpora](docs/corpora.md) describes how to access the corpora we use for fuzzing.
* [Fuzzer execution environment](docs/fuzzer_environment.md) documents the
  environment under which your fuzzers will be run.
* [Projects](projects) lists OSS projects currently analyzed by OSS-Fuzz.
* [Chrome's Efficient Fuzzer Guide](https://chromium.googlesource.com/chromium/src/testing/libfuzzer/+/HEAD/efficient_fuzzer.md) 
  while containing some Chrome-specific bits, is an excellent guide to making your fuzzer better.
* Blog posts: 
  * 2016-12-01 ([1](https://opensource.googleblog.com/2016/12/announcing-oss-fuzz-continuous-fuzzing.html),
[2](https://testing.googleblog.com/2016/12/announcing-oss-fuzz-continuous-fuzzing.html),
[3](https://security.googleblog.com/2016/12/announcing-oss-fuzz-continuous-fuzzing.html))
  * 2017-05-08 ([1](https://opensource.googleblog.com/2017/05/oss-fuzz-five-months-later-and.html),
[2](https://testing.googleblog.com/2017/05/oss-fuzz-five-months-later-and.html),
[3](https://security.googleblog.com/2017/05/oss-fuzz-five-months-later-and.html))

## Build Status
[This page](https://oss-fuzz-build-logs.storage.googleapis.com/index.html)
gives the latest build logs for each project.

## Trophies

[This page](https://bugs.chromium.org/p/oss-fuzz/issues/list?can=1&q=status%3AFixed%2CVerified+Type%3ABug%2CBug-Security+-component%3AInfra+)
gives a list of publicly-viewable fixed bugs found by OSS-Fuzz.

## References
* [libFuzzer documentation](http://libfuzzer.info)
* [libFuzzer tutorial](http://tutorial.libfuzzer.info)
* [libFuzzer workshop](https://github.com/Dor1s/libfuzzer-workshop)
* [Chromium Fuzzing Page](https://chromium.googlesource.com/chromium/src/testing/libfuzzer/)
* [ClusterFuzz](https://blog.chromium.org/2012/04/fuzzing-for-security.html)

