
# Speaker Verification task in Voxceleb1 dataset
This repository contains simple scripts for a training i-vector speaker recognition system on Voxceleb1[1] dataset using Kaldi. It was modified based on swshon's work[2]. Note that this experiment is indeed not speaker verification. The scoring is to compute similarity between two test utterances rather than that between a enrolled speaker and a test utterance.

# Requirement
* Kaldi Toolkit

# How to use
1. Download and unzip audio files from http://www.robots.ox.ac.uk/~vgg/data/voxceleb/vox1.html
2. Create a directory named voxceleb1 with two subdirectories named train and test.  Move dev data to train directory, test data to test directory.
3. Download List of trial pairs for Verification(http://www.robots.ox.ac.uk/~vgg/data/voxceleb/meta/veri_test.txt). Move it to voxceleb1 dir.
4. run cmd: ln -fsr "your path to kaldi-trunk/egs/sre08/v1/sid" sid
5. run cmd: ln -fsr "your path to kaldi-trunk/egs/sre08/v1/steps" steps
6. run cmd: ln -fsr "your path to kaldi-trunk/egs/sre08v/1/utils" steps
7. Modify dataset directories and parameters in run.sh file to fit in your machine.
8. Run run.sh file

# Result

The 2048 component GMM-UBM and 600-dimensional i-vector extractor were trained using voxceleb1 training data for verification task. Training parameter is almost same compared to sre10 baseline on Kaldi egs.

GMM-2048 CDS eer : 15.6%<br />
GMM-2048 LDA+CDS eer : 7.937%<br />
GMM-2048 PLDA eer : 5.652%<br />

# Note
The Voxceleb1 dataset, a large-scale speaker identification dataset was published in 2017 with speaker embedding baseline[1] and reported i-vector shows 8.8% EER. The i-vector was extracted using 1024 component GMM-UBM, so the EER is fairly worse compared to the result above.


# Reference
[1] A. Nagraniy, J. S. Chung, and A. Zisserman, “VoxCeleb: A large-scale speaker identification dataset,” in Interspeech, 2017, pp. 2616–2620.

[2] https://github.com/swshon/voxceleb-ivector

