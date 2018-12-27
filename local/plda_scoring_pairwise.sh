#!/bin/bash
# Copyright 2015   David Snyder
#           2018   Jerry Peng
# Apache 2.0.
#
# This script trains PLDA models and does scoring.

# Jerry Peng: The original paper voxceleb: a large-scale speaker identification dataset
# seems to use pairwise utterance scoring (Scoring the similarity between
# two utterance_ivectors instead of spk_ivector v.s. test_utt_ivector).
# Due to this reason, we revise the scoring method a little bit.

use_existing_models=false
simple_length_norm=false # If true, replace the default length normalization
                         # performed in PLDA  by an alternative that
                         # normalizes the length of the iVectors to be equal
                         # to the square root of the iVector dimension.

echo "$0 $@"  # Print the command line for logging

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;

if [ $# != 8 ]; then
  echo "Usage: $0 <plda-data-dir> <enroll-data-dir> <test-data-dir> <plda-ivec-dir> <enroll-ivec-dir> <test-ivec-dir> <trials-file> <scores-dir>"
fi

plda_data_dir=$1
enroll_data_dir=$2 # no use
test_data_dir=$3
plda_ivec_dir=$4
enroll_ivec_dir=$5
test_ivec_dir=$6
trials=$7
scores_dir=$8

if [ "$use_existing_models" == "true" ]; then
  for f in ${plda_ivec_dir}/mean.vec ${plda_ivec_dir}/plda ; do
    [ ! -f $f ] && echo "No such file $f" && exit 1;
  done
else
  run.pl $plda_ivec_dir/log/plda.log \
    ivector-compute-plda ark:$plda_data_dir/spk2utt \
    "ark:ivector-normalize-length scp:${plda_ivec_dir}/ivector.scp  ark:- |" \
    $plda_ivec_dir/plda || exit 1;
fi

mkdir -p $scores_dir/log

# run.pl $scores_dir/log/plda_scoring.log \
#   ivector-plda-scoring --normalize-length=true \
#     --simple-length-normalization=$simple_length_norm \
#     --num-utts=ark:${enroll_ivec_dir}/num_utts.ark \
#     "ivector-copy-plda --smoothing=0.0 ${plda_ivec_dir}/plda - |" \
#     "ark:ivector-subtract-global-mean ${plda_ivec_dir}/mean.vec scp:${enroll_ivec_dir}/spk_ivector.scp ark:- | ivector-normalize-length ark:- ark:- |" \
#     "ark:ivector-normalize-length scp:${test_ivec_dir}/ivector.scp ark:- | ivector-subtract-global-mean ${plda_ivec_dir}/mean.vec ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
#     "cat '$trials' | cut -d\  --fields=1,2 |" $scores_dir/plda_scores || exit 1;

run.pl $scores_dir/log/plda_scoring.log \
  ivector-plda-scoring --normalize-length=true \
    --simple-length-normalization=$simple_length_norm \
    "ivector-copy-plda --smoothing=0.0 ${plda_ivec_dir}/plda - |" \
    "ark:ivector-normalize-length scp:${test_ivec_dir}/ivector.scp ark:- | ivector-subtract-global-mean ${plda_ivec_dir}/mean.vec ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
    "ark:ivector-normalize-length scp:${test_ivec_dir}/ivector.scp ark:- | ivector-subtract-global-mean ${plda_ivec_dir}/mean.vec ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
    "cat '$trials' | cut -d\  --fields=1,2 |" $scores_dir/plda_scores || exit 1;