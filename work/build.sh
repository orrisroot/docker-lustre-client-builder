#!/bin/bash

if [ ! -f /.dockerenv ]; then
  echo "Error: running environment is not inside a docker container"
  exit 1
fi

if [ ! -f /etc/system-release-cpe ]; then
  echo "Error: /etc/system-release-cpe file not found"
  exit 1
fi

in_array() {
  for item in "${@:2}"; do [[ "$item" == "$1" ]] && return 0; done
  return 1
}

SYSTEM_CPE=$(cat /etc/system-release-cpe)
# cpe:/o:centos:centos:7
# cpe:/o:centos:centos:8
# cpe:/o:rocky:rocky:8:GA
# cpe:/o:rocky:rocky:8.5:GA
# cpe:/o:almalinux:almalinux:8::baseos
# cpe:/o:fedoraproject:fedora:35

SYSTEM_PRODUCT=$(echo $SYSTEM_CPE | awk -F : '{ print $4 }')
SYSTEM_VERSION=$(echo $SYSTEM_CPE | awk -F : '{ print $5 }')

SUPPORTED_SYSTEM_PRODUCTS=(centos rocky almalinux)
in_array ${SYSTEM_PRODUCT} ${SUPPORTED_SYSTEM_PRODUCTS[@]}
if [ $? -ne 0 ]; then
  echo "Error: unsupported system product found: ${SYSTEM_PRODUCT}"
  exit 1
fi

pushd $(dirname $0)
WORK_DIR="$(pwd)"
popd
LUSTRE_SOURCE="$(ls ${WORK_DIR}/*.tgz 2> /dev/null)"

case "${SYSTEM_VERSION}" in
  8*)
    dnf install -y dnf-plugins-core
    dnf config-manager --enable powertools
    dnf install -y kernel-devel kernel-headers
    dnf install -y rpm-build libtool make elfutils-libelf-devel
    # dnf install -y which kernel-rpm-macros kernel-abi-stablelists kmod
    dnf install -y krb5-devel openssl-devel libyaml-devel

    KERNEL_VERSION=$(rpm -qa kernel-devel | sed -e 's+kernel-devel-++')
    DEST_DIR="${WORK_DIR}/dist/${SYSTEM_PRODUCT}-${SYSTEM_VERSION}/${KERNEL_VERSION}"
    [ ! -d ${DEST_DIR} ] && mkdir -p ${DEST_DIR}
    cd ${DEST_DIR}

    if [ -f "${LUSTRE_SOURCE}" ]; then
      tar zxvf "${LUSTRE_SOURCE}"
      pushd $(basename "${LUSTRE_SOURCE}" .tgz)
    else
      dnf install -y git
      git clone --branch b2_12 git://git.whamcloud.com/fs/lustre-release.git
      pushd lustre-release
    fi
    sh ./autogen.sh
    ./configure --disable-server --disable-lru-resize --with-linux=/usr/src/kernels/${KERNEL_VERSION}
    make srpm
    SOURCE_RPM="$(pwd)/$(ls *src.rpm)"
    popd

    dnf install -y epel-release
    dnf install -y mock
    if [ "${SYSTEM_PRODUCT}" = "centos" ]; then 
      MOCK_CONFIG=centos-stream-8-x86_64
    else
      MOCK_CONFIG=${SYSTEM_PRODUCT}-8-x86_64
    fi
    mock -r ${MOCK_CONFIG} init
    mock -r ${MOCK_CONFIG} install kernel-devel-${KERNEL_VERSION} kernel-headers-${KERNEL_VERSION} kernel-abi-stablelists
    mock -r ${MOCK_CONFIG} install krb5-devel openssl-devel
    mock -r ${MOCK_CONFIG} --no-clean --define "configure_args '--disable-lru-resize'" --define "kdir /usr/src/kernels/${KERNEL_VERSION}" --define "kobjdir /usr/src/kernels/${KERNEL_VERSION}" --without servers --without ldiskfs --with gss_keyring --with gss --with gss --without snmp ${SOURCE_RPM}
    cp /var/lib/mock/${MOCK_CONFIG}/result/*.rpm ${DEST_DIR}/
    cp /var/lib/mock/${MOCK_CONFIG}/result/build.log ${DEST_DIR}/
    ;;

  7*)
    yum install -y kernel-devel kernel-headers
    yum install -y rpm-build libtool make elfutils-libelf-devel
    yum install -y krb5-devel openssl-devel libyaml-devel

    KERNEL_VERSION=$(rpm -qa kernel-devel | sed -e 's+kernel-devel-++')
    DEST_DIR="${WORK_DIR}/dist/${SYSTEM_PRODUCT}-${SYSTEM_VERSION}/${KERNEL_VERSION}"
    [ ! -d ${DEST_DIR} ] && mkdir -p ${DEST_DIR}
    cd ${DEST_DIR}

    if [ -f "${LUSTRE_SOURCE}" ]; then
      tar zxvf "${LUSTRE_SOURCE}"
      pushd $(basename "${LUSTRE_SOURCE}" .tgz)
    else
      yum install -y git
      git clone --branch b2_12 git://git.whamcloud.com/fs/lustre-release.git
      pushd lustre-release
    fi
    sh ./autogen.sh
    ./configure --disable-server --disable-lru-resize --with-linux=/usr/src/kernels/${KERNEL_VERSION}
    make srpm
    SOURCE_RPM="$(pwd)/$(ls *src.rpm)"
    popd

    yum install -y epel-release
    yum install -y mock
    MOCK_CONFIG=${SYSTEM_PRODUCT}-7-x86_64
    mock -r ${MOCK_CONFIG} init
    mock -r ${MOCK_CONFIG} install kernel-devel-${KERNEL_VERSION} kernel-headers-${KERNEL_VERSION} kernel-abi-whitelists
    mock -r ${MOCK_CONFIG} install krb5-devel openssl-devel
    mock -r ${MOCK_CONFIG} --no-clean --define "configure_args '--disable-lru-resize'" --define "kdir /usr/src/kernels/${KERNEL_VERSION}" --define "kobjdir /usr/src/kernels/${KERNEL_VERSION}" --without servers --without ldiskfs --with gss_keyring --with gss --with gss --without snmp ${SOURCE_RPM}
    cp /var/lib/mock/${MOCK_CONFIG}/result/*.rpm ${DEST_DIR}/
    cp /var/lib/mock/${MOCK_CONFIG}/result/build.log ${DEST_DIR}/
    ;;

  *)
    echo "Error: unsupported system version found: ${SYSTEM_VERSION}"
    exit 1
    ;;
esac
