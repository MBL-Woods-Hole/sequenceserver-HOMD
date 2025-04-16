# sequenceserver-HOMD
FAQ
1. [How To change database name](#How-to-change-database-names)
2. [How To Pre-Select a certain database](#How-to-pre-select-a-certain-database-in-the-web-form)
3. [GitHub](#How-I-Use-GitHub)
4. [nginx setup](#NGINX-Setup)
5. [iFRAME in HOMD web app](#iFrame-in-Web-Application)
6. [routes.rb for SequenceServer Singles DBs](#routes.rb-file)
7. [How to differentiate between RefSeq, ALLGenome and Singles web page](#Load Extra Code)
8. [WebPack - What is it? and How to use it?](#WebPack)
9. [Testing the System](#How-I-Test-HOMD-SequenceServer)

### SequenceServer Examples around the web:
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
    push extra files to sequenceserver (currently 192.168.1.61 or 1.60) (this is NOT GitHub)
    
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

### Important for singles: PROKKA and NCBI
```
    Must regenerate NCBI-IDs.csv and PROKKA-IDs.csv
    by running 'blast_get_SS_databaseIDs.py' with correct infile for blast directory
    These files have format:
    genome_id<TAB>ext<TAB>directory hash<TAB>organism
    where ext is fna or ffn or faa
    and dirctory hash is created in the py script
    and is the same as the Directory.id in SequenceServer.
    These files are placed in the root directories of the singles nodejs app on the sequence server
    They should be recreated when new genomes are added.
```
---
## HOMD Setup and Administration:
### On localhost:
   I have TWO SequenceServer directories on localhost that I edit separately: 
   1. sequenceserver-HOMD
   2. sequenceserver-singles-HOMD
   
   
   

### On 192.168.1.60 and 1.61 (the BLAST-Server):
SequenceServer is setup on 192.168.1.60 (the BLAST-Server) on which I use systemd to stop/start the SS services.

See /etc/systemd/system/SS-refseq.service, SS-genome.service SS-single_ncbi.service and SS-single_prokka.service

There are three directories that matter in /home/ubuntu/ on the BLAST-Server:

```/home/ubuntu/sequenceserver-HOMD  (uses config files: ~/.sequenceserver-refseq.conf and ~/.sequenceserver-genome.conf -ALLGenomes*)
   /home/ubuntu/sequenceserver-single_ncbi (uses config file ~/.sequenceserver-single_ncbi.conf)
   /home/ubuntu/sequenceserver-single_prokka (uses config file ~/.sequenceserver-single_prokka.conf)
```
These directories were installed as git repositories (NOT by 'gem install') from  https://github.com/wurmlab/sequenceserver

The important parts from a systemd configuration file: SS-genome, SS-refseq, SS-single-ncbi and SS-single-prokka
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

### How to change database names
    Database names are created automatically by SequenceServer but can be changed
    by editing the .pal or .nal files

### How to pre-select a certain database in the web form?
   in public/js/databases.js about line 20
   if changed must run "npm run build" in the SS directory to rebuild the webpack
   
### The logic to select one genome's set of DBs from the roughly 9000 available:
    See file routes.rb in the sequenceserver-singles directories
    Also need proprly formated PROKKA-DB.csv and NCBI_DB.csv files in the sequenceserver-singles directories
   
### NGINX Setup
  This is file /etc/nginx.conf.d/homd.conf on the webserver : 192.168.0.48
  The BLAST Server () has nginx but it is not used
  
```
# https://www.vultr.com/docs/nginx-redirects-for-non-www-sub-domains-to-www/
server {

        server_name devel.homd.org www.devel.homd.org;
        location /jbrowse/ {
           proxy_pass http://192.168.1.51:8080$request_uri;
           include /etc/nginx/proxy_params;
        }

  # ALL RefSeq Databases
        location /refseq_blast/ {
            proxy_pass http://192.168.1.61:4568/;
            include /etc/nginx/proxy_params_sserver;
        }
  # ALL Genomes Databases
        location /genome_blast/ {
            proxy_pass http://192.168.1.61:4567/;
            include /etc/nginx/proxy_params_sserver;
        }

  # single genome::ncbi
        location /genome_blast_single_ncbi/ {
            proxy_pass http://192.168.1.61:4570/;
            include /etc/nginx/proxy_params_sserver;
        }
  # single genome::prokka
        location /genome_blast_single_prokka/ {
            proxy_pass http://192.168.1.61:4571/;
            include /etc/nginx/proxy_params_sserver;
        }

        location / {
            proxy_pass    http://127.0.0.1:3002/;
            proxy_http_version 1.1;
            proxy_buffering on;
            proxy_buffers 8 8k;
            proxy_max_temp_file_size 4096m;
            proxy_connect_timeout 600;
            proxy_read_timeout 600;
            proxy_send_timeout 600;
            send_timeout 600;
            reset_timedout_connection  on;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            #proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            #include /etc/nginx/proxy_params;
        }

    listen [::]:443 ssl; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/archive/homd.org/fullchain7.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/archive/homd.org/privkey7.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}
```

### iFrame in Web Application
    SS is loaded in iFrames in the nodejs web app.
    the code to load:
    
    ```<iframe id='iframe_id' src="https://devel.homd.org/refseq_blast/" title="HOMD BLAST Server"></iframe>
       <iframe id='iframe_id' src="https://devel.homd.org/genome_blast/" title="HOMD BLAST Server"></iframe>
       <iframe id='iframe_id' src="https://devel.homd.org/genome_blast_single_prokka/?gid=<%= gid %>" title="HOMD BLAST Server"></iframe>
    ```
    
    IMPORTANT => Always end URL with a forward slash!!! <= IMPORTANT
    
    The names 'refseq_blast', 'genome_blast' and 'genome_blast_single_prokka' are the same as in the NGINX.conf file
    directing to the correct port and the correct SS instance.
    
    For the single genome URL the $gid will be captured tin the routes.rb file and matched with the correct DB.
    
### Routes.rb File
    The routes.rb file is important for the single genome version.

### Load Extra Code
    To load variables into the code at server startup I have ruby files in the ~/.sequenceserver-bin
    directory. These files are read at startup if they are refernced from the .conf file
    I have JBrowse links, and database types (for color differentiation) in these files.
    Note the 'links-*' files in the base directory --> Edit then copy them to the ~/.sequenceserver-bin 
    directory
    
### How I Use GitHub
    'https://github.com/MBL-Woods-Hole/sequenceserver-HOMD'
    GitHup is a public code repository and versioning platform and I store MBL/HOMD code there.
    For SequenceServer I have two directories on my localhost laptop where I do my editing/developing.
    1. localhost Directory: ~/sequenceserver-HOMD (Pushes to Branch: main)
        On the BLAST Server pulls to
        a) ~/sequenceserver-HOMD which is used for:
            1) RefSeq BLAST
            2) Genome BLAST (All Databases)
    2. localhost Directory: ~/sequenceserver-singles-HOMD (Pushes to Branch: single_genome)
        On the BLAST Server pulls to:
        a) ~/sequenceserver-single_ncbi
        b) ~/sequenceserver-single_prokka
    
    So two localhost directories become four BLAST interfaces. This happens because I use systemd
    to start/stop the services. Each service uses a different .conf file (located in the ubuntu
    home directory of the sequenceserver:
    ```
    -rw-rw-r--  1 ubuntu ubuntu     971 Mar 14 19:24 .sequenceserver-genome.conf
    -rw-rw-r--  1 ubuntu ubuntu     651 Mar 13 15:03 .sequenceserver-refseq.conf
    -rw-rw-r--  1 ubuntu ubuntu    1131 Mar 14 14:16 .sequenceserver-single_ncbi.conf
    -rw-rw-r--  1 ubuntu ubuntu    1141 Mar 14 14:00 .sequenceserver-single_prokka.conf
    ```
### WebPack
    WebPack needs to be recreated on the server if you change any javascript code
    or any css (anything in the public directory). So edit,push changes, pull to server
    then run 'npm run build' in the base SS directory to recreate the *min.js files that it reads on startup

### How I Test HOMD SequenceServer
    Testing SS is complicated. Most simply I take these steps:
    1) stop the server:  'sudo systemctl stop SS-genome'
    2) Find/examine the long start command from the systemd service file for that service:
         'cat /etc/systemd/system/SS-genome.service'
         ExecStart=/usr/bin/bash -lc '/home/ubuntu/.rbenv/versions/3.0.5/bin/bundle exec /home/ubuntu/sequenceserver-HOMD/bin/sequenceserver -c /home/ubuntu/.sequenceserver-genome.conf'
    3) Restart the sevice from the command line using this command
       EXCEPT; add '-D' to the sequenceserver command like so:
       '/usr/bin/bash -lc '/home/ubuntu/.rbenv/versions/3.0.5/bin/bundle exec /home/ubuntu/sequenceserver-HOMD/bin/sequenceserver -D -c /home/ubuntu/.sequenceserver-genome.conf'
         
    4) Now you can see output to help you debug
    5) When done restart using systemd
    
    Caveats: Single genome DB loading takes a long time so to debug quicker I've used a pared down db directory.
    Add print or puts to your ruby code
    