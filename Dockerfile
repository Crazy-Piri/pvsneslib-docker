# To create the image:
#   $ docker build -t amiga -f amiga.Dockerfile .
# To run the container:
#   $ docker run -v ${PWD}:/src/ -it amiga

# i386 because if we use 64bit gcc some tools segault.
# trusty because some tools don't compile with latest gcc.
# didnt had time to debug so I just choose the oldest supported ubuntu that worked :)
FROM i386/ubuntu:trusty

RUN apt-get update && apt-get install make python linux-libc-dev binutils gcc g++ git wget cmake -y 

RUN git clone https://github.com/vhelin/wla-dx /wla-dx\
	&& cd /wla-dx/\
	&& mkdir build && cd build\
	&& cmake ..\
	&& cmake --build . --config Release\
	&& cmake -P cmake_install.cmake

RUN git clone https://github.com/boldowa/snesbrr /snesbrr

RUN git clone https://github.com/alekmaul/pvsneslib /c/snesdev\
	&& cd /c/snesdev\
	&& cp /c/snesdev/devkitsnes/snes_rules /c/snesdev/devkitsnes/snes_rules.orig\
	&& sed 's:\\\\:/:g' /c/snesdev/devkitsnes/snes_rules.orig >/c/snesdev/devkitsnes/snes_rules\
	&& cd /c/snesdev/compiler/tcc-65816\
	&& rm -rf 816-tcc.exe\
	&& make 816-tcc.exe\
	&& cp 816-tcc.exe /c/snesdev/devkitsnes/bin/816-tcc

# /c/snesdev/devkitsnes/bin/816-opt.py is expecting python to be in /c/Python27/python
RUN mkdir -p /c/Python27/ && ln -sf /usr/bin/python /c/Python27/python

# smconv is expecting g++ in /e/MinGW32/bin/g++
RUN mkdir -p /e/MinGW32/bin/ && ln -sf /usr/bin/g++ /e/MinGW32/bin/g++

RUN cd /c/snesdev/tools/constify \
	&& cp Makefile Makefile.orig\
	&& sed 's:-lregex::g' Makefile.orig >Makefile\
	&& make all \
	&& cp constify.exe /bin/constify

WORKDIR /c/snesdev/tools/snestools
RUN make all
RUN cp snestools.exe /c/snesdev/devkitsnes/tools/snestools

WORKDIR /c/snesdev/tools/gfx2snes
RUN make all
RUN cp gfx2snes.exe /c/snesdev/devkitsnes/tools/gfx2snes

WORKDIR /c/snesdev/tools/bin2txt
RUN make all
RUN cp bin2txt.exe /c/snesdev/devkitsnes/tools/bin2txt

WORKDIR /c/snesdev/tools/smconv
RUN make all
RUN cp smconv.exe /c/snesdev/devkitsnes/tools/smconv

WORKDIR /snesbrr/src
RUN make all
RUN cp snesbrr /c/snesdev/devkitsnes/tools/snesbrr

RUN chmod 777 /c/snesdev/devkitsnes/bin/*

ENV PATH="/c/snesdev/devkitsnes/bin:${PATH}"

ENV PVSNESLIB_HOME="/c/snesdev/"

WORKDIR /src
