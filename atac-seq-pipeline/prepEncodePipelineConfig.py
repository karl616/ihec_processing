import json
import argparse

#TODO: how to control output folder and output names?

def prepare_argparser():
  parser =  argparse.ArgumentParser(prog = 'prepEncodePipelineConfig.py')

  parser.add_argument('-p', '--pipeline_type',
      dest='atac.pipeline_type',
      required=True,
      choices=['dnase', 'atac'],
      help="Which type of pipeline to configure")

  parser.add_argument('-a', '--rep1_R1',
      dest='atac.fastqs_rep1_R1',
      nargs='+',
      required=True,
      help="list of read 1 files belonging to replicate 1")

  parser.add_argument('-b', '--rep1_R2',
      dest='atac.fastqs_rep1_R2',
      nargs='+',
      help="list of read 2 files belonging to replicate 1. Same order as read 1")

  parser.add_argument('-r', '--genome_tsv',
      dest='atac.genome_tsv',
      required=True,
      help="Path to the reference definition file to use")

  parser.add_argument('-n', '--qc_report.name',
      dest='atac.qc_report.name',
      required=True,
      help="Sample name")

  parser.add_argument('--disable_paired_end',
      dest='atac.paired_end',
      action='store_false',
      default=True,
      help='atac.paired_end')

  parser.add_argument('--multimapping',
      dest='atac.multimapping',
      default=4,
      type=int,
      help="atac.multimapping (int)")

  parser.add_argument('--disable_auto_detect_adapter',
      dest='atac.trim_adapter.auto_detect_adapter',
      action='store_false',
      default=True,
      help="atac.trim_adapter.auto_detect_adapter")

  parser.add_argument('--smooth_win',
      dest='atac.smooth_win',
      default=73,
      type=int,
      help="smooth_win (int)")

  parser.add_argument('--disable_idr',
      dest='atac.enable_idr',
      default=True,
      action='store_false',
      help="disable idr")

  parser.add_argument('--idr_thresh',
      dest='atac.idr_thresh',
      default=0.05,
      type=float,
      help="idr_thresh (float)")
      
  parser.add_argument('--qc_report.desc',
      dest='atac.qc_report.desc',
      default="Encode pipeline processed open chromatin data",
      help="qc_report.desc")

  parser.add_argument('--filter.dup_marker',
      dest='atac.filter.dup_marker',
      choices=['picard', 'sambamba'],
      default='picard',
      help="filter.dup_marker")

  return(parser)


def main():
  argparser=prepare_argparser()
  config=argparser.parse_args()

  print(json.dumps(vars(config),indent=4, sort_keys=True))

if __name__ == "__main__":
  main()
