#!/bin/bash
set -euo pipefail

fn_git_clean() {
  git clean -xdf
  git checkout .
}

OUT_DIR="$PWD/out"
ROOT="$PWD"
EMCC_FLAGS_DEBUG="-Os -g3"
EMCC_FLAGS_RELEASE="-Oz -flto"

export CPPFLAGS="-I$OUT_DIR/include"
export LDFLAGS="-L$OUT_DIR/lib"
export PKG_CONFIG_PATH="$OUT_DIR/lib/pkgconfig"
export EM_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
export CFLAGS="-pthread $EMCC_FLAGS_RELEASE"
export CXXFLAGS="$CFLAGS"
export TOOLCHAIN_FILE="$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake"
export STRIP="llvm-strip"

mkdir -p "$OUT_DIR"

cd "$ROOT/lib/zlib"
fn_git_clean
chmod +x configure
emconfigure ./configure --prefix="$OUT_DIR" --static
emmake make -j install

cd "$ROOT/lib/x264"
fn_git_clean
emconfigure ./configure \
  --prefix="$OUT_DIR" \
  --host=i686-gnu \
  --enable-static \
  --disable-cli \
  --disable-asm \
  --extra-cflags="$CFLAGS"
emmake make -j install

cd "$ROOT/lib/x265/source"
fn_git_clean
mkdir -p build
cd build
mkdir -p main 10bit 12bit
cd 12bit
emmake cmake ../.. \
  -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
  -DENABLE_LIBNUMA=OFF \
  -DENABLE_SHARED=OFF \
  -DENABLE_CLI=OFF \
  -DHIGH_BIT_DEPTH=ON \
  -DEXPORT_C_API=OFF \
  -DMAIN12=ON
emmake make -j
cd ../10bit 
emmake cmake ../.. \
  -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
  -DENABLE_LIBNUMA=OFF \
  -DENABLE_SHARED=OFF \
  -DENABLE_CLI=OFF \
  -DHIGH_BIT_DEPTH=ON \
  -DEXPORT_C_API=OFF
emmake make -j
cd ../main
ln -sf ../10bit/libx265.a libx265_main10.a
ln -sf ../12bit/libx265.a libx265_main12.a
emmake cmake ../.. \
  -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
  -DENABLE_LIBNUMA=OFF \
  -DENABLE_SHARED=OFF \
  -DENABLE_CLI=OFF \
  -DCMAKE_INSTALL_PREFIX="$OUT_DIR" \
  -DEXTRA_LIB="x265_main10.a;x265_main12.a" \
  -DEXTRA_LINK_FLAGS=-L. \
  -DLINKED_10BIT=ON \
  -DLINKED_12BIT=ON
emmake make -j
mv libx265.a libx265_main.a
emar -M <<EOF
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF
emmake make install -j

cd "$ROOT/lib/libvpx"
fn_git_clean
emconfigure ./configure \
  --prefix="$OUT_DIR" \
  --target=generic-gnu \
  --disable-install-bins \
  --disable-examples \
  --disable-tools \
  --disable-docs \
  --disable-unit-tests \
  --disable-dependency-tracking \
  --extra-cflags="$CFLAGS" \
  --extra-cxxflags="$CXXFLAGS"
emmake make -j install

cd "$ROOT/lib/WavPack"
fn_git_clean
emconfigure ./autogen.sh \
  --prefix="$OUT_DIR" \
  --host=x86-linux-gnu \
  --disable-asm \
  --disable-man \
  --disable-tests \
  --disable-apps \
  --disable-dsd \
  --enable-legacy \
  --disable-shared \
  --disable-dependency-tracking \
  --disable-maintainer-mode
emmake make -j install

cd "$ROOT/lib/lame"
fn_git_clean
emconfigure ./configure \
  --prefix="$OUT_DIR" \
  --host=i686-linux \
  --disable-shared \
  --disable-frontend \
  --disable-analyzer-hooks \
  --disable-dependency-tracking \
  --disable-gtktest
emmake make -j install

cd "$ROOT/lib/fdk-aac"
fn_git_clean
emconfigure ./autogen.sh
emconfigure ./configure \
  --prefix="$OUT_DIR" \
  --host=x86_64-linux \
  --disable-shared \
  --disable-dependency-tracking
emmake make -j install

cd "$ROOT/lib/ogg"
fn_git_clean
emconfigure ./autogen.sh
emconfigure ./configure \
  --prefix="$OUT_DIR" \
  --host=i686-linux \
  --disable-shared \
  --disable-dependency-tracking \
  --disable-maintainer-mode
emmake make -j install

cd "$ROOT/lib/vorbis"
fn_git_clean
sed -i 's/ -mno-ieee-fp//g' configure.ac
emconfigure ./autogen.sh
emconfigure ./configure \
  --prefix="$OUT_DIR" \
  --host=i686-linux \
  --enable-shared=no \
  --enable-docs=no \
  --enable-examples=no \
  --enable-fast-install=no \
  --disable-oggtest \
  --disable-dependency-tracking
emmake make -j install

cd "$ROOT/lib/theora"
fn_git_clean
emconfigure ./autogen.sh \
  --prefix="$OUT_DIR" \
  --host=i686-linux \
  --enable-shared=no \
  --enable-docs=no \
  --enable-fast-install=no \
  --disable-spec \
  --disable-asm \
  --disable-examples \
  --disable-oggtest \
  --disable-vorbistest \
  --disable-sdltest
emmake make -j install

cd "$ROOT/lib/opus"
fn_git_clean
emconfigure ./autogen.sh
emconfigure ./configure \
  --prefix="$OUT_DIR" \
  --host=i686-gnu \
  --enable-shared=no \
  --disable-asm \
  --disable-rtcd \
  --disable-doc \
  --disable-extra-programs \
  --disable-stack-protector
