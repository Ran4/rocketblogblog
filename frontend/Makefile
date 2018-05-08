.PHONY: run clean

build: build/app.js
	#`make run` or open `build/index.html` to run

run: build/app.js
	open build/index.html

clean:
	rm -rf build

build/index.html:
	mkdir -p build && cp index.html build/

build/app.js: Main.elm build/index.html
	elm make --warn Main.elm --output build/app.js
