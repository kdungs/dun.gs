TARGET = _site
POSTS = $(shell ls posts/*.md)
OVERVIEW = $(shell ./overview.py)

all: structure ${TARGET}/index.html $(addprefix ${TARGET}/, $(addsuffix .html, $(basename ${POSTS})))

structure:
	mkdir -p ${TARGET}/posts
	cp -r css ${TARGET}/

${TARGET}/index.html: index.md
	pandoc -s --template "template.html" --variable overview="${OVERVIEW}" -f markdown -t html5 -o $@ $<

${TARGET}/posts/%.html: posts/%.md
	pandoc -s --template "template.html" -f markdown -t html5 -o $@ $<

clean:
	rm -rf ${TARGET}

testserver: all
	cd ${TARGET} && python3 -m http.server

deploy: clean all
	rsync -avz -e ssh ./_site/ uberspace:./html/
