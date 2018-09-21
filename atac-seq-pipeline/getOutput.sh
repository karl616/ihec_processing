name=getOutput.sh

#list of folders to copy without prefix
copyWithoutPrefix=("call-ataqc" "call-bam2ta" "call-bowtie2" "call-filter" "call-macs2" "call-macs2_pooled" "call-macs2_ppr1" "call-macs2_ppr2" "call-macs2_pr1" "call-macs2_pr2" "call-pool_ta" "call-pool_ta_pr1" "call-pool_ta_pr2" "call-spr" "call-xcor")
prefix=""

printHelp(){
  echo -e "" >&2
  echo -e "Copies and organizes the result from the ENCODE atac pipeline" >&2
  echo -e "  Excludes: fastq.gz, nodup.bam and null files" >&2
  echo -e "" >&2
  echo -e "Usage: $name <options>" >&2
  echo -e "" >&2
  echo -e " Mandatory options:" >&2
  echo -e "" >&2
  echo -e "  -r DIR\tresults folder" >&2
  echo -e "  -o DIR\toutput (target) folder" >&2
  echo -e "" >&2
  echo -e " Optional options" >&2
  echo -e "  -p STR\tprefix to add to combined files (default: autodetect)" >&2
}

while getopts "r:o:p:h" opt; do
  case "$opt" in
    r) pipelineOutputFolder="$OPTARG" ;;
    o) outputFolder="$OPTARG" ;;
    p) prefix="$OPTARG" ;;
    h) printHelp; exit 0 ;;
    *) printHelp; exit 1 ;;
  esac
done

if [[ -z "$pipelineOutputFolder" ]] || [[ -z "$outputFolder" ]]; then
  echo -e "ERROR $(date) ($name): All mandatory options must be set" >&2
  printHelp
  exit 1
fi

if [[ -z "$prefix" ]]; then
  qcFile=$(find $pipelineOutputFolder -name qc.json)
  if [[ -e $qcFile ]]; then
    prefix=$(
        cat $qcFile \
          | python -c "import sys, json; print(json.load(sys.stdin)['name'])"
      )
  fi
fi

#set -x

#identify root of results (assumes there is a call-macs2 folder with
# glob* subfolders
rootFolder=$(
    find $pipelineOutputFolder -type d -name "glob-*" |grep "/call-macs2/" \
      | sed -e "s@/call-macs2/.*@@" |sort -u
  )

#copy files 
for s in $rootFolder/*; do
  #Only use prefix for folders not present in the list
  prefixToUse=""
  if [[ -n "${prefix}" ]] \
      && [[ -z "$(
        echo ${copyWithoutPrefix[@]} | grep -w "$(basename $s)"
      )" ]]; then
    prefixToUse=${prefix}_
  fi

  target=$outputFolder/$(basename $s)
  mkdir -p $target
  #copy all files
  find $s -type f -print0 | grep -zZ "/glob-.*/" \
    | grep -vzZ -e "fastq.gz" -e "nodup.bam" -e "null" \
    | while IFS= read -r -d '' fileName; do
        cp $fileName $target/${prefixToUse}$(basename $fileName)
      done
done

#remove empty folders
find $outputFolder -type d -empty -delete


echo -e "DONE! All files copied" >&2

