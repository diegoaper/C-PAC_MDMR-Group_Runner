FROM ghcr.io/fcp-indi/c-pac/ubuntu:bionic-non-free
LABEL org.opencontainers.image.description "NOT INTENDED FOR USE OTHER THAN AS A STAGE IMAGE IN A MULTI-STAGE BUILD \
AFNI @update.afni.binaries stage"
USER root

# install AFNI
COPY dev/docker_data/required_afni_pkgs.txt /opt/required_afni_pkgs.txt
RUN if [ -f /usr/lib/x86_64-linux-gnu/mesa/libGL.so.1.2.0]; then \
        ln -svf /usr/lib/x86_64-linux-gnu/mesa/libGL.so.1.2.0 /usr/lib/x86_64-linux-gnu/libGL.so.1; \
    fi && \
    libs_path=/usr/lib/x86_64-linux-gnu && \
    if [ -f $libs_path/libgsl.so.23 ]; then \
        ln -svf $libs_path/libgsl.so.23 $libs_path/libgsl.so.19 && \
        ln -svf $libs_path/libgsl.so.23 $libs_path/libgsl.so.0; \
    elif [ -f $libs_path/libgsl.so.23.0.0 ]; then \
        ln -svf $libs_path/libgsl.so.23.0.0 $libs_path/libgsl.so.19 && \
        ln -svf $libs_path/libgsl.so.23.0.0 $libs_path/libgsl.so.0; \
    elif [ -f $libs_path/libgsl.so ]; then \
        ln -svf $libs_path/libgsl.so $libs_path/libgsl.so.0; \
    fi && \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH && \
    export LD_LIBRARY_PATH && \
    apt-get update && apt-get install -y libglw1-mesa-dev && \
    AFNI_VERSION="20.0.04" && \
    curl -LOJ https://github.com/afni/afni/archive/AFNI_${AFNI_VERSION}.tar.gz && \
    mkdir /opt/afni && \
    tar -xvf afni-AFNI_${AFNI_VERSION}.tar.gz -C /opt/afni --strip-components 1 && \
    rm -rf afni-AFNI_${AFNI_VERSION}.tar.gz && \
    cd /opt/afni/src && \
    sed '/^INSTALLDIR =/c INSTALLDIR = /opt/afni' Makefile.linux_ubuntu_16_64 > Makefile && \
    make vastness && make cleanest && \
    cd /opt/afni && \
    # filter down to required packages
    ls > full_ls && \
    sed 's/linux_openmp_64\///g' /opt/required_afni_pkgs.txt | sort > required_ls && \
    comm -2 -3 full_ls required_ls | xargs rm -rf full_ls required_ls && \
    apt-get remove -y libglw1-mesa-dev && \
    ldconfig

# set up AFNI
ENV PATH=/opt/afni:$PATH

ENTRYPOINT ["/bin/bash"]

# Link libraries for Singularity images
RUN ldconfig

RUN apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# set user
USER c-pac_user