# Automatically generated by configure - do not modify!
shared=no
build_suffix=
prefix=/Users/ns/Downloads/tvos.mpv.player-master/contrib/FFmpeg-tvOS/thin/x86_64
libdir=${prefix}/lib
incdir=${prefix}/include
rpath=
source_path=/Users/ns/Downloads/tvos.mpv.player-master/contrib/FFmpeg
LIBPREF=lib
LIBSUF=.a
extralibs_avutil="-pthread -lm -framework VideoToolbox -framework CoreFoundation -framework CoreMedia -framework CoreVideo"
extralibs_avcodec="-liconv -lm -pthread -lz -framework VideoToolbox -framework CoreFoundation -framework CoreMedia -framework CoreVideo"
extralibs_avformat="-lm -lbz2 -lz -Wl,-framework,CoreFoundation -Wl,-framework,Security"
extralibs_avdevice="-lm"
extralibs_avfilter="-pthread -lm -framework Metal -framework VideoToolbox -framework CoreFoundation -framework CoreMedia -framework CoreVideo"
extralibs_postproc="-lm"
extralibs_swscale="-lm"
extralibs_swresample="-lm"
avdevice_deps="avfilter swscale postproc avformat avcodec swresample avutil"
avfilter_deps="swscale postproc avformat avcodec swresample avutil"
swscale_deps="avutil"
postproc_deps="avutil"
avformat_deps="avcodec swresample avutil"
avcodec_deps="swresample avutil"
swresample_deps="avutil"
avutil_deps=""
