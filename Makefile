.PHONY: clean compile

clean:
	rm ./*.js
	rm lib/*.js

compile:
	coffee -c ./
