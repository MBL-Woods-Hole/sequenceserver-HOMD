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

-For single genome prokka and ncbi
Get path and database.id by opening SS on host *.60 pointing to prokka then ncbi
 (uncomment lines ~7 and ~38 in lib/sequenceserver/database.rb)
 
then edit the resulting file:  "genome_database_ids.txt" to be:
gid<TAB>ext<TAB>ID<TAB>Desired Title
And store it in these two (use py script: alter_genome_database_file.py
genome_blastdbIds_ncbiHASH.csv
genome_blastdbIds_prokkaHASH.csv

Push to 42
rsync -avzhe "ssh -i ~/.ssh/andy.pem" genome_database_ids.txt ubuntu@homd.info:genome_database_ids2.txt
the pull to local
rsync -avzhe "ssh -i ~/.ssh/andy.pem" ubuntu@homd.info:genome_database_ids2.txt genome_database_ids2.txt
