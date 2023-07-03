(* ::Package:: *)

PfdParallelM`packagePath=DirectoryName[$InputFileName]
PfdParallelM`workingPath=$Failed
PfdParallelM`Initialized=False


Print["Package PfdParallelM loaded."]
Print["To show the readme text, run PfdParallelMHelp[]"]


PfdParallelMHelp[]:=Module[{userGuide},
	userGuide=Get[PfdParallelM`packagePath<>"/README.md"];
	Print[userGuide]
]





(* ::Subsubsection:: *)
(*set up folders*)


Options[CreatePfdParallelMWorkingFolder]={OverWrite->False};
CreatePfdParallelMWorkingFolder[path_,OptionsPattern[]]:=Module[{},
	If[FileExistsQ[path],
		If[DirectoryQ[path],
			If[OptionValue[OverWrite],
				Run["rm -rf "<>path];
				Print[path<>" has been overwritten."]
				,
				Print["Folder "<>path<>" already exists. Their might be some existing data there."];
			]
			,
			Print[path<>" is an existing file! Failed."];
			Return[$Failed]
		]
	];
	Run["mkdir "<>path];
	Run["cp -f "<>PfdParallelM`packagePath<>"*.* "<>path];
	Run["rm -f "<>path<>"PfdParallelM.wl"];
	PfdParallelM`workingPath=path;
	Print["The working path of PfdParallelM has been set to "<>path];
	Return[path]
]
LackedPfdParallelMFiles[prePath_]:=Module[{separator,path,result,neededFiles,existingFiles,packagePath},
	separator=StringSplit[FileNameJoin[{"a","b"}],""][[2]];
	path=prePath;
	packagePath=PfdParallelM`packagePath;
	If[StringSplit[path,""][[-1]]===separator,path=StringRiffle[StringSplit[path,""][[1;;-2]],""]];
	If[StringSplit[packagePath,""][[-1]]===separator,packagePath=StringRiffle[StringSplit[packagePath,""][[1;;-2]],""]];
	neededFiles=DeleteCases[FileNameSplit[#][[-1]]&/@FileNames[All,packagePath],"PfdParallelM.wl"];
	existingFiles=FileNameSplit[#][[-1]]&/@FileNames[All,path];
	result=Complement[neededFiles,existingFiles];
	Return[result]
]
ChangePfdParallelMWorkingFolder[path_]:=Module[{lackedFiles},
	If[FileExistsQ[path],
		If[DirectoryQ[path],
			lackedFiles=LackedPfdParallelMFiles[path];
			If[lackedFiles==={},
				PfdParallelM`workingPath=path;
				Print["The working path of PfdParallelM has been set to "<>path];
				(*Print["Please make sure this folder is an PfdParallelM working folder and the dependent files are complete!"]*)
				,
				Print["Lacking following files at "<>path<>"\n",lackedFiles];
				Return[$Failed]
			]
			,
			Print[path<>" is an existing file! Failed."];
			Return[$Failed]
		]
		,
		Print[path<>" dose not exist!"];
		Return[$Failed]
	];
]


AutoCreatePfdParallelMSubFolder[]:=Module[{i,path,subFolder},
	If[PfdParallelM`workingPath===$Failed,
		Print["No working folder specified! Run CreatePfdParallelMWorkingFolder first!"];
		Return[$Failed]
		,
		path=PfdParallelM`workingPath
	];
	For[i=1,True,i++,
		subFolder=path<>"mission_"<>ToString[i]<>"/";
		If[!FileExistsQ[subFolder],
			Run["mkdir "<>subFolder];
			Break[];
		]
	];
	Return[subFolder]
]


(* ::Subsubsection:: *)
(*trashes cleaning*)


DeletePfdParallelMTempFiles[]:=Module[{i,path,subFolders,subFolder},
	If[ParallelComply`workingPath===$Failed,
		Print["No working folder specified! Run CreateParallelComplyWorkingFolder first!"];
		Return[$Failed]
		,
		path=ParallelComply`workingPath
	];
	subFolders=FileNames[All,path];
	For[i=1,i<=Length[subFolders],i++,
		subFolder=subFolders[[i]];
		If[!DirectoryQ[subFolder],Continue[];];
		Run["rm -rf "<>subFolder]
	];
	Print["ParallelComply buffer cleared in "<>path];
	Return[path]
]


KillAllPfdParallelProcesses[OptionsPattern[]]:=Module[{},
Run["ps -ef | grep pfd-parallel | grep -v grep | awk '{print \"kill -9 \"$2}' | sh"]
]


(* ::Subsubsection:: *)
(*listnumden converter*)


