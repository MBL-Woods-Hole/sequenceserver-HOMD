# sequenceserver-HOMD

###Examples around the web:
http://spottedwingflybase.org/blast
https://lotus.au.dk/blast/
https://fungalgenomics.science.uu.nl/blast/
http://wheat-expression.com/
http://18.216.121.101/blast/
http://brcwebportal.cos.ncsu.edu:4567/
https://planmine.mpibpc.mpg.de/planmine/blast.do?db=uc_Smed_v2&seq=ttacgacgtgtcaatcaggtgttagagtattatttcgtgtcagtc%0D%0Atcggagctgattatcgaagagaatctaataaaaatttacgagattttagatgaaatgctt%0D%0Agataatggatttcccttgataacagagtgtaacattctcgaggaattgattcgtccaccg%0D%0Aaatatattgcgtgcgattgcagatcaaatgaatcgccaaaacactacaatcagttcagta%0D%0Acttcccattggtcaattaagtgttgtgccatggcgaaaagttggtgtgaaacatccgaac%0D%0Aaatgaagcctattttgatttctttgaaacaatagatgcaattcttgacaaaaatggaaat%0D%0Accgatttcatgtgatatcgttggatctgtcaaggctaacatacatttgtctggagttcct%0D%0Agatctaacaatgtcattttgcaatcccaaattaattgatgatgtttcattgcactcctgt%0D%0Agtcagatatttcaaatgggaaaaagatcgtattcttagtttcattcctcctgaaggtcaa%0D%0Attcgaattatgtacatattactgtcaatcaaacagtaacatcaatcttcctgtcggaatc%0D%0Aaaatctttatcaaaaatcgatgaaaacaggagctatcttgatctgacggtgatcggaaat%0D%0Aaaaattaacgcaaagaaatcagtggaaaatctctgtcttacgattcatttgcctaaaatt%0D%0Agcgtgcaatgttgttccgaaaacctgttcaattgggaaaacaaaatataacaccatagaa%0D%0Aaacactctcacttggaatattggtcgactggatcagtgtgtagttaccacactgaaaggc%0D%0Acctataattttgcacagtaactcgttcgttgatgagaccagtgtcatacaggtaatggcc%0D%0Agagttcaaaatcgaacagtattccgccagcggtacaaatgtcaacaaag

###Setup
https://medium.com/coding-design/setting-up-sequenceserver-edf9d992998c
https://support.sequenceserver.com/t/blast-against-between-two-sequence-database-sequence-path-is-variable-based-on-user-input-in-server/120/2

###rsync push to *.42
rsync -avzhe "ssh -i ~/.ssh/andy.pem" genome_database_ids.txt ubuntu@homd.info:genome_database_ids2.txt
then pull to local
rsync -avzhe "ssh -i ~/.ssh/andy.pem" ubuntu@homd.info:genome_database_ids2.txt genome_database_ids2.txt

-To re-write the *.min.js files and run webpack (compiles sequenceserver-search.min.js and sequenceserver-report.min.js):
-npm run build

---
##HOMD Setup and Administration:
### on 192.168.1.60 (the BLAST-Server)
SequenceServer is setup on 192.168.1.60 (the BLAST-Server) on which I use systemd to stop/start the SS services.

See /etc/systemd/system/SS-refseq.services SS-genome.service SS-allncbi and SS-allprokka

There are three directories that matter in /home/ubuntu/ on the BLAST-Server

`/home/ubuntu/sequenceserver-HOMD`  (uses conf files: ~/.sequenceserver-refseq.conf and ~/.sequenceserver-genome.conf)
`/home/ubuntu/sequenceserver-allncbi` (uses conf file ~/.sequenceserver-allncbi.conf)
`/home/ubuntu/sequenceserver-allprokka` (uses conf file ~/.sequenceserver-allprokka.conf)

These directories were downloaded as git repositories (NOT by 'gem install') from  https://github.com/wurmlab/sequenceserver

The important parts from a systemd configuration file:
```
WorkingDirectory=/home/ubuntu/sequenceserver-HOMD
Type=simple
User=ubuntu
Environment=PATH=/home/ubuntu/.rbenv/shims:/home/ubuntu/.rbenv/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=RBENV_ROOT=/home/ubuntu/.rbenv/bin/rbenv
Environment=RBENV_VERSION=3.0.5
Environment=GEM_PATH=/home/ubuntu/.rbenv/versions/3.0.5/lib/ruby/gems/3.0.0:/home/ubuntu/.gem/ruby/3.0.0
Environment=BUNDLE_BIN_PATH=/home/ubuntu/.rbenv/versions/3.0.5/lib/ruby/gems/3.0.0/gems
Environment=BUNDLE_GEMFILE=/home/ubuntu/sequenceserver-HOMD/Gemfile
ExecStart=/usr/bin/bash -lc '/home/ubuntu/.rbenv/versions/3.0.5/bin/bundle exec /home/ubuntu/sequenceserver-HOMD/bin/sequenceserver -c /home/ubuntu/.sequenceserver-genome.conf'
```

### on 192.168.0.42 (the WebServer)
> The SS webpages are made visible on the web using nginx on the 
> homd development webserver (currently 192.168.0.42)
> See /etc/nginx.conf.d/homd.conf and ehomd.conf
> Each has locations stanza's similar to:
```
*location /genome_blast_all_ncbi/ {
*    proxy_pass http://192.168.1.60:4570/;
*}
```
> Which points the url to the port on the BLAST-Server

### on GitHub MBL-Woods-Hole  https://github.com/MBL-Woods-Hole/sequenceserver-HOMD
On my laptop I use one branch 'main' for the RefSeq and ALLGENOMES (both NCBI and PROKKA) databases.

And another branch 'allgenomes' for the individual selection genomes interface.
So on my laptop I switch back and forth depending on which interface I want to edit.

I edit them on my laptop and push them to github using different github branches to affect the code.

(BLAST-Server)./sequenceserver-HOMD uses the 'main' git branch.

(BLAST-Server)./sequenceserver-allncbi (individual ncbi genomes) uses the 'allgenomes' git branch.

(BLAST-Server)./sequenceserver-allprokka (individual prokka genomes) uses the 'allgenomes' git branch.

   
   
   
