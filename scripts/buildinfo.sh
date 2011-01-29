#!/bin/sh
PATH=$PATH:/usr/local/git/bin
REV=`git rev-parse HEAD | cut -c 1-8`
BUILD_INFO_FILE=${PROJECT_DIR}/Application/MITBuildInfo.m
echo "#import \"MITBuildInfo.h\";" > ${BUILD_INFO_FILE}
echo "" >> ${BUILD_INFO_FILE}
echo "NSString * const MITBuildNumber = @\"$REV\";" >> ${BUILD_INFO_FILE}
