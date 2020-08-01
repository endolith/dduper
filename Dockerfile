FROM debian:buster-slim AS build
MAINTAINER Lakshmipathi.G

# Install needed dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends git autoconf automake gcc \
    make pkg-config e2fslibs-dev libblkid-dev zlib1g-dev liblzo2-dev \
    python3-dev libzstd-dev python-pip python3-setuptools patch

# Clone the repo
RUN git clone https://github.com/Lakshmipathi/dduper.git && git clone https://github.com/kdave/btrfs-progs.git

# Apply csum patch
WORKDIR /btrfs-progs
RUN patch -p1 < /dduper/patch/btrfs-progs-v5.6.1/0001-Print-csum-for-a-given-file-on-stdout.patch

# Start the btrfs-progs build
RUN ./autogen.sh
RUN ./configure --disable-documentation
RUN make install DESTDIR=/btrfs-progs-build

# Install dduper
FROM debian:buster-slim
COPY --from=build /lib/x86_64-linux-gnu/liblzo2.so.2 /lib/x86_64-linux-gnu/
COPY --from=build /btrfs-progs-build /btrfs-progs
COPY --from=build /dduper /dduper

RUN cp -rv /btrfs-progs/usr/local/bin/* /usr/local/bin && cp -rv /btrfs-progs/usr/local/include/* /usr/local/include/ && cp -rv /btrfs-progs/usr/local/lib/* /usr/local/lib
RUN btrfs inspect-internal dump-csum --help
RUN apt-get update && apt-get install -y --no-install-recommends python-pip 
WORKDIR /dduper
RUN pip install -r requirements.txt && cp -v dduper /usr/sbin/
RUN apt-get remove -y python-pip 