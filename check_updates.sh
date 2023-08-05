#!/bin/bash
#
# Script to create md5 hashes and get changes since last run
#

if [ $# -lt 1 ] ; then
  echo "Usage:"
  echo "$0 <hashfile> [<directory>]"
  echo
  exit 1
fi

export HASHFILE="$1"
export TOPDIR="${2:-.}"

export TMPFILE=$HASHFILE.tmp
export BACKFILE=$HASHFILE.bck
export NEWFILE=$HASHFILE.new
export NOFILE=$HASHFILE.no

# Clean old temp files, if any

[ -f "$BACKFILE" ] && rm $BACKFILE
[ -f "$NEWFILE" ]  && rm $NEWFILE
[ -f "$NOFILE" ]   && rm $NOFILE

# In the first run, we create the file $HASHFILE if it does not exist
# You have to make sure that $HASHFILE does not contain any garbage for the first run!!

if [ ! \( -f $HASHFILE -a -s $HASHFILE \) ]; then
  echo -n "Creating $HASHFILE for the first time..."
  /usr/bin/find $TOPDIR -type f -print0 | xargs -0 /usr/bin/md5sum > $HASHFILE
  echo "done."
  exit
fi

# First, find the newer files

/usr/bin/find $TOPDIR -type f -newer $HASHFILE -print > $TMPFILE

# Now save the old file and create a new one, starting with new files

mv $HASHFILE $BACKFILE
echo -n "Processing new or modified files ..."
cat $TMPFILE | while read filename ; do
  /usr/bin/md5sum "$filename" >> $HASHFILE
  if ! grep -q -e " $filename$" $BACKFILE ; then
    echo "$filename" >> $NEWFILE
  fi
done
echo "done."

# Now walk through the old file and process to new file

cat $BACKFILE | while read md5 filename ; do
  # Does the file still exist?
  if [ -f "$filename" ] ; then
    if grep -q -e "^$filename$" $TMPFILE ; then
      echo "$filename has changed!"
    else # not changed
      echo "$md5  $filename" >> $HASHFILE
    fi
  else
    echo "$filename" >> $NOFILE
  fi
done

# delete temporary files
rm $BACKFILE
rm $TMPFILE

# display new files

if [ -f "$NEWFILE" ]; then
  echo "New files:"
  cat $NEWFILE ; rm $NEWFILE
fi

# display removed files

if [ -f "$NOFILE" ]; then
  echo "Removed files:"
  cat $NOFILE ; rm $NOFILE
fi
