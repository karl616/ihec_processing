#$ -cwd
#$ -S /bin/bash
#$ -V
#$ -j y
#$ -l mem_free=67G
#$ -l h_vmem=67G

minicondaFolder=/home/user/miniconda2
nextflowFolder=/home/user/.nextflow



environment=$1
sampleName=$2
TMPWD=$3
trimmedFolder=$4
genomeFasta=$5
genomeIndex=$6
transcriptAnnotation=$7
outputFolder=$8
extraOptions=$9

#all fileIDs and file names must be unique ==> flatten folder structure
# this construct will move everything in folders to the main folder

pushd $trimmedFolder
  find . -mindepth 2 -name "*.fq.gz" \
    | xargs -l dirname \
    | sed -e "s/^.\///" \
    | sort -u \
    | while read folder; do
        prefix=$(echo $folder | sed -e "s/\//_/g")
        for s in $folder/*.fq.gz; do
          if [[ -e ${prefix}_$(basename $s) ]]; then
            #this should very rarely happen
            mv $s $(mktemp -u ${prefix}_XXX_$(basename $s))
          else
            mv $s ${prefix}_$(basename $s)
          fi
        done
      done
  #remove folders? not necessary
#  find . -maxdepth 1 -mindepth 1  -type d \
#    | xargs rm -r    

popd &> /dev/null


#generate input (index) file

#sampleID fileID path "fastq" "FqRd{"",1,2}"
find $trimmedFolder -name "*.fq.gz" \
  | sed -e 's/\(.*\)\/\(.*_[ATGCN-]\{4,24\}_L00[0-9]\)_R\([12]\)_\([0-9]\{3\}\)_\(.*\).fq.gz/\5 \2_\4 \0 fastq FqRd\3/g' \
  | mawk -vOFS='\t' -vname=$sampleName -vfolder=$trimmedFolder '
      $1~/trimmed/ {$5="FqRd"}
      {
        $1=name
        NF=5
        print
      }
    ' \
> $outputFolder/readIndex.tsv


unset PYTHONPATH

source $minicondaFolder/bin/activate $environment

  echo -e "LOGG ($(date)) $name: Enter work folder" >&2
  pushd $outputFolder
    nextflow \
        -c $nextflowFolder/assets/guigolab/grape-nf/resource.config \
        run -qs 1 -without-docker -w $outputFolder/work grape-nf \
        --index $outputFolder/readIndex.tsv --genome $genomeFasta \
        --annotation $transcriptAnnotation \
        --steps mapping,bigwig,quantification \
        --genomeIndex $genomeIndex $extraOptions || exit 8    
    mv $(mawk '{print $3}' pipeline.db) $outputFolder
    #removal of work folder conditional on that the pipeline finished
    if [[ $( 
          tail -n 1 trace.txt | awk '$6=="COMPLETED" {print 1}' 
        ) == 1 ]]; then
      rm -r $outputFolder/work
      rm -rf $TMPWD
    fi

  popd &> /dev/null
  

#TODO: add general deactivate step?

source $minicondaFolder/bin/deactivate







