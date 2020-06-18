pwd
#cd upx
./autogen.sh
make distclean
./configure
make clean
make -j4