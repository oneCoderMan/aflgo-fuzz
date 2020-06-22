
FROM hust-fuzz-base/base-builder
MAINTAINER your@email.com
#可以在此处添加开发者特定需要的库



RUN git clone https://github.com/oneCoderMan/test.git


WORKDIR test
COPY build.sh $SRC/
COPY BBtargets.txt $SRC/
