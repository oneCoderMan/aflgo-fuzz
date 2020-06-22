pwd
#cd upx
export LDFLAGS=-lpthread
./autogen.sh
./configure --disable-shared
make clean
make
cp ./util/swftophp $OUT/