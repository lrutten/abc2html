all: build

build:
	shards build

run:
	bin/abc2html

install:
	cp -v bin/abc2html ~/bin

clean:
	rm -Rvf bin

