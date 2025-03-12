# sequenceserver-HOMD

### Examples around the web:
```
http://spottedwingflybase.org/blast
https://lotus.au.dk/blast/
https://fungalgenomics.science.uu.nl/blast/
http://wheat-expression.com/
http://18.216.121.101/blast/
http://brcwebportal.cos.ncsu.edu:4567/
https://planmine.mpibpc.mpg.de/planmine/blast.do
 Setting up:
https://medium.com/coding-design/setting-up-sequenceserver-edf9d992998c
https://support.sequenceserver.com/t/blast-against-between-two-sequence-database-sequence-path-is-variable-based-on-user-input-in-server/120/2
```

### Helpful commands
```
push to sequenceserver (currently 192.168.1.61 or 1.60)


PUSH to server from localhost: BYPASS gateway
scp  -i ~/.ssh/andy.pem -o "ProxyCommand ssh -i ~/.ssh/andy.pem ubuntu@homd.info -W %h:%p" FILENAME ubuntu@192.168.1.61:
PULL FROM localhost 
scp  -i ~/.ssh/andy.pem -o "ProxyCommand ssh -i ~/.ssh/andy.pem ubuntu@homd.info -W %h:%p" ubuntu@192.168.1.102:FILENAME ./


-To re-write the *.min.js files and run webpack (compiles sequenceserver-search.min.js and sequenceserver-report.min.js):
"npm run build" in the SS directory

For debugging each SS instance:
cd ~/sequenceserver-XXX
sudo systemcmd stop SS-XXX; 
bundle exec bin/sequenceserver -D -c ~/.sequenceserver-XXX.conf (you may need to 'npm run build' if edited recently)
```

### Important for singles: prokka and ncbi
Must regenerate NCBI-IDs.csv and PROKKA-IDs.csv
by running 'blast_get_SS_databaseIDs.py' with correct infile for blast directory
These files have format:
genome_id<TAB>ext<TAB>directory hash
where ext is fna or ffn or faa
and dirctory hash is created in the py script
These files are placed in the root directories of the singles node app on the sequence server
They should be recreated when new genomes are added.
---
## HOMD Setup and Administration:
### On 192.168.1.60 (the BLAST-Server)
SequenceServer is setup on 192.168.1.60 (the BLAST-Server) on which I use systemd to stop/start the SS services.

See /etc/systemd/system/SS-refseq.service, SS-genome.service SS-single_ncbi.service and SS-single_prokka.service

There are three directories that matter in /home/ubuntu/ on the BLAST-Server:

```/home/ubuntu/sequenceserver-HOMD  (uses config files: ~/.sequenceserver-refseq.conf and ~/.sequenceserver-genome.conf)
/home/ubuntu/sequenceserver-single_ncbi (uses config file ~/.sequenceserver-single_ncbi.conf)
/home/ubuntu/sequenceserver-single_prokka (uses config file ~/.sequenceserver-single_prokka.conf)
```
These directories were installed as git repositories (NOT by 'gem install') from  https://github.com/wurmlab/sequenceserver

The important parts from a systemd configuration file:
```
WorkingDirectory=/home/ubuntu/sequenceserver-HOMD
StandardOutput=file:/home/ubuntu/logs/genome-blast_stdout.log
StandardError=file:/home/ubuntu/logs/genome-blast_stderr.log
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
#### Search ALL Databases  (Genomes or RefSeq)
    ***nginx conf files are on development and production servers
--genome  PORT:4567  confFile:  .sequenceserver-genome.conf
   systemd:  sudo systemctl restart SS-genome.service
--refseq  PORT:4568  confFile: .sequenceserver-refseq.conf
   systemd:  sudo systemctl restart SS-refseq.service
   
#### Single Genome DB versions (-allncbi and -allprokka) descripion
    ***nginx conf files are on development and production servers
    *** Takes a long tme to restart => reading db loactions
--single_prokka PORT:4571   confFile:  ~/.sequenceserver-single_prokka.conf 
    systemd:  sudo systemctl restart SS-single_prokka.service
--single_ncbi   PORT:4570   confFile:  ~/.sequenceserver-single_ncbi.conf
    systemd:  sudo systemctl restart SS-single_ncbi.service
The logic to show only one database (for the single db versions -single_ncbi and -single_prokka) is located  
in the /lib/sequenceserver/routes.rb file:  ```get '/searchdata.json' do```  about line 100.
Its important to note that SS must load ALL the databases on startup. (for homd thats: 3x8600 DBs)  
That is why it is split into prokka and ncbi versions: so that each only loads only half the number.  
To find the one database that is called for in the URL (ie ?gid=SEQF1595.2) I have recorded all the database IDs  
into files (one prokka and one ncbi) which is loaded at runtime and searched to display the (usually) three  
genome databases (faa, ffn and fna). The Database ID is used and derived from an MD5HASH() of the BLAST database full-path.  
If the path changes in the future we will need to re-create the ID files. There is a script in homd-scripts  
that will re-create the ID data files: ```blast_get_SS_databaseIDs.py```



### On 192.168.0.42 (the WebServer)
> The SS webpages are made visible on the web using nginx on the 
> HOMD development webserver (currently 192.168.0.42)
> See /etc/nginx.conf.d/homd.conf and ehomd.conf
> Each has locations stanza's similar to:
```
       location /genome_blast_single_ncbi/ {
         proxy_pass http://192.168.1.60:4570/;
       }
```
> Which points the url to the port on the BLAST-Server.
> The port number is here and in the SS.conf file on the SS Server.

### On GitHub MBL-Woods-Hole  
   URL: https://github.com/MBL-Woods-Hole/sequenceserver-HOMD
   
On my laptop I have just one directory ```~/sequenceserver/``` for editing and debugging and I switch git branches  
back and forth depending on which interface I want to edit (main or single_genomes). 


#### Use one git branch 'main' for the RefSeq and ALLGENOMES (both NCBI and PROKKA) databases.
```
(BLAST-Server)./sequenceserver-HOMD (RefSeq and ALLGenomes DB) uses the 'main' git branch. 
```
To differentiate between RefSeq and ALLGENOMES in the code I added a variable $DB_TYPE ("genome" or "refseq")  
which is introduced through the SS.conf file for each type (db_type-refseq.rb or db_type-genome.rb)   
located in the SS bin directory ```/home/ubuntu/.sequenceserver-bin/``` on the BLAST-Server


#### And another git branch 'single_genomes' for the individual selection genomes interface (ncbi and prokka).  
```
(BLAST-Server)./sequenceserver-single_ncbi (individual ncbi genomes) uses the 'single_genomes' git branch.  
(BLAST-Server)./sequenceserver-single_prokka (individual prokka genomes) uses the 'single_genomes' git branch.
```
To differentiate between ncbi and prokka I added a variable $ANNO in the links-jbrowse files  
(links-jbrowse-prokka.rb and links-jbrowse-ncbi.rb) which is introduced through the SS.conf file for each type  
located in the SS bin directory ```/home/ubuntu/.sequenceserver-bin/``` on the BLAST-Server

For both $ANNO and $DB_TYPE it's purpose is to simple change the background color and titles for each interface.  
The actual databases loaded are in the .conf file themselves.

   
   
   
