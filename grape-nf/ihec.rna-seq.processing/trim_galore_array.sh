#$ -cwd
#$ -S /bin/bash
#$ -V
#$ -j y
#$ -l mem_free=5G
#$ -l h_vmem=5G

name="trim_galore_array.sh"
#trim_galore binary, tested with v4.2
trim_galore="trim_galore"
#make sure cutadapt is present in PATH and necessary packages in PYTHONPATH
export PATH=$PATH
export PYTHONPATH=$PYTHONPATH

#set TMPDIR if necessary

clip5=0

printHelp(){
 echo -e ""
 echo -e "OBS! Must be submitted as an array-job with Grid Engine (SGE_TASK_ID dependent):"
 echo -e " qsub -t 1-\`find <INPUTDIR> -name \"*_R1_*q.gz\" |wc -l\` -o log.txt $name -i <INPUTDIR> <OUTPUTDIR>"
 echo -e ""
 echo -e "Usage: $name <options>"
 echo -e ""
 echo -e " Mandatory:"
 echo -e "  -i INPUTDIR"
 echo -e "  -o OUTPUTDIR"
 echo -e ""
 echo -e " Optional:"
 echo -e "  -a STR\talternative adapter"
 echo -e "  -b STR\talternative adapter for read 2"
 echo -e "  -e STR\textraoptions passed on to trim_galore"
 echo -e "  -c INT\tclip 5' end of read n bp"
#TODO: implement workaround for command line submission:
# echo -e "  -j jobID\tIf not submitted as an array job, this must be set to mimick this"
}

printf "%s\n" "$@"

while getopts ":i:o:e:a:b:c:h" opt
do
# echo $opt
# echo $OPTARG
 case "$opt" in
  h) printHelp; exit 0 ;;
  i) inputRoot="${OPTARG%/}" ;;
  o) outputRoot="${OPTARG%/}" ;;
  e) extraOptions="$OPTARG" ;;
  a) trim_galore="${trim_galore} -a ${OPTARG}" ;;
  b) adapter2=${OPTARG} ;;
  c) clip5="$OPTARG" ;;
  *) printHelp; exit 1 ;;
 esac
done

if [[ -z "$inputRoot" ]] || [[ -z "$outputRoot" ]]
then
 echo -e ""
 echo -e "ERROR ($name): All mandatory options must be set"
 printHelp
 exit 1
fi


ls -lh $inputRoot

#submit with a command similar to this:

# qsub -t 1-`find $inputRoot -name "*_R1_*q.gz" |wc -l` -o log.txt trim_galore_array.sh $inputRoot $outputRoot

#tries to trim all files following the scheme: "*_R1_*q.gz". Applies paired end trimming if it is possible to substitute _R1_ with _R2_ and that file exists.

#get the file to work on, omitting the given prefix
pushd $inputRoot /dev/null
inputRoot=`pwd -P`
file1=$( find . -name "*_R1_*q.gz" |sort|head -n ${SGE_TASK_ID}|tail -n 1 |sed -e 's#\./##' )
popd > /dev/null

#create the output folder if it doesn't exist
mkdir -p $outputRoot
#get full path for outputRoot, this isn't necessary
pushd $outputRoot > /dev/null
outputRoot=`pwd -P`
#outputRoot=${outputRoot%/.}
popd > /dev/null
#create folder
outputFolder=$outputRoot/`dirname $file1`
outputFolder=${outputFolder%/.}
mkdir -p $outputFolder

echo $outputFolder

#is there a second file?
file2=${file1/_R1_/_R2_}

#echo $inputRoot/$file1 $inputRoot/$file2

#TODO: develop error handling
if [ -f "$inputRoot/$file2" ]
then
 echo "paired"
 if [[ $clip5 -gt 0 ]]; then
  trim_galore="${trim_galore} --clip_R1 $clip5 --clip_R2 $clip5"
 fi
 if [[ ! -z "$adapter2" ]]; then
  trim_galore="${trim_galore} -a2 $adapter2"
 fi
 echo $trim_galore $extraOptions -q 20 --phred33 -o $outputFolder --no_report_file --paired $inputRoot/$file1 $inputRoot/$file2
 $trim_galore $extraOptions -q 20 --phred33 -o $outputFolder --no_report_file --paired $inputRoot/$file1 $inputRoot/$file2 || exit 1
else
 echo "singlet"
 if [[ $clip5 -gt 0 ]]; then
  trim_galore="${trim_galore} --clip_R1 $clip5"
 fi
 echo $trim_galore $extraOptions -q 20 --phred33 -o $outputFolder --no_report_file $inputRoot/$file1
 $trim_galore $extraOptions -q 20 --phred33 -o $outputFolder --no_report_file $inputRoot/$file1 || exit 1
fi
