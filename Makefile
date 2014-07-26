.PHONY: clean compile tryit cleantmp

clean:
	rm ./*.js
	rm lib/*.js

cleantmp:
	rm tmp/dest/*.js

compile:
	coffee -c ./

tryit: cleantmp
	coffee asyncProc.coffee

