#!/bin/bash

# Check if our files exist
# Dictionary
# Names

if [ -z $1 ]; then
cat << 'EOF'
         ___                _     _                                            _            
        / __\___  _ __ ___ | |__ (_)_ __   ___  /\  /\__ _ _ ____   _____  ___| |_ ___ _ __ 
       / /  / _ \| '_ ` _ \| '_ \| | '_ \ / _ \/ /_/ / _` | '__\ \ / / _ \/ __| __/ _ \ '__|
      / /__| (_) | | | | | | |_) | | | | |  __/ __  / (_| | |   \ V /  __/\__ \ ||  __/ |   
      \____/\___/|_| |_| |_|_.__/|_|_| |_|\___\/ /_/ \__,_|_|    \_/ \___||___/\__\___|_|   
                                                                                            
Combine the results of TheHarvester
[-] Multi Threaded
[-] Parses out human/non-human email addresses
[-] Builds CSV of found names & email addresses

Usage: combineharvester domain


Outputs:
    human.domain.com.csv: CSV of names and email addresses of real people'
    nothuman.domain.com.txt: TXT of shared/non identifying mailboxes'


Based on the awesome work of Christian Martorella
https://github.com/laramies/theHarvester

EOF

exit

fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Pick Domain
domain=$1
echo "Harvesting for $domain"

# Build Temp Area
tmpdir=$(mktemp -d)
#tmpdir="/tmp/tmp.74sl4boaCs"
mkdir $tmpdir/harvested

#tmpdir="/tmp/tmp.3d6W6mOZfe"
# Run Harvester
#theharvester -d $domain -b google bing linkedin pgp jigsaw bingapi people123 google-profiles dogpilesearch twitter googleplus yahoo baidu

##### SKIP FOR DEBUG ###
  
# Asynchronous
#harvesters=( google linkedin )
harvesters=( google linkedin bing people123 jigsaw googleplus yahoo baidu pgp bingapi )

for harvester in "${harvesters[@]}"
do
    harvester_name=$(echo "$harvester" | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
    { echo "[-] Starting harvesting from $harvester_name"; theharvester -d $domain -b $harvester > $tmpdir/harvested/$harvester; } &
done

echo "This is going to take a while... grab a cup of tea ^ . ^"

# Progress bar goes here maybe?
# Count the number of harvesters, divide screen width and build a bar.
wait

##### SKIP FOR DEBUG ###


# Parse out emails
echo "[-] Parsing Emails"
grep --ignore-case --fixed-strings --no-filename @$domain $tmpdir/harvested/* | tr '[A-Z]' '[a-z]' | grep --invert-match '^@' |grep --invert-match '?'| sort | uniq > $tmpdir/all-emails


# Try and determine human email addresses
sed "s/@$domain//" $tmpdir/all-emails > $tmpdir/emails.nodomain

echo "[-] Enumerating Human Emails"
# We do two passes to try and pull out shared addresses
grep --fixed-strings --word-regexp --invert-match --file="$DIR/dictionary" $tmpdir/emails.nodomain | grep --fixed-strings --invert-match --file="$DIR/long-dictionary" | sed "s/$/@$domain/" > $tmpdir/human-emails

echo "[-] Enumerating Shared Mailboxes"
# Separate out shared email addresses
grep --fixed-strings --line-regexp --invert-match --file="$tmpdir/human-emails" $tmpdir/all-emails > $tmpdir/shared-emails

#If we don't already have name lists, drop them in the project folder
# curl -s "http://deron.meranda.us/data/census-derived-all-first.txt" | awk '{print $1}' > firstnames.txt
# curl -s "http://www2.census.gov/topics/genealogy/1990surnames/dist.all.last" | awk '{print $1}' > lastnames.txt
# Combine, lowercase
# Get normal dictionary, strip apostraphies, lowercase, strip everything 2 characters and shorter
# Strip everything out of the dictionary that is a name
# That's our dictionary file
# We then take all the 7+ character words and make our dictionary-long

# Cleanup
rm $tmpdir/all-emails
rm $tmpdir/emails.nodomain

echo "[-] Enumerating Naming Conventions"
# Process Human Emails
sed "s/@$domain//" $tmpdir/human-emails > $tmpdir/human-emails.nodomain

# I'm so sorry, I know this part is disgusing :(

echo -n "firstname.lastname " > $tmpdir/naming-convention-counts
{ grep --count --perl-regexp '^[a-z]{2,}\.[a-z]{2,}$' $tmpdir/human-emails.nodomain || true; } >> $tmpdir/naming-convention-counts

echo -n "firstname-lastname " >> $tmpdir/naming-convention-counts
{ grep --count --perl-regexp '^[a-z]{2,}\-[a-z]{2,}$' $tmpdir/human-emails.nodomain || true; } >> $tmpdir/naming-convention-counts

echo -n "firstname_lastname " >> $tmpdir/naming-convention-counts
{ grep --count --perl-regexp '^[a-z]{2,}\_[a-z]{2,}$' $tmpdir/human-emails.nodomain || true; } >> $tmpdir/naming-convention-counts

echo -n "firstnamelastname " >> $tmpdir/naming-convention-counts
{ grep --count --perl-regexp '^[a-z]{12,}$' $tmpdir/human-emails.nodomain || true; } >> $tmpdir/naming-convention-counts

echo -n "f.lastname " >> $tmpdir/naming-convention-counts
{ grep --count --perl-regexp '^[a-z]{1}\.[a-z]{2,}$' $tmpdir/human-emails.nodomain || true; } >> $tmpdir/naming-convention-counts

echo -n "f-lastname " >> $tmpdir/naming-convention-counts
{ grep --count --perl-regexp '^[a-z]{1}\-[a-z]{2,}$' $tmpdir/human-emails.nodomain || true; } >> $tmpdir/naming-convention-counts

echo -n "f_lastname " >> $tmpdir/naming-convention-counts
{ grep --count --perl-regexp '^[a-z]{1}\_[a-z]{2,}$' $tmpdir/human-emails.nodomain || true; } >> $tmpdir/naming-convention-counts

echo -n "firstname " >> $tmpdir/naming-convention-counts
{ grep --count --fixed-strings --line-regex --file="$DIR/firstnames" $tmpdir/human-emails.nodomain || true; } >> $tmpdir/naming-convention-counts

echo -n "flastname " >> $tmpdir/naming-convention-counts
{ sed 's/^.//' $tmpdir/human-emails.nodomain | grep --count --fixed-strings --line-regex --file="$DIR/lastnames" || true; } >> $tmpdir/naming-convention-counts

echo -n "lastname " >> $tmpdir/naming-convention-counts 
{ grep --count --fixed-strings --line-regex --file="$DIR/lastnames" $tmpdir/human-emails.nodomain || true; } >> $tmpdir/naming-convention-counts

# Pick the most likely naming convention
namingconvention=$(cat $tmpdir/naming-convention-counts | sort -rnk2 | head -n1 | awk '{print $1}')
echo "[-] Using \"$namingconvention\" naming convention"

echo "[-] Cleaning Up Names"
# Now we parse the names:
grep --perl-regexp --no-filename '^[A-Za-z][A-Za-z\ \- \.\,]+$' $tmpdir/harvested/* > $tmpdir/names

sed -r 's/([a-zA-Z]+\ [a-zA-Z]+)\ [A-Z]+$/\1/' $tmpdir/names |\
sed -r 's/^(Dr|Mr|Ms|Mrs|Lord|Mayor|Prof|Professor|Eng|phd)[\ \.\-\,]+//gi' | tr '[A-Z]' '[a-z]' > $tmpdir/names.cleaned
# Clean Names
# Strip Dr. Lord Prefixes
# Strip Suffixes

echo "[-] Parsing Names From Emails"

# Make CSV
cat $tmpdir/human-emails | sed -r 's/^([a-zA-Z]+)([\ \-\.\_]*)([a-zA-Z]*)(.+$)/\1,\3,\1\2\3\4/' > $tmpdir/humans.csv


echo "[-] Proccessing Naming Convention"

case $namingconvention in
    ("firstname.lastname")
        cat $tmpdir/names.cleaned | sed -r 's/(^[a-z]+)[\ ]*([a-z]+)/\1,\2,\1.\2/g' | sed 's/\ /./g' | sed "s/$/@$domain/" >> $tmpdir/humans.csv;;
    ("firstname-lastname")
        cat $tmpdir/names.cleaned | sed -r 's/(^[a-z]+)[\ ]*([a-z]+)/\1,\2,\1-\2/g' | sed 's/\ /-/g' | sed "s/$/@$domain/" >> $tmpdir/humans.csv;;
    ("firstname_lastname")
        cat $tmpdir/names.cleaned | sed -r 's/(^[a-z]+)[\ ]*([a-z]+)/\1,\2,\1_\2/g' | sed 's/\ /_/g' | sed "s/$/@$domain/" >> $tmpdir/humans.csv;;
    ("firstnamelastname")
        cat $tmpdir/names.cleaned | sed -r 's/(^[a-z]+)[\ ]*([a-z]+)/\1,\2,\1\2/g' | sed 's/\ //g' | sed "s/$/@$domain/" >> $tmpdir/humans.csv;;
    ("f.lastname")
        cat $tmpdir/names.cleaned | sed -r 's/(^[a-z])([a-z]+)\ ([a-z]+)/\1\2,\3,\1.\3/g' | sed 's/\ /./g' | sed "s/$/@$domain/" >> $tmpdir/humans.csv;;
    ("f-lastname") 
        cat $tmpdir/names.cleaned | sed -r 's/(^[a-z])([a-z]+)\ ([a-z]+)/\1\2,\3,\1-\3/g' | sed 's/\ /-/g' | sed "s/$/@$domain/" >> $tmpdir/humans.csv;;
    ("f_lastname") 
        cat $tmpdir/names.cleaned | sed -r 's/(^[a-z])([a-z]+)\ ([a-z]+)/\1\2,\3,\1_\3/g' | sed 's/\ /_/g' | sed "s/$/@$domain/" >> $tmpdir/humans.csv;;
    ("firstname")
        cat $tmpdir/names.cleaned | sed -r 's/(^[a-z]+)[\ ]*([a-z]+)/\1,\2,\1/g' | sed 's/\ //g' | sed "s/$/@$domain/" >> $tmpdir/humans.csv;;
    ("flastname") 
        cat $tmpdir/names.cleaned | sed -r 's/(^[a-z])([a-z]+)\ ([a-z]+)/\1\2,\3,\1\3/g' | sed 's/\ //g' | sed "s/$/@$domain/" >> $tmpdir/humans.csv;;
    ("lastname")
        cat $tmpdir/names.cleaned | sed -r 's/(^[a-z]+)[\ ]*([a-z]+)/\1,\2,\2/g' | sed 's/\ //g' | sed "s/$/@$domain/" >> $tmpdir/humans.csv;;
    (*)
        echo "[X] Something went VERY wrong" ;;
esac

# output

tac $tmpdir/humans.csv | awk -F"," '!_[$3]++' | sed -r 's/(.*),(.*),(.*)/\u\1,\u\2,\3\u/' > humans.$domain.csv
cat $tmpdir/shared-emails | sort | uniq > nothuman.$domain


# *molotov*
echo $tmpdir
