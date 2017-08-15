#!/bin/sh

#  BuildHaskell.sh
#  ShadesApp
#
#  Created by Manuel M T Chakravarty on 09.08.17.
#  Copyright © 2017 Manuel M T Chakravarty. All rights reserved.

PROJECT_PATH=${SCRIPT_INPUT_FILE_0}
PROJECT_NAME=`basename ${PROJECT_PATH}`
PROJECT_BUILD_PATH=${CONFIGURATION_TEMP_DIR}/${PROJECT_NAME}
CABAL_FILE=Shades.cabal
MAIN_MODULE=Shades
MAIN_FILE=${MAIN_MODULE}.hs
SCENE_VAR=shades

echo "PROJECT_BUILD_PATH = ${PROJECT_BUILD_PATH}"

# Copy HfM project to a build location
ditto ${PROJECT_PATH} ${PROJECT_BUILD_PATH}

# Patch the Cabal file to generate a library
sed -e "s/^Executable.*$/Library/" -e "s/main-is: ${MAIN_FILE}//" ${PROJECT_PATH}/${CABAL_FILE} \
                                                                          >${PROJECT_BUILD_PATH}/${CABAL_FILE}
echo "      ${MAIN_MODULE}"                                              >>${PROJECT_BUILD_PATH}/${CABAL_FILE}
echo "      ForeignExport"                                               >>${PROJECT_BUILD_PATH}/${CABAL_FILE}

# Add 'ForeignExport' module
echo "{-# LANGUAGE ForeignFunctionInterface #-}"                          >${PROJECT_BUILD_PATH}/ForeignExport.hs
echo "module ForeignExport where"                                        >>${PROJECT_BUILD_PATH}/ForeignExport.hs
echo "import Foreign"                                                    >>${PROJECT_BUILD_PATH}/ForeignExport.hs
echo "import Foreign.ForeignPtr.Unsafe"                                  >>${PROJECT_BUILD_PATH}/ForeignExport.hs
echo "import Graphics.SpriteKit"                                         >>${PROJECT_BUILD_PATH}/ForeignExport.hs
echo "import ${MAIN_MODULE}"                                             >>${PROJECT_BUILD_PATH}/ForeignExport.hs
echo "foreign export ccall game_scene :: IO (Ptr ())"                    >>${PROJECT_BUILD_PATH}/ForeignExport.hs
echo 'game_scene = (unsafeForeignPtrToPtr . castForeignPtr) <$> sceneToForeignPtr '"${SCENE_VAR}"\
                                                                         >>${PROJECT_BUILD_PATH}/ForeignExport.hs

# Build
(cd ${PROJECT_BUILD_PATH}; cabal configure --disable-library-profiling)
(cd ${PROJECT_BUILD_PATH}; cabal build)

# Make sure the libary gets picked up by the linker
OBJECTS_NORMAL=${OBJECT_FILE_DIR_normal}/${NATIVE_ARCH_ACTUAL}
ln -shf `ls "${PROJECT_BUILD_PATH}/dist/build/${LIBPATH}"/libHSShades-*.dylib` "${OBJECTS_NORMAL}"
echo `ls "${OBJECTS_NORMAL}"/libHSShades-*.dylib` >>"${OBJECTS_NORMAL}/${PROJECT}.LinkFileList"

# And also link against the (threaded) RTS
RTS_DIR=`ghc-pkg describe rts | grep library-dirs | cut -d ' ' -f 2`
RTS_DYLIB=`ls "${RTS_DIR}"/libHSrts_thr-ghc*.dylib`
echo ${RTS_DYLIB} >>"${OBJECTS_NORMAL}/${PROJECT}.LinkFileList"