ListNumdenConvert[input_]:=Module[{termList,listNumDen},
	If[Head[input]===Plus,
		termList=List@@input
	,
		termList={input}
	];
	listNumDen={Numerator[#],Denominator[#]}&/@termList;
	StringReplace[ToString[InputForm[listNumDen]],{"{"->"list(","}"->")"}]

]


ReadConvertAndSave[inputFile_,outputFolder_]:=Module[{input,result,outputFileName},
	input=Get[inputFile];
	result=ListNumdenConvert[input];
	outputFileName=outputFolder<>"/listnumden_"<>FileNameSplit[inputFile][[-1]];
	If[!DirectoryQ[#],Run["mkdir -p "<>#]]&[outputFolder];
	Export[outputFileName,result];
	(*If[False,
		Run["echo "<>outputFileName]
	,
		Print[outputFileName]
	]*)
]





ParallelConvertAndSave[inputFolder_,outputFolder_]:=Module[{files},
	files=FileNames[All,inputFolder];
	LaunchKernels[];
	ParallelTable[ReadConvertAndSave[files[[i]],outputFolder],{i,Length[files]}];
	CloseKernels[];
]


(* ::Subsubsection:: *)
(*initialization*)


SetPfdParallelPackagePath[prepath_]:=Module[{path},
	path=prepath;
	If[!FileExistsQ[path<>"/spack/share/spack/setup-env.sh"],
		Print["Path "<>path<>" is not a pfd-parallel package path or it is not a complete pfd-parallel package path."];
		Return[$Failed]
	];
	PfdParallelM`PfdParallelPath=path
]
(*SetPfdParallelListnumdenConverterPath[prepath_]:=Module[{path},
	path=prepath;
	If[!FileExistsQ[path<>"/pfd-parallel-listnumden-converter.wl"],
		Print["Package pfd-parallel-listnumden-converter.wl not found in "<>path<>""];
		Return[$Failed]
	];
	PfdParallelM`PfdParallelListnumdenConverterPath=path
]*)


ScriptRun="cd PFDPARALLELPATH
export software_ROOT=`pwd`
. $software_ROOT/spack/share/spack/setup-env.sh
spack load pfd-parallel
cd PFDPARALLELMWORKINGPATH
hostname > ./nodefile
hostname > ./loghostfile
hostname > ./hostfile
$PFD_INSTALL_DIR/libexec/bundle/gpispace/bin/gspc-monitor --port 9876 &
SINGULARPATH=\"$PFD_INSTALL_DIR/LIB\"  $SINGULAR_INSTALL_DIR/bin/Singular SINGULARSCRIPT &
wait
"
ScriptSingular="LIB \"pfd_gspc.lib\";
configToken gspcconfig = configure_gspc();
gspcconfig.options.tempdir = \"tempdir\";
gspcconfig.options.nodefile = \"hostfile\";
gspcconfig.options.procspernode = 12;
gspcconfig.options.loghostfile = \"loghostfile\";
gspcconfig.options.logport = 9876;
configToken pfdconfig = configure_pfd();
pfdconfig.options.inputdir = \"listnumden_inputs\";
pfdconfig.options.filename = \"listnumden_input\";
pfdconfig.options.suffix = \"txt\";
pfdconfig.options.parallelism = \"PARALLELISM\";
pfdconfig.options.algorithm = \"ALGORITHM\";
pfdconfig.options.outputformat = \"OUTPUTFORMAT\";
pfdconfig.options.outputdir = \"outputs\";
ring r=0,VARS,rp;
list listofentries = LISTOFENTIRES;
parallel_pfd( listofentries, gspcconfig, pfdconfig);"





(*PfdParallelMInitialization[]:=Module[{converterCodes},
	converterCodes=PfdParallelM`PfdParallelListnumdenConverterPath<>"/pfd-parallel-listnumden-converter.wl";
	If[Get[converterCodes]===$Failed,
		Print["Cannot get "<>converterCodes];
		Return[$Failed]
	];
	PfdParallelM`Initialized=True
]*)





Options[PfdParallelPrepareInput]={
Parallelism->"waitAll",
Algorithm->"Leinartas",
OutputFormat->"cleartext"
(*,
DeleteTempFiles\[Rule]False*)

}
PfdParallelPrepareInput[input_,OptionsPattern[]]:=Module[
{dimensions,mode,timer=AbsoluteTime[],workingFolder,i,j,localScriptRun,localScriptSingular,tempHead\:ff0cresult,entriesString,reportString},
	Print["Checking inputs..."];
	If[Head[input]=!=List,Print["PfdParallelM`PfdParallel: Unknown data structure, it should be a list or a matrix."];Return[$Failed]];
	dimensions=Dimensions[input];
	If[Length[dimensions]===1,
		If[MemberQ[Head/@input,List],Print["PfdParallelM`PfdParallel: Wrong data structure, possible non-regular matrix."];Return[$Failed]];
		mode="list"
	,
		If[Length[dimensions]===2,
			If[MemberQ[Head/@Flatten[input,1],List],Print["PfdParallelM`PfdParallel: Wrong data structure, list depth longer than matrix."];Return[$Failed]]
			mode="matrix"
		,
			Print["PfdParallelM`PfdParallel: Wrong data structure, not a list nor a matrix."];
			Return[$Failed]
		]
	];
	Print["mode=",mode];
	Print["\tDone. Time used: ",Round[AbsoluteTime[]-timer]," s."];
	timer=AbsoluteTime[];
	Print["Exporting input files..."];
	workingFolder=AutoCreatePfdParallelMSubFolder[];
	Run["mkdir -p "<>workingFolder<>"/inputs/"];
	Switch[mode,
	"list",
		For[i=1,i<=dimensions[[1]],i++,
			Export[workingFolder<>"/inputs/input_1_"<>ToString[i]<>".txt",input[[i]]//InputForm//ToString]
		],
	"matrix",
		For[i=1,i<=dimensions[[1]],i++,For[j=1,j<=dimensions[[2]],j++,
			Export[workingFolder<>"/inputs/input_"<>ToString[i]<>"_"<>ToString[j]<>".txt",input[[i,j]]//InputForm//ToString]
		]],
	_,
		Print["Unkown mode."];
		Return[$Failed]
	];
	Print["\tDone. Time used: ",Round[AbsoluteTime[]-timer]," s."];
	timer=AbsoluteTime[];
	Print["Converting input files into listnumden form..."];
	ParallelConvertAndSave[workingFolder<>"/inputs/",workingFolder<>"/listnumden_inputs/"];
	Print["\tDone. Time used: ",Round[AbsoluteTime[]-timer]," s."];
	timer=AbsoluteTime[];
	Print["Creating running scripts"];
	localScriptRun=StringReplace[ScriptRun,{
		"PFDPARALLELPATH"->PfdParallelM`PfdParallelPath,
		"SINGULARSCRIPT"->workingFolder<>"/pfdparallel.sing",
		"PFDPARALLELMWORKINGPATH"->workingFolder
	}];
	Switch[mode,
	"list",
		entriesString=StringReplace[ToString[InputForm[
			Flatten[Table[tempHead[1,i],{i,dimensions[[1]]}]]/.tempHead->List
		]],{"{"->"list(","}"->")"}],
	"matrix",
		entriesString=StringReplace[ToString[InputForm[
			Flatten[Table[tempHead[i,j],{i,dimensions[[1]]},{j,dimensions[[2]]}]]/.tempHead->List
		]],{"{"->"list(","}"->")"}],
	_,
		Print["Unkown mode."];
		Return[$Failed]
	];
	localScriptSingular=StringReplace[ScriptSingular,{
		"PARALLELISM"->OptionValue[Parallelism],
		"ALGORITHM"->OptionValue[Algorithm],
		"OUTPUTFORMAT"->OptionValue[OutputFormat],
		"VARS"->StringReplace[ToString[InputForm[Variables[input]]],{"{"->"(","}"->")"}],
		"LISTOFENTIRES"->entriesString
	}];
	Export[workingFolder<>"/run.sh",localScriptRun,"Text"];
	Export[workingFolder<>"/pfdparallel.sing",localScriptSingular,"Text"];
	Print["\tDone. Time used: ",Round[AbsoluteTime[]-timer]," s."];
	timer=AbsoluteTime[];
	Print["Running pfd-parallel... If there is a monitor, please close it after finished."];
	Run["mkdir -p "<>workingFolder<>"/tempdir/"];
	Run["mkdir -p "<>workingFolder<>"/outputs/"];
	Run["chmod +x "<>workingFolder<>"/run.sh"];
	Print["\tDone. Time used: ",Round[AbsoluteTime[]-timer]," s."];
	Print["--------------------------------------"];
	reportString="Preparation finished. To get the result, do the following:
1. Run the following command in a terminal:\n"<>
workingFolder<>"/run.sh\n"<>
"2. Wait until the above computation finished. Then, click \"x\" to close the monitor.
3. Run the following commad here (in the Mathematica UI):\n"<>
"yourResultName=PfdParallelReadOutput[\""<>workingFolder<>"\",\""<>mode<>"\","<>ToString[InputForm[dimensions]]<>"];";
reportString
]
PfdParallelReadOutput[workingFolder_,mode_,dimensions_]:=Module[{timer,result,i,j},
	timer=AbsoluteTime[];
	Print["Reading outputs in "<>workingFolder<>"..."];
	Switch[mode,
	"list",
		result=Table[0,dimensions[[1]]];
		For[i=1,i<=dimensions[[1]],i++,
			result[[i]]=Get[workingFolder<>"/outputs/result_listnumden_input_1_"<>ToString[i]<>".txt"]
		],
	"matrix",
		For[i=1,i<=dimensions[[1]],i++,For[j=1,j<=dimensions[[2]],j++,
			result=Table[0,dimensions[[1]],dimensions[[2]]];
			result[[i,j]]=Get[workingFolder<>"/outputs/result_listnumden_input_"<>ToString[i]<>"_"<>ToString[j]<>".txt"]
		]],
	_,
		Print["Unkown mode."];
		Return[$Failed]
	];
	Print["\tDone. Time used: ",Round[AbsoluteTime[]-timer]," s."];
	result
	
]
