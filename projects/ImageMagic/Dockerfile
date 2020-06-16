
FROM hust-fuzz-base/base-builder
MAINTAINER your@email.com
#可以在此处添加开发者特定需要的库

#RUN git clone --depth 1 <git_url> upx     # or use other version control
#RUN git clone --depth=1 https://gitee.com/truelq/upx.git
RUN git clone https://github.com/ImageMagick/ImageMagick.git
RUN git checkout f2c9bdb8
#COPY upx $SRC/upx/
WORKDIR ImageMagick
COPY build.sh $SRC/
