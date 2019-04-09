FROM ubuntu:19.04

RUN sed -i.bak -e "s%http://archive.ubuntu.com/ubuntu/%http://ftp.jaist.ac.jp/pub/Linux/ubuntu/%g" /etc/apt/sources.list && \
    apt-get -y update && \
    apt-get -y install flex bison bc libelf-dev curl git make && \
    curl -LsO http://tukaani.org/xz/xz-5.0.3.tar.gz && \
    tar -zxvf xz-5.0.3.tar.gz && \
    cd xz-5.0.3 && \
    ./configure && \
    make  && \
    make install

RUN curl -LsO https://dl.google.com/go/go1.12.2.linux-amd64.tar.gz && \
    tar zxvf go1.12.2.linux-amd64.tar.gz && \
    export GOROOT="${PWD}/go" && \
    export PATH="${PATH}:${GOROOT}/bin" && \
    mkdir -p ${HOME}/gopath && \
    export GOPATH="${HOME}/gopath" && \
    go get github.com/kata-containers/tests && \
    cd $GOPATH/src/github.com/kata-containers/tests/.ci && \
    kernel_arch="$(./kata-arch.sh)" && \
    kernel_dir="$(./kata-arch.sh --kernel)" && \
    tmpdir="$(mktemp -d)" && \
    cd "$tmpdir" && \
    curl -sL https://raw.githubusercontent.com/kata-containers/packaging/master/kernel/configs/${kernel_arch}_kata_kvm_4.19.x -o .config && \
    kernel_version=$(grep "Linux/[${kernel_arch}]*" .config | cut -d' ' -f3 | tail -1) && \
    kernel_tar_file="linux-${kernel_version}.tar.xz" && \
    kernel_url="https://cdn.kernel.org/pub/linux/kernel/v$(echo $kernel_version | cut -f1 -d.).x/${kernel_tar_file}" && \
    curl -LsOk ${kernel_url} && \
    tar -Jxvf ${kernel_tar_file}

