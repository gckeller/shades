#!/bin/sh

#  CopyHaskellDylibs.sh
#  ShadesApp
#
#  Created by Manuel M T Chakravarty on 13.08.17.
#  Copyright © 2017 Manuel M T Chakravarty. All rights reserved.

APP_BUNDLE_FRAMEWORKS="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

# Locate the dylib containing our Haskell code into the app bundle
MAIN_HASKELL_DYLIB_PATH=`ls "${APP_BUNDLE_FRAMEWORKS}"/libHSShades-*.dylib`
MAIN_HASKELL_DYLIB=`basename "${MAIN_HASKELL_DYLIB_PATH}"`

# Remove all unnecessary RPATHs (they can be trouble with sandboxing)
RPATHS_TO_REMOVE=`otool -l "${APP_BUNDLE_FRAMEWORKS}/${MAIN_HASKELL_DYLIB}" | grep -e 'path.*/usr/lib/ghc' | cut -d ' ' -f11`
for RPATH in ${RPATHS_TO_REMOVE}; do
  install_name_tool -delete_rpath "${RPATH}" "${APP_BUNDLE_FRAMEWORKS}/${MAIN_HASKELL_DYLIB}"
done

copyDependencies() {
  local libname="$1"
  local deps=`otool -l "${APP_BUNDLE_FRAMEWORKS}/${libname}" | grep -e 'name @rpath/' | cut -d ' ' -f11`

  echo "Processing dependencies of $1..."
  for dep in $deps; do
    local name=`basename ${dep}`

    # If we haven't copied this library yet, copy it and then copy its dependencies
    if [ ! -f "${APP_BUNDLE_FRAMEWORKS}/${name}" ]; then
      local pkg=`echo $name | sed -e 's/libHS//' -e 's/-ghc.*dylib//'`
      local libdir=`ghc-pkg describe $pkg | grep dynamic-library-dirs | cut -d ' ' -f 2`
      if [ $? != 0 ]; then exit 1; fi
      ditto "${libdir}/${name}" "${APP_BUNDLE_FRAMEWORKS}"
      copyDependencies ${name}
    fi
  done
}

copyDependencies ${MAIN_HASKELL_DYLIB}

# Include the (threaded) RTS
RTS_DIR=`ghc-pkg describe rts | grep library-dirs | cut -d ' ' -f 2`
RTS_DYLIB=`ls "${RTS_DIR}"/libHSrts_thr-ghc*.dylib`
ditto ${RTS_DYLIB} "${APP_BUNDLE_FRAMEWORKS}"
ditto "${RTS_DIR}/libffi.dylib" "${APP_BUNDLE_FRAMEWORKS}"
