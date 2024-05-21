#!/bin/bash

set -e

_root=$PWD
_dirname=$RULES_pkgname-$RULES_electron_ver
rm -rf $_dirname
mkdir $_dirname
_dirpath=$(realpath $_dirname)
cd $_dirname

( cd ../repos/electron && git checkout v$RULES_electron_ver )

( cd ../repos/chromium && \
  git checkout $RULES_chromium_ver && \
  cp -r --reflink=auto . $_dirpath/src )

cat > .gclient <<EOF
solutions = [
  {
    "name": "src/electron",
    "url": "file://$_root/repos/electron@v$RULES_electron_ver",
    "deps_file": "DEPS",
    "managed": False,
    "custom_deps": {
      "src": None,
    },
    "custom_vars": {},
  },
]
EOF

_oldpath=$PATH
export PATH+=":$_root/repos/depot_tools"
export DEPOT_TOOLS_UPDATE=0

gclient sync -D --nohooks --with_branch_heads --with_tags

cd src

echo "Running hooks..."
python3 build/landmines.py
python3 build/util/lastchange.py -o build/util/LASTCHANGE
python3 build/util/lastchange.py -m GPU_LISTS_VERSION \
  --revision-id-only --header gpu/config/gpu_lists_version.h
python3 build/util/lastchange.py -m SKIA_COMMIT_HASH \
  -s third_party/skia --header skia/ext/skia_commit_hash.h
python3 build/util/lastchange.py \
  -s third_party/dawn --revision gpu/webgpu/DAWN_VERSION
# python3 tools/update_pgo_profiles.py --target=linux update \
#   --gs-url-base=chromium-optimization-profiles/pgo_profiles
download_from_google_storage --no_resume --extract --no_auth \
  --bucket chromium-nodejs -s third_party/node/node_modules.tar.gz.sha1

export PATH=$_oldpath
unset DEPOT_TOOLS_UPDATE

# apply electron patches beforehand since they need git to apply
( cd .. && \
  src/electron/script/apply_all_patches.py \
    src/electron/patches/config.json )

# same as yarn install
( cd electron && yarnpkg install )

# Below are scripts taken from openSUSE to remove unused, large chunks of files.

