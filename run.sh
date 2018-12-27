#!/bin/bash

# Written by Suwon Shon, 2018
# swshon@mit.edu

stage=0

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh
set -e
mfccdir=`pwd`/mfcc
vaddir=`pwd`/mfcc
trials=data/voxceleb1_trials_sv
num_components=2048 # Larger than this doesn't make much of a difference.


if [ $stage -le 0 ]; then
# Preparing dataset folder voxceleb1. The voxceleb1 folder should have subdir voxceleb1_wav which contain wav files.
./local/make_voxceleb1_sv.pl /lan/ibdata/SPEECH_DATABASE/voxceleb1 data

# Extract speaker recogntion features.
steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj 30 --cmd "$train_cmd" \
    data/train exp/make_mfcc $mfccdir
steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj 30 --cmd "$train_cmd" \
    data/test exp/make_mfcc $mfccdir

# VAD decision
sid/compute_vad_decision.sh --nj 40 --cmd "$train_cmd" \
    data/train exp/make_vad $vaddir
sid/compute_vad_decision.sh --nj 40 --cmd "$train_cmd" \
    data/test exp/make_vad $vaddir

for name in train test; do
  utils/fix_data_dir.sh data/${name}
done

fi



if [ $stage -le 2 ]; then

# Train UBM and i-vector extractor.
sid/train_diag_ubm.sh --nj 10 --num-threads 4 --cmd "$train_cmd --mem 10G"\
    data/train $num_components \
    exp/diag_ubm_$num_components

sid/train_full_ubm.sh --nj 10 --remove-low-count-gaussians true \
    --cmd "$train_cmd --mem 10G" data/train \
    exp/diag_ubm_$num_components exp/full_ubm_$num_components

sid/train_ivector_extractor.sh --num-threads 4 --nj 10 --num_processes 1 --cmd "$train_cmd --mem 10G" \
  --ivector-dim 600 \
  --num-iters 5 exp/full_ubm_$num_components/final.ubm data/train \
  exp/extractor

fi

if [ $stage -le 3 ]; then

# Extract i-vectors.
sid/extract_ivectors.sh --cmd "$train_cmd --mem 6G " --nj 30 \
   exp/extractor data/train \
   exp/ivectors_train

sid/extract_ivectors.sh --cmd "$train_cmd --mem 6G " --nj 30 \
   exp/extractor data/test \
   exp/ivectors_test

fi



if [ $stage -le 4 ]; then

# cosine distance scoring
local/cosine_scoring_pairwise.sh data/test data/test \
  exp/ivectors_test exp/ivectors_test $trials local/scores

eer=`compute-eer <(python local/prepare_for_eer.py $trials local/scores/cosine_scores) 2> /dev/null`
echo "CDS eer : $eer"

# LDA+cosine distance scoring
local/lda_scoring_pairwise.sh data/train data/test data/test \
  exp/ivectors_train exp/ivectors_test exp/ivectors_test $trials \
  local/scores

eer=`compute-eer <(python local/prepare_for_eer.py $trials local/scores/lda_scores) 2> /dev/null`
echo "LDA+CDS eer : $eer"

# PLDA scoring
ivector-mean scp:exp/ivectors_train/ivector.scp exp/ivectors_train/mean.vec
local/plda_scoring_pairwise.sh data/train data/test data/test \
  exp/ivectors_train exp/ivectors_test exp/ivectors_test \
  $trials local/scores

eer=`compute-eer <(python local/prepare_for_eer.py $trials local/scores/plda_scores) 2> /dev/null`
echo "PLDA eer : $eer"

fi


#GMM-2048 CDS eer : 15.6
#GMM-2048 LDA+CDS eer : 7.937
#GMM-2048 PLDA eer : 5.652


