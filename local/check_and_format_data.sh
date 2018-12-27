#!/bin/bash

# Author: Jerry Peng 2018
# In this script, 
#  1) we check the format of wav files inside a given directory
#  2)    create wav.scp. It will be used in kaldi.



posfix="*.MP3"
cleanup=false

. ./utils/parse_options.sh || exit 1;

if [ $# -ne 2 ]; then
  echo "Usage: check_and_format_data.sh [--posfix='*.MP3|*.mp3|*.WAV|*.wav'] <ipath2audio_dir> <opath2data_dir>"
  echo "Check the format of the input data and generate wav.list and wav.scp to opath2data_dir."
  echo "--posfix='*.MP3' by default. The output wav.list and wav.scp contain only audio files with the specified posfix."
  exit 1
fi

# ipath2dir="/lan/ibdata/SPEECH_DATABASE/RTHK_raw_data/Sound_Archives/2017"
# opath2dir="data/2017"

ipath2dir=$1;
opath2dir=$2;


[ ! -d "$ipath2dir" ] && echo "$ipath2dir doesn't exist!" && exit 1;
mkdir -p "$opath2dir"

echo ">> Start check and format data ============================================"

# list audios with different formats
audio_postfixes="*.wav *.WAV *.mp3 *.MP3"

numfiles_total=0
for i in $audio_postfixes; do
  numfiles=`find $ipath2dir -type f -name "$i" | wc -l`
  numfiles_total=$((numfiles_total+numfiles))
  printf "There are %8d audio files with postfix: %s\n" $numfiles "$i"
done
echo "Found $numfiles_total audio files in total under dir $ipath2dir"

echo "Now, we only take $posfix into consideration."
fpaths="find $ipath2dir -type f -name $posfix -print0"

# check sampling frequency
echo "1) check sampling frequency. The first column is #files, second column is sampling frequency"
$fpaths | xargs -0 soxi -r 2> /dev/null | uniq | sort | uniq -c

# the result shows two files are broken. And they should be get rid of.
# the rest files are all 48kHz.

echo "2) check number of channels. The first column is #files, second column is #channels"
$fpaths | xargs -0 soxi -c 2> /dev/null | sort | uniq -c
# the rest files are all 2-channel(stereo)

echo "3) check precision. The first column is #files, second column is #bits/sample"
$fpaths | xargs -0 soxi 2> /dev/null | grep "Precision" | sort | uniq -c
# the rest files are all 16-bit

echo "4) generate the valid audio file list wav.list and wav.scp to $opath2dir"
$fpaths | xargs -0 soxi 2> /dev/null | grep "Input File" | cut -d\' -f2 > $opath2dir/wav.list
numvalidfiles=`wc -l $opath2dir/wav.list | cut -d' ' -f1`
echo "$numvalidfiles valid audio files are written into $opath2dir/wav.list"

#perl -CSAD local/gen_wavscp.pl $opath2dir/wav.list | sort -k1,1 -u  > $opath2dir/wav_org.scp
#numvalidformat_file=`wc -l $opath2dir/wav_org.scp | cut -d' ' -f1`
#echo "${numvalidformat_file} correctly-formated audio files are written into $opath2dir/wav_org.scp"
#echo "Note that some audio in $opath2dir/wav.list may not have\
# the presumed format in local/gen_wavscp.pl. And they are discarded from $opath2dir/wav_org.scp"
#
#echo "5) check the total duration of audio in file $opath2dir/wav_org.scp"
#dur=`cut -d' ' -f2- $opath2dir/wav_org.scp | xargs -I{} soxi -d {} | 
#  awk -F'[:,]' '{sumh+=$1; summ+=$2; sums+=$3}; END{print sumh+summ/60+sums/3600}'`
#echo "$dur hours in total."
#
#
#
#echo "6) convert format to 16kHz, mono channel, wav audio"
#
## stereo to mono channel
## 44.1k to 16k
## mp3 to wav
#perl -CSAD local/cvt_wavformat.pl $opath2dir/wav_org.scp > $opath2dir/wav_cvt.scp
#echo "output wav_cvt.scp to $opath2dir"
#
#ln -fsr $opath2dir/wav_cvt.scp $opath2dir/wav.scp || exit 1;
#echo ">> finish check and format data ========================================"
#
#if $cleanup; then
#  rm $opath2dir/wav.list
#fi

exit 0;
