FROM ubuntu:19.04

COPY config.patch /tmp/build/config.patch

WORKDIR /tmp/build
RUN sed -i.bak -e "s%http://archive.ubuntu.com/ubuntu/%http://ftp.jaist.ac.jp/pub/Linux/ubuntu/%g" /etc/apt/sources.list && \
    apt-get -y update && \
    apt-get -y install flex bison bc libelf-dev curl git make && \
    curl -LsO http://tukaani.org/xz/xz-5.0.3.tar.gz && \
    tar -zxvf xz-5.0.3.tar.gz && \
    cd xz-5.0.3 && \
    ./configure && \
    make  && \
    make install && \
    curl -LsO https://dl.google.com/go/go1.12.2.linux-amd64.tar.gz && \
    tar zxvf go1.12.2.linux-amd64.tar.gz && \
    export GOROOT="${PWD}/go" && \
    export PATH="${PATH}:${GOROOT}/bin" && \
    mkdir -p ${HOME}/gopath && \
    export GOPATH="${HOME}/gopath" && \
    go get github.com/kata-containers/tests && \
    cd $GOPATH/src/github.com/kata-containers/tests/.ci && \
    kernel_arch="$(./kata-arch.sh)" && \
    kernel_dir="$(./kata-arch.sh --kernel)" && \
    curl -sL https://raw.githubusercontent.com/kata-containers/packaging/master/kernel/configs/${kernel_arch}_kata_kvm_4.19.x -o .config && \
    kernel_version=$(grep "Linux/[${kernel_arch}]*" .config | cut -d' ' -f3 | tail -1) && \
    kernel_tar_file="linux-${kernel_version}.tar.xz" && \
    kernel_url="https://cdn.kernel.org/pub/linux/kernel/v$(echo $kernel_version | cut -f1 -d.).x/${kernel_tar_file}" && \
    curl -LsOk ${kernel_url} && \
    tar -Jxvf ${kernel_tar_file} && \
    patch -p1 < /tmp/build/config.patch && \
    cp .config "linux-${kernel_version}/.config" && \
    cd "linux-${kernel_version}" && \
    curl -sL https://raw.githubusercontent.com/kata-containers/packaging/master/kernel/patches/0001-NO-UPSTREAM-9P-always-use-cached-inode-to-fill-in-v9.patch | patch -p1 && \
    make ARCH=${kernel_dir} -j$(nproc) && \
    kata_kernel_dir="/usr/share/kata-containers" && \
    kata_vmlinuz="${kata_kernel_dir}/kata-vmlinuz-${kernel_version}.container" && \
    [ $kernel_arch = ppc64le ] && kernel_file="$(realpath ./vmlinux)" || kernel_file="$(realpath arch/${kernel_arch}/boot/bzImage)" && \
    mkdir -p /build && \
    echo -n ${kernel_version} > /build/kernel_version && \
    # bzImage -> vmlinuz
    cp "${kernel_file}" /build/vmlinuz-${kernel_version} && \
    # vmlinux -> vmlinux
    cp "$(realpath vmlinux)" /build/vmlinux-${kernel_version} && \
    cp modules.builtin /build/modules.builtin-${kernel_version} && \
    cp modules.builtin /build/modules.order-${kernel_version}
