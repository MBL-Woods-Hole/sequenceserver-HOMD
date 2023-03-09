# sequenceserver-HOMD

-To re-write the *.min.js files:
-npm run build

Samples:
http://spottedwingflybase.org/blast
https://lotus.au.dk/blast/
https://fungalgenomics.science.uu.nl/blast/
http://wheat-expression.com/
http://18.216.121.101/blast/
http://brcwebportal.cos.ncsu.edu:4567/
https://planmine.mpibpc.mpg.de/planmine/blast.do?db=uc_Smed_v2&seq=ttacgacgtgtcaatcaggtgttagagtattatttcgtgtcagtc%0D%0Atcggagctgattatcgaagagaatctaataaaaatttacgagattttagatgaaatgctt%0D%0Agataatggatttcccttgataacagagtgtaacattctcgaggaattgattcgtccaccg%0D%0Aaatatattgcgtgcgattgcagatcaaatgaatcgccaaaacactacaatcagttcagta%0D%0Acttcccattggtcaattaagtgttgtgccatggcgaaaagttggtgtgaaacatccgaac%0D%0Aaatgaagcctattttgatttctttgaaacaatagatgcaattcttgacaaaaatggaaat%0D%0Accgatttcatgtgatatcgttggatctgtcaaggctaacatacatttgtctggagttcct%0D%0Agatctaacaatgtcattttgcaatcccaaattaattgatgatgtttcattgcactcctgt%0D%0Agtcagatatttcaaatgggaaaaagatcgtattcttagtttcattcctcctgaaggtcaa%0D%0Attcgaattatgtacatattactgtcaatcaaacagtaacatcaatcttcctgtcggaatc%0D%0Aaaatctttatcaaaaatcgatgaaaacaggagctatcttgatctgacggtgatcggaaat%0D%0Aaaaattaacgcaaagaaatcagtggaaaatctctgtcttacgattcatttgcctaaaatt%0D%0Agcgtgcaatgttgttccgaaaacctgttcaattgggaaaacaaaatataacaccatagaa%0D%0Aaacactctcacttggaatattggtcgactggatcagtgtgtagttaccacactgaaaggc%0D%0Acctataattttgcacagtaactcgttcgttgatgagaccagtgtcatacaggtaatggcc%0D%0Agagttcaaaatcgaacagtattccgccagcggtacaaatgtcaacaaag

//Setup
https://medium.com/coding-design/setting-up-sequenceserver-edf9d992998c
https://support.sequenceserver.com/t/blast-against-between-two-sequence-database-sequence-path-is-variable-based-on-user-input-in-server/120/2

Push to 42
rsync -avzhe "ssh -i ~/.ssh/andy.pem" genome_database_ids.txt ubuntu@homd.info:genome_database_ids2.txt
the pull to local
rsync -avzhe "ssh -i ~/.ssh/andy.pem" ubuntu@homd.info:genome_database_ids2.txt genome_database_ids2.txt


# sequenceserver-HOMD

-To re-write the *.min.js files:
-npm run build

Samples:
http://spottedwingflybase.org/blast
https://lotus.au.dk/blast/

//Setup
https://medium.com/coding-design/setting-up-sequenceserver-edf9d992998c

====
HOMD Setup and administration:
SequenceServer is setup on 192.168.1.60 (the BLAST Server)
on the BLAST server I use systemd to stop/start the SS services.
See /etc/systemd/system/SS-refseq.services SS-genome.service SS-allncbi and SS-allprokka
====
The SS webpages are made visible on the web using nginx on the 
homd development webserver (currently 192.168.0.42)
See /etc/nginx.conf.d/homd.conf and ehomd.conf
Each has locations stanza's similar to:
*location /genome_blast_all_ncbi/ {
*    proxy_pass http://192.168.1.60:4570/;
*}
Which points the url to the port on the blast Server

====
There are three directories that matter in /home/ubuntu/ on the BLAST Server
./sequenceserver-HOMD  (uses conf files: ~/.sequenceserver-refseq.conf and ~/.sequenceserver-genome.conf)
./sequenceserver-allncbi (uses conf file ~/.sequenceserver-allncbi.conf)
./sequenceserver-allprokka (uses conf file ~/.sequenceserver-allprokka.conf)
These directories were downloaded as git repositories (NOT by gem install) from  https://github.com/wurmlab/sequenceserver
And I host them now on github/MBL-Woods-Hole
====
I edit them on my laptop and push them to github using different github branches to affect the code.
./sequenceserver-HOMD uses the 'main' git branch.
   and it is for the RefSeq and ALLGENOMES (both NCBI and PROKKA) databases.
   it separates the two using the SS config files (see systemd: SS_refseq and SS-genomes).

./sequenceserver-allncbi   uses the 'allgenomes' git branch.
./sequenceserver-allprokka also uses the 'allgenomes' git branch.
   
   
   
