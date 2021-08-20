#!/bin/bash
mkdir hw2_q1
cd hw2_q1/
pwd
# /c/Users/Daniil/Documents/Uni Shenanigans/MATH2504/HW2/q1/hw2_q1
echo "Dan"
# Dan
echo "Dan" > my_name.txt
cat my_name.txt
# Dan
ls -lh
# total 1.0K
# -rw-r--r-- 1 Daniil 197121 4 Aug 20 11:21 my_name.txt
cp my_name.txt my_name2.txt
mkdir people
mv my_name2.txt people/Dan_Zaikin.txt
echo "Charlie" > people/Charles_Parker.txt
echo "Buddy" > people/Bernard_Rich.txt
echo "Lionel" > people/Lionel_Hampton.txt
cd people/
mv Dan_Zaikin.txt ../Dan_Zaikin.txt
mv Charles_Parker.txt "/c/Users/Daniil/Documents/Uni Shenanigans/MATH2504/HW2/q1/hw2_q1/Charles_Parker.txt"
ls -lha
# total 7.0K
# drwxr-xr-x 1 Daniil 197121 0 Aug 20 11:40 .
# drwxr-xr-x 1 Daniil 197121 0 Aug 20 11:38 ..
# -rw-r--r-- 1 Daniil 197121 6 Aug 20 11:40 .Bernard_Rich.txt
# -rw-r--r-- 1 Daniil 197121 6 Aug 20 11:29 Bernard_Rich.txt
# -rw-r--r-- 1 Daniil 197121 7 Aug 20 11:36 Lionel_Hampton.txt
rm -rf ./{*,.*}
# rm: refusing to remove '.' or '..' directory: skipping './.'
# rm: refusing to remove '.' or '..' directory: skipping './..'
rmdir people
