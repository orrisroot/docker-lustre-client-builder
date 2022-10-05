#!/bin/bash

if [ ! -f /.dockerenv ]; then
  echo "Error: running environment is not inside a docker container"
  exit 1
fi

if [ ! -f /etc/os-release ]; then
  echo "Error: /etc/os-release file not found"
  exit 1
fi

. /etc/os-release
SYSTEM_ID="${ID}-${VERSION_ID}"

pushd $(dirname $0)
WORK_DIR="$(pwd)"
popd
LUSTRE_SOURCE="$(ls ${WORK_DIR}/lustre-*.tar.gz 2> /dev/null)"

case "${SYSTEM_ID}" in
  centos-7*)
    yum groupinstall -y "Development Tools"
    yum install -y kernel-devel kernel-abi-whitelists
    # yum install -y elfutils-libelf-devel
    yum install -y krb5-devel openssl-devel libyaml-devel libmount-devel

    KERNEL_VERSION="$(rpm -qa kernel-devel | sed -e 's+kernel-devel-++')"
    KERNEL_ARCH="$(echo ${KERNEL_VERSION} | sed -e 's+.*\.++g')"
    DEST_DIR="${WORK_DIR}/dist/${SYSTEM_ID}/${KERNEL_VERSION}"
    [ ! -d ${DEST_DIR} ] && mkdir -p ${DEST_DIR}
    cd ${DEST_DIR}

    if [ -f "${LUSTRE_SOURCE}" ]; then
      tar zxvf "${LUSTRE_SOURCE}"
      pushd $(basename "${LUSTRE_SOURCE}" .tar.gz)
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
    MOCK_CONFIG="$(echo $SYSTEM_ID | sed -e 's+7\..*$+7+g')-$KERNEL_ARCH"
    mock -r ${MOCK_CONFIG} init
    mock -r ${MOCK_CONFIG} install kernel-devel-${KERNEL_VERSION} kernel-headers-${KERNEL_VERSION} kernel-abi-whitelists
    mock -r ${MOCK_CONFIG} install flex bison krb5-devel openssl-devel libmount-devel
    mock -r ${MOCK_CONFIG} --no-clean --define "configure_args '--disable-lru-resize'" --define "kdir /usr/src/kernels/${KERNEL_VERSION}" --define "kobjdir /usr/src/kernels/${KERNEL_VERSION}" --without servers --without ldiskfs --with gss_keyring --with gss --with gss --without snmp ${SOURCE_RPM}
    cp /var/lib/mock/${MOCK_CONFIG}/result/*.rpm ${DEST_DIR}/
    cp /var/lib/mock/${MOCK_CONFIG}/result/build.log ${DEST_DIR}/
    ;;

  centos-8*|rocky-8*|almalinux-8*)
    dnf install -y dnf-plugins-core
    dnf config-manager --enable powertools
    dnf group install -y "Development Tools"
    dnf install -y kernel-devel kernel-rpm-macros kernel-abi-stablelists
    dnf install -y krb5-devel openssl-devel libyaml-devel libmount-devel

    KERNEL_VERSION="$(rpm -qa kernel-devel | sed -e 's+kernel-devel-++')"
    KERNEL_ARCH="$(echo ${KERNEL_VERSION} | sed -e 's+.*\.++g')"
    DEST_DIR="${WORK_DIR}/dist/${SYSTEM_ID}/${KERNEL_VERSION}"
    [ ! -d ${DEST_DIR} ] && mkdir -p ${DEST_DIR}
    cd ${DEST_DIR}

    if [ -f "${LUSTRE_SOURCE}" ]; then
      tar zxvf "${LUSTRE_SOURCE}"
      pushd $(basename "${LUSTRE_SOURCE}" .tar.gz)
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
    MOCK_CONFIG="$(echo $SYSTEM_ID | sed -e 's+centos+centos-stream+g' -e 's+8\..*$+8+g')-$KERNEL_ARCH"
    mock -r ${MOCK_CONFIG} init
    mock -r ${MOCK_CONFIG} install kernel-devel-${KERNEL_VERSION} kernel-headers-${KERNEL_VERSION} kernel-abi-stablelists
    mock -r ${MOCK_CONFIG} install flex bison krb5-devel openssl-devel libmount-devel
    mock -r ${MOCK_CONFIG} --no-clean --define "configure_args '--disable-lru-resize'" --define "kdir /usr/src/kernels/${KERNEL_VERSION}" --define "kobjdir /usr/src/kernels/${KERNEL_VERSION}" --without servers --without ldiskfs --with gss_keyring --with gss --with gss --without snmp ${SOURCE_RPM}
    cp /var/lib/mock/${MOCK_CONFIG}/result/*.rpm ${DEST_DIR}/
    cp /var/lib/mock/${MOCK_CONFIG}/result/build.log ${DEST_DIR}/
    ;;

  centos-9*|rocky-9*|almalinux-9*)
    # TODO: may not work now.
    dnf install -y dnf-plugins-core
    dnf config-manager --enable crb
    dnf group install -y "Development Tools"
    dnf install -y kernel-devel kernel-rpm-macros kernel-abi-stablelists
    dnf install -y which kmod
    dnf install -y krb5-devel keyutils-libs-devel openssl-devel libyaml-devel libmount-devel

    KERNEL_VERSION="$(rpm -qa kernel-devel | sed -e 's+kernel-devel-++')"
    KERNEL_ARCH="$(echo ${KERNEL_VERSION} | sed -e 's+.*\.++g')"
    DEST_DIR="${WORK_DIR}/dist/${SYSTEM_ID}/${KERNEL_VERSION}"
    [ ! -d ${DEST_DIR} ] && mkdir -p ${DEST_DIR}
    cd ${DEST_DIR}

    if [ -f "${LUSTRE_SOURCE}" ]; then
      tar zxvf "${LUSTRE_SOURCE}"
      pushd $(basename "${LUSTRE_SOURCE}" .tar.gz)
    else
      dnf install -y git
      git clone --branch b2_15 git://git.whamcloud.com/fs/lustre-release.git
      pushd lustre-release
    fi
    sh ./autogen.sh
    ./configure --disable-server --disable-lru-resize --with-linux=/usr/src/kernels/${KERNEL_VERSION}
    make srpm
    SOURCE_RPM="$(pwd)/$(ls *src.rpm)"
    popd

    dnf install -y epel-release
    dnf install -y mock
    MOCK_CONFIG="$(echo $SYSTEM_ID | sed -e 's+centos+centos-stream+g' -e 's+9\..*$+9+g')-$KERNEL_ARCH"
    mock -r ${MOCK_CONFIG} init
    mock -r ${MOCK_CONFIG} install kernel-devel-${KERNEL_VERSION} kernel-headers-${KERNEL_VERSION} kernel-abi-stablelists
    mock -r ${MOCK_CONFIG} install krb5-devel keyutils-libs-devel openssl-devel
    mock -r ${MOCK_CONFIG} --no-clean --define "configure_args '--disable-lru-resize'" --define "kdir /usr/src/kernels/${KERNEL_VERSION}" --define "kobjdir /usr/src/kernels/${KERNEL_VERSION}" --without servers --without ldiskfs --with gss_keyring --with gss --with gss --without snmp ${SOURCE_RPM}
    cp /var/lib/mock/${MOCK_CONFIG}/result/*.rpm ${DEST_DIR}/
    cp /var/lib/mock/${MOCK_CONFIG}/result/build.log ${DEST_DIR}/
    ;;

  ubuntu-18.04|ubuntu-20.04)
    export DEBIAN_FRONTEND=noninteractive
    apt update
    apt install -y linux-headers-generic
    apt install -y build-essential module-assistant debhelper dpatch quilt rsync flex bison mpi-default-dev
    apt install -y libyaml-dev libreadline-dev libselinux-dev libsnmp-dev
    apt install -y libkrb5-dev libssl-dev libgss-dev libkeyutils-dev zlib1g-dev libmount-dev

    KERNEL_VERSION="$(ls -d /usr/src/linux-headers-*-generic | sed -e 's+.*/linux-headers-++g')"
    DEST_DIR="${WORK_DIR}/dist/${SYSTEM_ID}/${KERNEL_VERSION}"
    [ ! -d ${DEST_DIR} ] && mkdir -p ${DEST_DIR}
    cd ${DEST_DIR}

    if [ -f "${LUSTRE_SOURCE}" ]; then
      tar zxvf "${LUSTRE_SOURCE}"
      pushd $(basename "${LUSTRE_SOURCE}" .tar.gz)
    else
      apt install -y git
      git clone --branch b2_12 git://git.whamcloud.com/fs/lustre-release.git
      pushd lustre-release
    fi
    sh ./autogen.sh
    ./configure --disable-server --disable-lru-resize --with-linux="/usr/src/linux-headers-${KERNEL_VERSION}/"
    make debs | tee build.log
    cp ./debs/*.deb ${DEST_DIR}/
    cp ./build.log ${DEST_DIR}/
    popd
    ;;

  *)
    echo "Error: unsupported system version found: ${SYSTEM_ID}"
    exit 1
    ;;
esac
