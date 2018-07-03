name="ihec.rna-seq.processing.sh"

installFolder=/home/user/git/ihec_processing/atac_encode_pipeline/ihec.rna-seq.processing
referenceFolder=/data/references

environment="grape-nf-test"
grapeScript=$installFolder/ihec.rna-seq.grape-nf.sh
trimScript=$installFolder/trim_galore_array.sh
TMPDIR=/tmp
adapter=""
extraOptions=""
extraTrimOptions=""

printHelp(){

  echo -e "" >&2
  echo -e "Trim reads and process them with the IHEC pipeline (grape-nf)." >&2
  echo -e "" >&2
  echo -e "Usage: $name <options>" >&2
  echo -e "" >&2
  echo -e " Mandatory options:" >&2
  echo -e "  -i DIR\tinput folder containing (illumina-named) reads" >&2
  echo -e "  -n STR\tsample name"
  echo -e "  -o DIR\toutput folder" >&2
  echo -e "" >&2
  echo -e "  Reference option" >&2
  echo -e "   -s STR\tSpecies, valid short-cuts: hs38, hs37, mm10" >&2
  echo -e "   OR" >&2
  echo -e "   -g FILE\tfasta file containing the reference genome" >&2
  echo -e "   -r REF\tSTAR reference genome index" >&2
  echo -e "   -t FILE\tGTF file with transcript annotation" >&2
  echo -e "" >&2
  echo -e " Optional options" >&2
  echo -e "  -a STR\talternative adapter sequence, overriding Trim_galore's" >&2
  echo -e "        \t autodetection" >&2
  echo -e "  -w    \twait on the second job" >&2
  echo -e "" >&2

}

#code to generate genome index
#STAR --runThreadN ${cpus} \
#		 --runMode genomeGenerate \
#		 --genomeDir genomeDir \
#		 --genomeFastaFiles ${genome} \
#		 --sjdbGTFfile ${annotation} \
#    --sjdbOverhang ${sjOverHang}


while getopts "i:n:o:s:g:r:t:a:wh" opt; do
  case "$opt" in
    i) inputFolder="$OPTARG" ;;
    n) sampleName="$OPTARG" ;;
    o) outputFolder="$OPTARG" ;;
    s)
      case "$OPTARG" in
        hs38)
          genomeFasta=$referenceFolder/hs38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
          genomeIndex=$referenceFolder/hs38/indices/ihec_star
          transcriptAnnotation=$referenceFolder/hs38/gencode.v22.annotation.201503031.gtf
        ;;
        mm10)
          genomeFasta=$referenceFolder/mm10/GRCm38mm10_PhiX_Lambda.fa
          genomeIndex=$referenceFolder/mm10/indices/ihec_star
          transcriptAnnotation=$referenceFolder/mm10/gencode.vM2.annotation.noChr.gtf
          extraOptions="$extraOptions --wig-ref-prefix -"
        ;;
        hs37)
          genomeFasta=$referenceFolder/hs37/hs37d5_PhiX_Lambda.fa
          genomeIndex=$referenceFolder/hs37/indices/ihec_star
          transcriptAnnotation=$referenceFolder/hs37/gencode.v19.annotation.noChr.gtf
          extraOptions="$extraOptions --wig-ref-prefix -"
        ;;
        *)
          echo -e "ERROR: $(date) ($name): $OPTARG not yet a supported species" >&2
          printHelp
          exit 1
        ;;
      esac
    ;;
    g) genomeFasta="$OPTARG" ;;
    r) genomeIndex="$OPTARG" ;;
    t) transcriptAnnotation="$OPTARG" ;;
    a) extraTrimOptions="$extraTrimOptions -a $OPTARG" ;;
    w) waitExtra="-sync y" ;;
    h) printHelp; exit 0 ;;
    *) printHelp; exit 1 ;;
  esac
done

#check that all mandatory variables are set
if [[ -z ${inputFolder+x} ]] || [[ -z ${outputFolder+x} ]] || \
    [[ -z ${genomeFasta+x} ]] || [[ -z ${genomeIndex+x} ]] || \
    [[ -z ${transcriptAnnotation+x} ]] || [[ -z ${sampleName+x} ]]; then
  echo -e "ERROR: $(date) ($name): all mandatory options must be set" >&2
  printHelp
  exit 1
fi

#make sure we have full paths everywhere
inputFolder=$(readlink -m $inputFolder)
outputFolder=$(readlink -m $outputFolder)
genomeFasta=$(readlink -m $genomeFasta)
genomeIndex=$(readlink -m $genomeIndex)
transcriptAnnotation=$(readlink -m $transcriptAnnotation)

TMPWD=$(mktemp -d --tmpdir=$TMPDIR $sampleName.XXXXXXXX)

mkdir -p $outputFolder/log

#trim data
mkdir -p $TMPWD/trimmed
echo "qsub -N trim.$(basename $TMPWD) -t 1-$(find $inputFolder -name "*_R1_*q.gz" |wc -l) -o $outputFolder/log/ $trimScript -i $inputFolder -o $TMPWD/trimmed $extraTrimFlags" > $outputFolder/jobs.sh


echo "qsub $waitExtra -hold_jid trim.$(basename $TMPWD) -N grape.$(basename $TMPWD) -o $outputFolder/log/ $grapeScript "$environment" $sampleName $TMPWD $TMPWD/trimmed $genomeFasta $genomeIndex $transcriptAnnotation $outputFolder \"$extraOptions\"" >> $outputFolder/jobs.sh

bash $outputFolder/jobs.sh

echo -e "LOGG ($(date)) $name: Jobs submitted" >&2
