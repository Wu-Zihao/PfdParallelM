# PfdParallelM

## Usage

**PfdParallelM** is a Mathematica package to help user to run [pfd-parallel](https://github.com/singular-gpispace/pfd-parallel) more conveniently in Mathematica interface. **pfd-parallel** is a package to simplify rational functions by partial fraction decomposition. If you do not have pfd-parallel installed on your computer, please click [here](https://github.com/singular-gpispace/pfd-parallel) to install it first.

## How to use
1. Get this package by 
```
Get["the path of the PfdParallelM package"]
```

2. Create a temporary working folder for PfdParallelM, run 
```
CreatePfdParallelMWorkingFolder[" some folder "] to \
```
The folder can be a folder that already exists.

3. 
Tell PfdParallelM where pfd-parallel is, run
```
SetPfdParallelPackagePath["somePath/pfd-parallel/"]
```

4. Run 
```
PfdParallelPrepareInput[x]
```
to begin a pfd task, where x is a list or a matrix, whose entries are fractions to be partial fraction decomposed. This function returns a string, which is a message to tell the user the 1-line command to run pfd-parallel in terminal, and a 1-line command to read the results. An example of such a message is like
```
Preparation finished. To get the result, do the following:
1. Run the following command in a terminal:
somePath/run.sh | sh
2. Wait until the above computation finished.
3. Run the following commad here (in Mathematica UI):
yourResult=PfdParallelReadOutput["some path","matrix",{47,108}];
```


