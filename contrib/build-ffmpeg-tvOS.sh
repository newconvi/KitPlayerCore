#!/bin/sh


# directories

SOURCE="FFmpeg"
FAT="FFmpeg-tvOS"
SCRATCH=$FAT/"scratch"
# must be an absolute path
THIN=`pwd`/$FAT/"thin"


# absolute path to x264 library
#X264=`pwd`/fat-x264

#FDK_AAC=`pwd`/../fdk-aac-build-script-for-iOS/fdk-aac-ios

CONFIGURE_FLAGS="--enable-cross-compile --disable-debug --disable-programs --disable-indev=avfoundation \
--disable-doc --enable-pic --disable-shared --enable-static --enable-videotoolbox --disable-audiotoolbox --disable-encoders \
--disable-decoders --enable-decoder=aac --enable-decoder=pcm* --enable-decoder=ac3* --enable-decoder=eac3* --enable-decoder=mp3 --enable-decoder=vp* --enable-decoder=h264 --enable-decoder=hevc --enable-decoder=opus --enable-decoder=mpeg4* --enable-decoder=flac --enable-decoder=pgssub --enable-decoder=ass --enable-decoder=subrip --enable-decoder=ssa \
--disable-hwaccels --enable-hwaccel=h263_videotoolbox --enable-hwaccel=hevc_videotoolbox --enable-hwaccel=mpeg4_videotoolbox --enable-hwaccel=vp9_videotoolbox --enable-hwaccel=h264_videotoolbox \
--disable-demuxers --enable-demuxer=aac --enable-demuxer=flac --enable-demuxer=live_flv --enable-demuxer=ac3 --enable-demuxer=truehd --enable-demuxer=flv --enable-demuxer=rtp --enable-demuxer=rtsp --enable-demuxer=ogg --enable-demuxer=m4v --enable-demuxer=matroska --enable-demuxer=pcm* --enable-demuxer=h263 --enable-demuxer=h264 --enable-demuxer=h261 --enable-demuxer=mov --enable-demuxer=wav --enable-demuxer=mp3 --enable-demuxer=hevc --enable-demuxer=hls --enable-demuxer=webvtt --enable-demuxer=mpegps --enable-demuxer=mpegts --enable-demuxer=srt --enable-demuxer=ass --enable-demuxer=dvbsub --enable-demuxer=dvbtxt --enable-demuxer=eac3 --enable-demuxer=av1 --enable-demuxer=avi \
--disable-muxers"

# avresample
#CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-avresample"


echo $CONFIGURE_FLAGS


ARCHS="arm64 x86_64"

COMPILE="y"
LIPO="y"

DEPLOYMENT_TARGET="10.2"

if [ "$*" ]
then
	if [ "$*" = "lipo" ]
	then
		# skip compile
		COMPILE=
	else
		ARCHS="$*"
		if [ $# -eq 1 ]
		then
			# skip lipo
			LIPO=
		fi
	fi
fi

if [ "$COMPILE" ]
then
	if [ ! `which yasm` ]
	then
		echo 'Yasm not found'
		if [ ! `which brew` ]
		then
			echo 'Homebrew not found. Trying to install...'
                        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
				|| exit 1
		fi
		echo 'Trying to install Yasm...'
		brew install yasm || exit 1
	fi
	if [ ! `which gas-preprocessor.pl` ]
	then
		echo 'gas-preprocessor.pl not found. Trying to install...'
		(curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
			-o /usr/local/bin/gas-preprocessor.pl \
			&& chmod +x /usr/local/bin/gas-preprocessor.pl) \
			|| exit 1
	fi

	if [ ! -r $SOURCE ]
	then
		echo 'FFmpeg source not found. Trying to download...'
#        curl http://www.ffmpeg.org/releases/$SOURCE.tar.bz2 | tar xj \
#            || exit 1
        git clone https://github.com/FFmpeg/FFmpeg.git;
	fi

	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		CFLAGS="-arch $ARCH"
		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="appleTVSimulator"
		    CFLAGS="$CFLAGS -mtvos-simulator-version-min=$DEPLOYMENT_TARGET"
		else
		    PLATFORM="appleTVOS"
		    CFLAGS="$CFLAGS -mtvos-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
		    if [ "$ARCH" = "arm64" ]
		    then
		        EXPORT="GASPP_FIX_XCODE5=1"
		    fi
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang"

		# force "configure" to use "gas-preprocessor.pl" (FFmpeg 3.3)
		if [ "$ARCH" = "arm64" ]
		then
		    AS="gas-preprocessor.pl -arch aarch64 -- $CC"
		else
		    AS="$CC"
		fi

		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"
		if [ "$X264" ]
		then
			CFLAGS="$CFLAGS -I$X264/include"
			LDFLAGS="$LDFLAGS -L$X264/lib"
		fi
		if [ "$FDK_AAC" ]
		then
			CFLAGS="$CFLAGS -I$FDK_AAC/include"
			LDFLAGS="$LDFLAGS -L$FDK_AAC/lib"
		fi


        TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
            --target-os=darwin \
            --arch=$ARCH \
            --cc="$CC" \
            --as="$AS" \
            $CONFIGURE_FLAGS \
            --extra-cflags="$CFLAGS" \
            --extra-ldflags="$LDFLAGS" \
            --prefix="$THIN/$ARCH" \
        || exit 1

#        make -j3 install $EXPORT ||exit 1
         make -j3 install || exit 1
		cd $CWD
	done
fi

if [ "$LIPO" ]
then
	echo "building fat binaries..."
	mkdir -p $FAT/lib
	set - $ARCHS
	CWD=`pwd`
	cd $THIN/$1/lib
	for LIB in *.a
	do
		cd $CWD
		echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1
	done

	cd $CWD
	cp -rf $THIN/$1/include $FAT
fi

echo Done
