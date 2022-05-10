#!/bin/bash

usage () {
  echo "Usage: $(basename $1) TYPE"
  echo "options:"
  echo "  - TYPE: centos-7 almalinux-8 rocky-8 centos-stream-8 ubuntu-18.04 ubuntu-20.04"
}
if [ $# -ne 1 ]; then
  usage $0
  exit 1
fi

case $1 in
  centos-7)
    docker run --cap-add SYS_ADMIN -it --rm --name c7 -v $(pwd)/work:/work docker.io/library/centos:7 /bin/bash /work/build.sh
    ;;
  alma*-8)
    docker run --cap-add SYS_ADMIN -it --rm --name a8 -v $(pwd)/work:/work docker.io/library/almalinux:8 /bin/bash /work/build.sh
    ;;
  rocky*-8)
    docker run --cap-add SYS_ADMIN -it --rm --name r8 -v $(pwd)/work:/work docker.io/library/rockylinux:8 /bin/bash /work/build.sh
    ;;
  centos-stream-8)
    docker run --cap-add SYS_ADMIN -it --rm --name cs8 -v $(pwd)/work:/work quay.io/centos/centos:stream8 /bin/bash /work/build.sh
    ;;
  ubuntu-18.04)
    docker run --cap-add SYS_ADMIN -it --rm --name u1804 -v $(pwd)/work:/work docker.io/library/ubuntu:18.04 /bin/bash /work/build.sh
    ;;
  ubuntu-20.04)
    docker run --cap-add SYS_ADMIN -it --rm --name u2004 -v $(pwd)/work:/work docker.io/library/ubuntu:20.04 /bin/bash /work/build.sh
    ;;
  *)
    echo "Error: unknown type: $1"
    ;;
esac
