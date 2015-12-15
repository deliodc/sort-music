#!/bin/bash
# Name: Ordea Música
# Author: Delio Docampo Cordeiro
# Version:20151215
# Description: This script, copy mp3 files of multiple
# subdirectories, and sort them by their album year of
# creation, their number of track for this album, and
# copies this mp3 files in one main directory, with a
# new file label, with the next structure:
# 
# <album_order>-<track_order>-<song_title>
# 
###################


E_ERROR='\033[0;31m'
E_INFO='\e[0;34m'
E_WORK='\e[0;32m'
E_NC='\033[0m'
# Check input parameters
if [ -z "$1" ]
 then
   ROOT="`pwd .`"
   echo -e "${E_INFO}Non se definiu o primer parámetro, se usará o actual directorio como raíz:\n$ROOT${E_NC}\n"
 else
   ROOT="$1"
fi
if [  -z "$2" ]
 then
   DATE_TITLE=`date +"_%Y%m%d_%H:%M:%S"`
   OUTPUT_TITLE="OUTPUT$DATE_TITLE"
   DESTINY_DIR=`pwd`"/$OUTPUT_TITLE"
   mkdir -vp "$DESTINY_DIR"
   echo -e "${E_INFO}Non se definiu o segundo parámetro, se usará ./$OUTPUT_TITLE como directorio de saida:\n$DESTINY_DIR${E_NC}"
 else
   DESTINY_DIR="$2"
   mkdir -vp "$DESTINY_DIR"
fi
# END Check input parameters

