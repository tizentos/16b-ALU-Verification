all:
	vsim -c -do run.do
	vcover report -details report.ucdb -output comparator.txt
gui:
	vsim -do run.do

clean:
	rm -rf work/
	rm -f transcript
