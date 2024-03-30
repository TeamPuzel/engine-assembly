
window: window.o
	ld -o window window.o -L '/opt/homebrew/lib' -lc -lsdl2 -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _start -arch arm64

window.o: window.s
	as -arch arm64 -o window.o window.s