emmake make -j install

cd "$ROOT/lib/libwebp"
fn_git_clean
mkdir -p build
cd build
emmake cmake .. \
  -DCMAKE_C_FLAGS="$CXXFLAGS" \
  -DCMAKE_INSTALL_PREFIX="$OUT_DIR" \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
  -DBUILD_SHARED_LIBS=OFF \
  -DWEBP_ENABLE_SIMD=OFF \
  -DWEBP_BUILD_ANIM_UTILS=OFF \
  -DWEBP_BUILD_CWEBP=OFF \
  -DWEBP_BUILD_DWEBP=OFF \
  -DWEBP_BUILD_GIF2WEBP=OFF \
  -DWEBP_BUILD_IMG2WEBP=OFF \
  -DWEBP_BUILD_VWEBP=OFF \
  -DWEBP_BUILD_WEBPINFO=OFF \
  -DWEBP_BUILD_WEBPMUX=OFF \
  -DWEBP_BUILD_EXTRAS=OFF
emmake make -j install

cd "$ROOT/lib/freetype2"
fn_git_clean
emconfigure ./autogen.sh
emconfigure ./configure \
  --prefix="$OUT_DIR" \
  --host=x86_64-gnu \
  --enable-shared=no \
  --without-harfbuzz
# build apinames manually to prevent it built by emcc
gcc -o objs/apinames src/tools/apinames.c
emmake make -j install

cd "$ROOT/lib/fribidi"
fn_git_clean
emconfigure ./autogen.sh \
  --prefix="$OUT_DIR" \
  --host=x86_64-linux \
  --enable-shared=no \
  --enable-static=yes \
  --disable-dependency-tracking \
  --disable-debug
$( emmake make -j install ) || true
cp fribidi.pc "$OUT_DIR/lib/pkgconfig"

cd "$ROOT/lib/harfbuzz"
fn_git_clean
emconfigure ./autogen.sh \
  CFLAGS="$CFLAGS -DHB_NO_PRAGMA_GCC_DIAGNOSTIC_ERROR" \
  CXXFLAGS="$CXXFLAGS -DHB_NO_PRAGMA_GCC_DIAGNOSTIC_ERROR" \
  --prefix="$OUT_DIR" \
  --host=i686-gnu \
  --enable-shared=no \
  --enable-static
emmake make -j install

cd "$ROOT/lib/libass"
fn_git_clean
./autogen.sh
emconfigure ./configure \
  CFLAGS="$CFLAGS -DHB_NO_PRAGMA_GCC_DIAGNOSTIC_ERROR" \
  --prefix="$OUT_DIR" \
  --host=i686-gnu \
  --disable-shared \
  --enable-static \
  --disable-asm \
  --disable-fontconfig \
  --disable-require-system-font-provider
emmake make -j install

cd "$ROOT/lib/FFmpeg"
fn_git_clean
emconfigure ./configure \
  --prefix="$OUT_DIR" \
  --target-os=none \
  --arch=x86_32 \
  --enable-cross-compile \
  --disable-x86asm \
  --disable-inline-asm \
  --disable-stripping \
  --disable-programs \
  --disable-doc \
  --disable-debug \
  --disable-runtime-cpudetect \
  --disable-autodetect \
  --extra-cflags="$CFLAGS" \
  --extra-cxxflags="$CFLAGS" \
  --extra-ldflags="$LDFLAGS" \
  --pkg-config-flags="--static" \
  --nm="llvm-nm" \
  --ar=emar \
  --ranlib=emranlib \
  --cc=emcc \
  --cxx=em++ \
  --objcc=emcc \
  --dep-cc=emcc \
  --enable-gpl \
  --enable-nonfree \
  --enable-zlib \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libwavpack \
  --enable-libmp3lame \
  --enable-libfdk-aac \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libfreetype \
  --enable-libopus \
  --enable-libwebp \
  --enable-libass \
  --enable-libfribidi
emmake make -j install

mkdir -p "$ROOT/dist"
cd "$ROOT/lib/FFmpeg"
emcc \
  ${CFLAGS} \
  ${CPPFLAGS} \
  ${LDFLAGS} \
  -I. -I./fftools \
  -Wno-deprecated-declarations -Wno-pointer-sign -Wno-implicit-int-float-conversion -Wno-switch -Wno-parentheses -Qunused-arguments \
  -lavdevice -lavfilter -lavformat -lavcodec -lswresample -lswscale -lavutil -lpostproc -lm -lharfbuzz -lfribidi -lass -lx264 -lx265 -lvpx -lwavpack -lmp3lame -lfdk-aac -lvorbis -lvorbisenc -lvorbisfile -logg -ltheora -ltheoraenc -ltheoradec -lz -lfreetype -lopus -lwebp \
  -lnodefs.js -lworkerfs.js \
  fftools/ffmpeg_opt.c \
  fftools/ffmpeg_filter.c \
  fftools/ffmpeg_hw.c \
  fftools/cmdutils.c \
  fftools/ffmpeg.c \
  --pre-js "$ROOT/js/pre.js" \
  --post-js "$ROOT/js/post.js" \
  --closure 1 \
  -s INITIAL_MEMORY=67108864 \
  -s WASM_BIGINT=1 \
  -s PROXY_TO_PTHREAD=1 \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s EXPORTED_RUNTIME_METHODS='["callMain","FS","NODEFS","WORKERFS","ENV"]' \
  -s INCOMING_MODULE_JS_API='["noInitialRun","noFSInit","locateFile","preRun","instantiateWasm","quit"]' \
  -s MODULARIZE=1 \
  -s EXPORT_NAME=createModule \
  -o "$ROOT/dist/ffmpeg.js"