# For every entry on this list either remove it, or add an explanation why it's needed.
echo ">>>>>> Remove bundled libs"
keeplibs=(
    base/third_party/cityhash #Derived code, not vendored dependency.
    base/third_party/cityhash_v103 #Derived code, not vendored dep
    base/third_party/dynamic_annotations #Derived code, not vendored dependency.
    base/third_party/icu #Derived code, not vendored dependency.
    base/third_party/superfasthash #Not a shared library.
    base/third_party/symbolize #Derived code, not vendored dependency.
    base/third_party/valgrind #Copy of a private header.
    base/third_party/xdg_mime #Seems not to be available as a shared library.
    base/third_party/xdg_user_dirs #Derived code, not vendored dependency.
    chrome/third_party/mozilla_security_manager #Derived code, not vendored dependency.
    courgette/third_party #Derived code, not vendored dependency.
    net/third_party/mozilla_security_manager #Derived code, not vendored dependency.
    net/third_party/nss #Derived code, not vendored dependency.
    net/third_party/quiche #Not available as a shared library yet. An old version is in Factory (google-quiche-source)
    net/third_party/uri_template #Derived code, not vendored dependency.
    third_party/abseil-cpp #Leap and fc36 too old.
    third_party/angle  # ANGLE is an integral part of chrome and is not available as a shared library.
    third_party/angle/src/third_party/ceval #not in any distro
    third_party/angle/src/third_party/volk #replacement vulkan loader. Drop it when Leap has new enough libvulkan
    third_party/blink #Integral part of chrome
    third_party/boringssl #Factory has an ancient version, but upstream seems to have gave up on making it a shared library
    third_party/boringssl/src/third_party/fiat #Not in any distro
    # We don't need it (disable-catapult.patch)
    #third_party/catapult
    #third_party/catapult/common/py_vulcanize/third_party/rcssmin
    #third_party/catapult/common/py_vulcanize/third_party/rjsmin
    #third_party/catapult/third_party/beautifulsoup4
    #third_party/catapult/third_party/html5lib-1.1
    #third_party/catapult/third_party/html5lib-python
    #third_party/catapult/third_party/polymer
    #third_party/catapult/third_party/six
    #third_party/catapult/tracing/third_party/d3
    #third_party/catapult/tracing/third_party/gl-matrix
    #third_party/catapult/tracing/third_party/jpeg-js
    #third_party/catapult/tracing/third_party/jszip
    #third_party/catapult/tracing/third_party/mannwhitneyu
    #third_party/catapult/tracing/third_party/oboe
    #third_party/catapult/tracing/third_party/pako
    third_party/ced #not in any distro
    third_party/cld_3 #not in any distro. We have cld2 but not cld3
    third_party/closure_compiler #the python scripts are not available separately
    third_party/crashpad #Integral part of chrome
    third_party/crashpad/crashpad/third_party/lss #Derived code, not vendored dependency.
    third_party/crashpad/crashpad/third_party/zlib #Derived code, not vendored dependency.
    third_party/cros_system_api #Integral part of Chrome. Needed.
    third_party/d3 #javascript
    third_party/dawn #Integral part of chrome, Needed even if you're building chrome without webgpu
    third_party/dawn/third_party/gn/webgpu-cts #Integral part of chrome, Needed even if you're building chrome without webgpu
    third_party/devtools-frontend #Javascript code, integral part of chrome
    third_party/devtools-frontend/src/front_end/third_party #various javascript code compiled into chrome, see README.md
    third_party/devtools-frontend/src/front_end/third_party/puppeteer/package/lib/esm/third_party/mitt
    third_party/devtools-frontend/src/front_end/third_party/puppeteer/package/lib/esm/third_party/rxjs
    third_party/devtools-frontend/src/test/unittests/front_end/third_party/i18n # javascript
    third_party/devtools-frontend/src/third_party/i18n #javascript
    third_party/devtools-frontend/src/third_party/typescript #Chromium added code
    third_party/distributed_point_functions #not in any distro
    third_party/dom_distiller_js #javascript
    #third_party/eigen3 #Used only by tflite which is not used in electron
    third_party/electron_node #Integral part of electron
    third_party/emoji-segmenter #not available as a shared library
    third_party/fdlibm #derived code, not vendored dep
    third_party/hunspell #heavily forked version
    third_party/iccjpeg #not in any distro
    third_party/inspector_protocol #integral part of chrome
    third_party/ipcz #not in any distro
    third_party/jstemplate #javascript
    third_party/khronos #Modified to add ANGLE definitions
    third_party/leveldatabase #use of private headers
    third_party/libaddressinput #seems not to be available as a separate library
    third_party/libaom #version in Factory is too old
    third_party/libaom/source/libaom/third_party/fastfeat
    third_party/libaom/source/libaom/third_party/SVT-AV1
    third_party/libaom/source/libaom/third_party/vector
    third_party/libaom/source/libaom/third_party/x86inc
    third_party/libavif #leap too old
    #third_party/libgav1 #Usage of private headers (ObuFrameHeader from utils/types.h) in VAAPI code only
    third_party/libphonenumber #Depends on protobuf which cannot be unbundled
    third_party/libsrtp #Needs to be built against boringssl, not openssl
    third_party/libsync #not yet in any distro
    third_party/libudev #Headers for a optional delay-loaded dependency
    third_party/liburlpattern #Derived code, not vendored dep.
    third_party/libva_protected_content #ChromeOS header not available separately. needed for build.
    third_party/libvpx #15.5/FC37 too old
    third_party/libvpx/source/libvpx/third_party/x86inc
    third_party/libwebm #Usage of private headers (mkvparser/mkvmuxer)
    third_party/libx11 #Derived code, not vendored dep
    third_party/libxcb-keysyms #Derived code, not vendored dep
    third_party/libxml/chromium #added chromium code
    third_party/libyuv #The version in Fedora is too old
    third_party/lottie #javascript
    third_party/lss #Wrapper for linux ABI
    #third_party/maldoca #integral part of chrome, but not used in electron.
    #third_party/maldoca/src/third_party
    third_party/material_color_utilities #not in any distro
    third_party/mesa_headers #ui/gl/gl_bindings.cc depends on GL_KHR_robustness not being defined.
    third_party/metrics_proto #integral part of chrome
    third_party/modp_b64 #not in Factory or Rawhide. pkgconfig(stringencoders) Mageia, AltLinux, Debian have it
    third_party/node #javascript code
    third_party/omnibox_proto #integral part of chrome
    third_party/one_euro_filter #not in any distro
    third_party/openscreen #Integral part of chrome, needed even if you're building without.
    third_party/openscreen/src/third_party/tinycbor #not in any distro
    third_party/ots #not available as a shared library. Fedora has the cli version as opentype-sanitizer
    #we don't build pdf support, removing it from tarball to save space
    #third_party/pdfium #Part of chrome, not available separately.
    #third_party/pdfium/third_party/agg23 #Heavily patched version. Fedora has it as agg
    #third_party/pdfium/third_party/base #derived code, not vendored dependency
    #third_party/pdfium/third_party/bigint #not on any distro
    #third_party/pdfium/third_party/freetype #Copy of private headers
    #third_party/pdfium/third_party/skia_shared #Skia is not available as a shared library yet.
    third_party/perfetto #Seems not to be available as a shared library, despite the presence of a `debian` directory.
    third_party/perfetto/protos/third_party/chromium #derived code, not vendored dep
    third_party/pffft #not in any distro, also heavily patched
    third_party/polymer #javascript
    third_party/private-join-and-compute #not in any distro, also heavily patched
    third_party/private_membership #derived code, not vendored dep
    third_party/protobuf #Heavily forked. Apparently was officially unbundlable back in the GYP days, and may be again in the future.
    third_party/puffin #integral part of chrome
    third_party/rnnoise #use of private headers
    third_party/shell-encryption #not available on any distro, also heavily patched
    third_party/skia #integral part of chrome
    third_party/smhasher #not in Rawhide or Factory. AltLinux has it (libsmhasher) CONSIDER UNBUNDLING if we have it
    third_party/speech-dispatcher #Headers for a delay-loaded optional dependency
    third_party/sqlite #heavily forked version
    third_party/swiftshader #not available as a shared library
    third_party/swiftshader/third_party/astc-encoder #not in rawhide or factory. Debian has it (astc-encoder)
    third_party/swiftshader/third_party/llvm-subzero #heavily forked version of libLLVM for use in subzero
    third_party/swiftshader/third_party/marl #not on any distro
    third_party/swiftshader/third_party/SPIRV-Headers #Leap too old
    third_party/swiftshader/third_party/SPIRV-Tools #Leap too old
    third_party/swiftshader/third_party/subzero #integral part of swiftshader
    #third_party/tflite #Not used by electron, but chrome needs it.
    #third_party/tflite/src/third_party/eigen3
    #third_party/tflite/src/third_party/fft2d
    third_party/vulkan-deps/spirv-headers #Leap too old
    third_party/vulkan-deps/spirv-tools #Leap too old
    third_party/vulkan-deps/vulkan-headers #Leap too old. CONSIDER UNBUNDLING when all distros have new enough vulkan sdk
    third_party/vulkan_memory_allocator #not in Factory
    third_party/webgpu-cts #Javascript code. Needed even if you're building chrome without webgpu
    third_party/webrtc #Integral part of chrome
    third_party/webrtc/common_audio/third_party/ooura #derived code, not vendored dep
    third_party/webrtc/common_audio/third_party/spl_sqrt_floor #derived code, not vendored dep
    third_party/webrtc/modules/third_party/fft #derived code, not vendored dep
    third_party/webrtc/modules/third_party/g711 #derived code, not vendored dep
    third_party/webrtc/modules/third_party/g722 #derived code, not vendored dep
    third_party/webrtc/rtc_base/third_party/base64 #derived code, not vendored dep
    third_party/webrtc/rtc_base/third_party/sigslot #derived code, not vendored dep
    third_party/webrtc_overrides #Integral part of chrome
    third_party/widevine #Integral part of chrome. Needed.
    third_party/wayland/wayland_scanner_wrapper.py #wrapper script
    third_party/wayland-protocols/gtk/gdk/wayland/protocol #Imagine downloading 100MB of gtk source just to get one file.
    third_party/wayland-protocols/mesa #egl-wayland-devel (Fedora) / libnvidia-egl-wayland1 (Tumbleweed). 15.6 has an old version that misses the file we need.
    third_party/wayland-protocols/unstable #unknown origin. not in wayland-protocol-devel or elsewhere
    third_party/wuffs #not in any distro
    third_party/x11proto #derived code, not vendored dep
    third_party/zlib/contrib/minizip #https://bugzilla.redhat.com/show_bug.cgi?id=2240599 https://github.com/zlib-ng/minizip-ng/issues/447
    third_party/zlib/google #derived code, not vendored dep
    third_party/zxcvbn-cpp #not in any distro, also heavily patched
    url/third_party/mozilla #derived code, not vendored dep
    v8/src/third_party/siphash #derived code, not vendored dep
    v8/src/third_party/utf8-decoder #derived code, not vendored dep
    v8/src/third_party/valgrind #incompatible definition of VALGRIND_DISCARD_TRANSLATIONS
    v8/third_party/inspector_protocol #integral part of chrome
    v8/third_party/v8 #derived code, not vendored dep
)
build/linux/unbundle/remove_bundled_libraries.py "${keeplibs[@]}" --do-remove
if [ $? -ne 0 ]; then
    echo "ERROR: remove_bundled_libraries.py failed"
    cleanup_and_exit 1