function sort_int_numbers(){
  # Sort a numbers input parameter array
  local SORT_NUMBERS NUMBERS_TO_WORK NUMBERS
  declare -a NUMBERS=("${!1}")
  NUMBERS_TO_WORK=(${NUMBERS[@]})
  IFS=$'\n' SORT_NUMBERS=($(sort -n <<<"${NUMBERS[*]}"))
  for (( C=0; C<${#SORT_NUMBERS[@]}; C++))
    do
      for (( C2=0; C2<${#NUMBERS[@]}; C2++ ))
	do
	    if [ ${SORT_NUMBERS[$C]} -eq ${NUMBERS_TO_WORK[$C2]} ];then
	      INDEX+=($(($C2))) 
	      NUMBERS_TO_WORK[$C2]="-1"
	      break
	    fi
      done
  done
}

function older_mp3(){
  # Takes the most older mp3 from the directorie or the year of directorie title
  local PROCESS_DIR="$1" LIST_SONGS TEMP_DATE OLD_DATE
  LIST_SONGS=`find $PROCESS_DIR -type f -iname *.mp3`
  for SONG in $LIST_SONGS
  do
    TEMP_DATE=`mediainfo  $SONG  2> /dev/null | grep date | grep [0-9]{4} -Po | uniq`
    if [[ -z $OLD_DATE ]];then # if OLD_DATE is undefined
      if [[ -z $TEMP_DATE ]]; then # if TEMP_DATE is undefined
        TEMP_DATE=`echo $PROCESS_DIR| grep [0-9]{4} -Po | uniq ` #try to take a year from folders name
      fi
    OLD_DATE=$TEMP_DATE
    fi
    if [[ ! -z $TEMP_DATE ]];then
      if [[ $TEMP_DATE < $OLD_DATE ]];then
        OLD_DATE=$TEMP_DATE
      fi
    fi
  done
  if [[ ! -z $OLD_DATE ]];then
      echo $OLD_DATE | grep [0-9]{4} -Po | uniq 
    else
      echo "NULL"
  fi
}

function copy_mp3_files(){
  NDIRS=${#DIR_PATH_LOCAL[@]}
  for (( C_DIR=0; $C_DIR<$NDIRS; C_DIR++));
    do
      unset Z  DESTINY_FILES FILE_PATH_OLD DIR_NUM_RAW
      DIR_NUM_RAW=$(($C_DIR+1))
      for (( ZC_DIR=0; ZC_DIR<$((${#NDIRS}-${#DIR_NUM_RAW})) ; ZC_DIR++)) 
	do
	  Z="$Z"0
      done
      if [ 0 -eq $((${#NDIRS}-${#DIR_NUM_RAW})) ] && [ $DIR_NUM_RAW -lt 10 ];then
        Z=0
      fi
      DIR_NUM=$Z$DIR_NUM_RAW
      if [ $C_DIR -lt $NDIRS ];then
	DIR="${DIR_PATH[$C_DIR]}"
	local LIST_FILES_RAW=`ls "$DIR"/*.[mM][pP]3`
	unset LIST_FILES
	IFS=$'\n' # Set the cut character for "for" in the new line character
	for FILE in ${LIST_FILES_RAW[@]}
	  do
	    # This make the list of files, from the LIST_FILES_RAW
	    FILE_PATH_OLD+=($FILE)
	    FILE_TITLE=`basename $FILE`
	    FILE_TITLE=`echo $FILE_TITLE | awk 'BEGIN { FS = "^[0-9._ -]*" } { print $2 }'`
	    if [ -z $FILE_TITLE ];then
	      # If the file title no start with a number o especial character, uses a complet file title.
	      FILE_TITLE=`basename $FILE`
	    fi
	    LIST_FILES+=($FILE_TITLE)
	done
	unset FILE CF ZF
	NFILES=${#LIST_FILES[@]}
	#############
	for (( CF=0 ; CF<${#LIST_FILES[@]} ; CF++))
	  do
	    FILE_TITLE=${LIST_FILES[$CF]}	
	    unset Z
	    for (( ZC=0; ZC<$((${#NFILES}-${#CF})) ; ZC++))
	      do
	      #Zero count menor que numero digitos archivos totales menos número dígitos CF count files
		Z="$Z"0
	      done
	    TEMP_FILE_NUM=$Z$(($CF+1))
	    if [[ ${#TEMP_FILE_NUM} -gt ${#NFILES} ]];then
	      TEMP_FILE_NUM=$(($CF+1))
	    fi
	    FILE_NUM=$TEMP_FILE_NUM
	    NEW_FILE_TITLE=$DIR_NUM-$FILE_NUM-$FILE_TITLE
	    DESTINY_FILES+=("$DESTINY_DIR/$NEW_FILE_TITLE")	    
          done
	unset FILE_TITLE CF
	IFS=$'\n'
	for (( CF=0; $CF<${#FILE_PATH_OLD[@]} ; CF++ ))
	  do
	    cp -v "${FILE_PATH_OLD[$CF]}" "${DESTINY_FILES[$CF]}"
	  done
      fi
    done
}


function mp3_organize(){
  #   This function takes DIR_PATH and DIR_YEAR from parametters, 
  # evaluate the date on .mp3 files or directories titles, and
  # sort chronologically if all directories have a date or alphabetical
  # if one or many directories no have a date.
  ####
  local DIR_PATH_LOCAL DIR_YEAR_LOCAL YEAR ORDER
  declare -a DIR_YEAR_LOCAL=(${DIR_YEAR[@]})
  declare -a DIR_PATH_LOCAL=(${DIR_PATH[@]})
  ORDER="chronologically"
  for YEAR in ${DIR_YEAR_LOCAL[@]};
    do
      if [[ $YEAR == "NULL" ]];then
	    ORDER="alphabetical"
      fi
  done  
  # 1.- Check if wont to organize alphabetical or chronologically
  if [[ -z $ORDER ]];then
    ORDER="alphabetical"
  fi

  if [[ ! -z $ORDER ]];then
    if [[ $ORDER == "chronologically" ]];then
      sort_int_numbers DIR_YEAR_LOCAL[@]
      local COUNT=0
      for C_YEAR in ${INDEX[@]}
	do
	  DIR_YEAR[$COUNT]=${DIR_YEAR_LOCAL[$C_YEAR]}
	  DIR_PATH[$COUNT]=${DIR_PATH_LOCAL[$C_YEAR]}
	  let COUNT++
      done
#     else
      #alphabetical no order
    fi
    copy_mp3_files
  fi
}

function music_sort(){
  local COUNT=0
  DIRECTORIES=`find "$ROOT"  -iname *.mp3 -exec dirname {} \; | uniq | sort`
  IFS=$'\n' # Set the cut character for "for" in the new line character
  for DIR in $DIRECTORIES
    do
      DIR_PATH[$COUNT]=$DIR
      DIR_YEAR[$COUNT]=$(older_mp3 $DIR)  # the knot part  # get the most older year of mp3 in the dir 
      let COUNT++
  done
  unset COUNT
  mp3_organize
}


music_sort