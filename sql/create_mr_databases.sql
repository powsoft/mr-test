{\rtf1\ansi\ansicpg1252\cocoartf1344\cocoasubrtf720
{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red0\green0\blue120;\red234\green234\blue234;\red0\green0\blue0;
\red107\green0\blue1;\red107\green0\blue1;\red234\green234\blue234;\red43\green39\blue19;\red0\green0\blue120;
}
\margl1440\margr1440\vieww10800\viewh8400\viewkind0
\deftab720
\pard\pardeftab720

\f0\fs26 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 CREATE\cf4 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec4  \cf2 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 DATABASE\cf4 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec4  DataTrue_Main\
\cf2 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 ON\cf4 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec4  (\
  NAME = DataTrue_Main_dat,\
  FILENAME = \cf5 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec5 \'91C:\\\cf6 \cb7 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 icontrol\\mr\\\cf5 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec5 data\\\cf0 \cb7 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 DataTrue_Main\cf5 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec5 .mdf'\cf4 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec4 \
)\
LOG \cf2 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 ON\cf4 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec4  (\
  NAME = \cf0 \cb7 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 DataTrue_Main\cf4 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec4 _log,\
  FILENAME = \cf5 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec5 \'91C:\\\cf6 \cb7 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 icontrol\\mr\\\cf5 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec5 log\\DataTrue_Main.ldf'\cf4 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec4 \
);\cf8 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec8 \
\
\pard\pardeftab720
\cf9 \cb7 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 CREATE\cf0 \expnd0\expndtw0\kerning0
 \cf9 \expnd0\expndtw0\kerning0
DATABASE\cf0 \expnd0\expndtw0\kerning0
 DataTrue_EDI\
\cf9 \expnd0\expndtw0\kerning0
ON\cf0 \expnd0\expndtw0\kerning0
 (\
  NAME = \cb7 \expnd0\expndtw0\kerning0
DataTrue_EDI\cb7 \expnd0\expndtw0\kerning0
_dat,\
  FILENAME = \cf6 \expnd0\expndtw0\kerning0
\'91C:\\icontrol\\mr\\data\\\cf0 \cb7 \expnd0\expndtw0\kerning0
DataTrue_EDI\cf6 \cb7 \expnd0\expndtw0\kerning0
.mdf'\cf0 \expnd0\expndtw0\kerning0
\
)\
LOG \cf9 \expnd0\expndtw0\kerning0
ON\cf0 \expnd0\expndtw0\kerning0
 (\
  NAME = \cb7 \expnd0\expndtw0\kerning0
DataTrue_EDI\cb7 \expnd0\expndtw0\kerning0
_log,\
  FILENAME = \cf6 \expnd0\expndtw0\kerning0
\'91C:\\icontrol\\mr\\log\\DataTrue_EDI.ldf'\cf0 \expnd0\expndtw0\kerning0
\
);}