fi
# Now remove additional bundled/duplicate libraries in node/deps
rm -rf third_party/electron_node/deps/{googletest/{include,src},icu-small} #292MB and vendored
find third_party/electron_node/deps/brotli -type f ! -name "*.gn" -a ! -name "*.gni" -a ! -name "*.gyp" -a ! -name "*.gypi" -delete
find third_party/electron_node/deps/cares -type f ! -name "*.gn" -a ! -name "*.gni" -a ! -name "*.gyp" -a ! -name "*.gypi" -delete
find third_party/electron_node/deps/nghttp2 -type f ! -name "*.gn" -a ! -name "*.gni" -a ! -name "*.gyp" -a ! -name "*.gypi" -delete
find third_party/electron_node/deps/openssl -type f ! -name "*.gn" -a ! -name "*.gni" -a ! -name "*.gyp" -a ! -name "*.gypi" -delete
find third_party/electron_node/deps/v8 -type f ! -name "*.gn" -a ! -name "*.gni" -a ! -name "*.gyp" -a ! -name "*.gypi" -delete
find third_party/electron_node/deps/zlib -type f ! -name "*.gn" -a ! -name "*.gni" -a ! -name "*.gyp" -a ! -name "*.gypi" -delete

# Some more chonkers
rm -rf components/test/data #21MB
rm -rf docs #30MB
rm -rf media/test/data #62MB
rm -rf native_client_sdk/doc_generated #21MB
rm -rf third_party/blink/{manual,perf}_tests #70MB
rm -rf third_party/electron_node/{doc,test} #42MB
rm -rf third_party/libaom/fuzz #44MB
rm -rf third_party/perfetto/docs #11MB
rm -rf third_party/protobuf/{csharp,java,js,objectivec,php,ruby} #22MB
rm -rf third_party/skia/{bench,docs,gm,platform_tools,resources,site,test,tools} #67MB
rm -rf third_party/sqlite/fuzz #61MB
rm -rf third_party/swiftshader/tests/regres #381MB
rm -rf third_party/webrtc/data #27MB
rm -rf tools/disable_tests #6MB
rm -rf tools/perf/{page_sets,testdata} #55MB
rm -rf third_party/blink/web_tests # 1.6GB
rm -rf third_party/catapult/tracing/test_data # 200MB
rm -rf third_party/sqlite/src/test #86MB
find chrome/test/data -type f ! -name "*.gn" -a ! -name "*.gni" -delete #249MB, thanks Mageia
find third_party/hunspell_dictionaries -type f ! -name "*.gn" -a ! -name "*.gni" -delete #262MB

# see electron/.circleci/config/base.yml
rm -rf android_webview
rm -rf ios/chrome

find . -type d -name .git -print0 | xargs -0 rm -rf
# Remove generatted python bytecode
find . -type d -name __pycache__ -print0 | xargs -0 rm -rvf
find . -type f -name '*.pyc' -print -delete

echo ">>>>>> Remove non-free binaries"
find . -type f -name "*.wasm" -print -delete
find . -type f -name "*.jar" -print -delete
find . -type f -name "*.exe" -print -delete
find . -type f -name "*.node" -print -delete
find . -type f -name "*.dll" -print -delete
find . -type f -name "*.dylib" -print -delete
find . -type f -name "*.so" -print -delete
find . -type f -name "*.o" -print -delete
find . -type f -name "*.a" -print -delete

# We use sponge to avoid a race condition between find and rm
find -type f | sponge | xargs -P$(nproc) -- sh -c 'file -S "$@" | grep -v '\'' .*script'\'' | grep '\'' .*executable'\'' | tee /dev/stderr | sed '\''s/: .*//'\'' | xargs rm -fv'

# Remove empty directories
echo ">>>>>> Remove empty directories"
find . -type d -empty -print -delete
