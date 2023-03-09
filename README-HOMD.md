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
push to .42
rsync -avzhe "ssh -i ~/.ssh/andy.pem" genome_database_ids.txt ubuntu@homd.info:genome_database_ids2.txt
then pull to local
rsync -avzhe "ssh -i ~/.ssh/andy.pem" ubuntu@homd.info:genome_database_ids2.txt genome_database_ids2.txt

-To re-write the *.min.js files and run webpack (compiles sequenceserver-search.min.js and sequenceserver-report.min.js):
"npm run build" in the SS directory

For debugging each SS instance:
cd ~/sequenceserver-XXX
sudo systemcmd stop SS-XXX; 
bundle exec bin/sequenceserver -D -c ~/.sequenceserver-XXX.conf (you may need to 'npm run build' if edited recently)
```

---
## HOMD Setup and Administration:
### On 192.168.1.60 (the BLAST-Server)
SequenceServer is setup on 192.168.1.60 (the BLAST-Server) on which I use systemd to stop/start the SS services.

See /etc/systemd/system/SS-refseq.service, SS-genome.service SS-allncbi.service and SS-allprokka.service

There are three directories that matter in /home/ubuntu/ on the BLAST-Server:

```/home/ubuntu/sequenceserver-HOMD  (uses config files: ~/.sequenceserver-refseq.conf and ~/.sequenceserver-genome.conf)
/home/ubuntu/sequenceserver-allncbi (uses config file ~/.sequenceserver-allncbi.conf)
/home/ubuntu/sequenceserver-allprokka (uses config file ~/.sequenceserver-allprokka.conf)
```
These directories were installed as git repositories (NOT by 'gem install') from  https://github.com/wurmlab/sequenceserver

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

#### Single DB versions (-allncbi and -allprokka) descripion
The logic to show only one database (for the single db versions -allncbi and -allprokka) is located  
in the /lib/sequenceserver/routes.rb file:  ```get '/searchdata.json' do```  
Its important to note that SS must load ALL the databases on startup. (for homd: 3x8600 DBs)  
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
       location /genome_blast_all_ncbi/ {
         proxy_pass http://192.168.1.60:4570/;
       }
```
> Which points the url to the port on the BLAST-Server.
> The port number is here and in the SS.conf file on the SS Server.

### On GitHub MBL-Woods-Hole  
   URL: https://github.com/MBL-Woods-Hole/sequenceserver-HOMD
   
On my laptop I have just one directory ```~/sequenceserver/``` for editing and debugging and I switch git branches  
back and forth depending on which interface I want to edit (main or allgenomes). 


#### Use one git branch 'main' for the RefSeq and ALLGENOMES (both NCBI and PROKKA) databases.
```
(BLAST-Server)./sequenceserver-HOMD (RefSeq and ALLGenomes DB) uses the 'main' git branch. 
```
To differentiate between RefSeq and ALLGENOMES in the code I added a variable $DB_TYPE ("genome" or "refseq")  
which is introduced through the SS.conf file for each type (db_type-refseq.rb or db_type-genome.rb)   
located in the SS bin directory ```/home/ubuntu/.sequenceserver-bin/``` on the BLAST-Server


#### And another git branch 'allgenomes' for the individual selection genomes interface (ncbi and prokka).  
```
(BLAST-Server)./sequenceserver-allncbi (individual ncbi genomes) uses the 'allgenomes' git branch.  
(BLAST-Server)./sequenceserver-allprokka (individual prokka genomes) uses the 'allgenomes' git branch.
```
To differentiate between ncbi and prokka I added a variable $ANNO in the links-jbrowse files  
(links-jbrowse-prokka.rb and links-jbrowse-ncbi.rb) which is introduced through the SS.conf file for each type  
located in the SS bin directory ```/home/ubuntu/.sequenceserver-bin/``` on the BLAST-Server

For both $ANNO and $DB_TYPE it's purpose is to simple change the background color and titles for each interface.  
The actual databases loaded are in the .conf file themselves.

   
   
   
