#!/usr/bin/env python

## SEE https://docs.dhtmlx.com/suite/tree__api__refs__tree.html // new version 7 must load from json file
# this script creates a list of json objects that allows the dhtmlx javascript library
# to parse and show a taxonomy tree (Written for HOMD)
##
import os, sys
import gzip
import json
#from json import JSONEncoder
import argparse
import csv,re
import hashlib
#from Bio import SeqIO

sys.path.append('/Users/avoorhis/programming/homd-scripts/')
sys.path.append('/home/ubuntu/homd-work')
try:
    from connect import MyConnection
except:
    MyConnection = None
    
import datetime
def md5(args):
    #ruby code
    #@id = Digest::MD5.hexdigest args.first

    # /mnt/xvdb/blastdb/genomes_prokka/V10.1/fna/SEQF9980.1.fna	87316a8f31a6d5e02661cf4328423d00
    # /mnt/xvdb/blastdb/genomes_prokka/V10.1/fna/SEQF9981.1.fna	264bd29c2416326e96dcef7612fddf76
    # /mnt/xvdb/blastdb/genomes_prokka/V10.1/fna/SEQF9982.1.fna	98cc64a5aad577eab8a4f02dcef1009b
    # what is python equivalent?
    
    # # initializing string
    str2hash = "/mnt/xvdb/blastdb/genomes_prokka/V10.1/fna/SEQF9980.1.fna"
    # # encoding GeeksforGeeks using encode()
    # # then sending to md5()
    result = hashlib.md5(str2hash.encode())

    # # printing the equivalent hexadecimal value.
    #print("The hexadecimal equivalent of hash is : ", end ="")
    #print(result.hexdigest())

def get_organism(g):
    q = "SELECT organism from `genomesV11.0` where genome_id='%s'"  % (g)
    #print(q)
    result = myconn.execute_fetch_one(q)
    if result:
        return result[0]
    else:
        return ''
    
def run(args):
    
    collector = {}
    ext_list = ['faa','ffn','fna']
    org = ''
    for (root,dirs,files) in os.walk(args.indir, topdown=True):
       
       for file in files:  
          
          if file.startswith('GCA'):
             #print(file)
             file_pts = file.split('.') # eg  SEQF1595.2.faa.psq
             ext = file_pts[2]
             genome = file_pts[0]+'.'+file_pts[1]
             if args.sql:
                 org = get_organism(genome)
                 org = org.replace('"','')
             
             #print('org',org)
             path = root+'/'+genome+'.'+ext
             #print(root,ext,genome,path)
             id = result = hashlib.md5(path.encode())
             collector[path] = {"g":genome,"e":ext,"i":id.hexdigest(),"o":org,"p":path}
    
    #fmt = args.outfmt.split(',')  # g,e,i
    fmt = ['g','e','i','o']
    for path in collector:
        #print(path)
        for letter in fmt:
            if letter == fmt[-1]:
               print(collector[path][letter], end =" ")
            else:
               print(collector[path][letter]+'\t', end =" ")
        print()
    
if __name__ == "__main__":

    usage = """
    USAGE:
        ./blast_get_SS_databaseIDs.py 
        
        Run like this:
           *** IMPORTANT the indirectory must be the same as in the database_dir from the SS.conf file
               INCLUDING the soft-link path
              currently: /mnt/xvdb/blastdb/genomes_prokka/V10.1/
              
          ./blast_get_SS_databaseIDs.py -i /mnt/xvdb/blastdb/genomes_ncbi/V11.0 > NCBI-IDs.csv
          ./blast_get_SS_databaseIDs.py -i /mnt/xvdb/blastdb/genomes_prokka/V11.0 > PROKKA-IDs.csv
          
          Try
          ./blast_get_SS_databaseIDs.py -host homd_dev -i /home/ubuntu/blast-db-genome/genomes_prokka_single/ffn >> PROKKA-IDsNEW.csv
          ./blast_get_SS_databaseIDs.py -host homd_dev -i /home/ubuntu/blast-db-genome/genomes_prokka_single/fna >> PROKKA-IDsNEW.csv
          ./blast_get_SS_databaseIDs.py -host homd_dev -i /home/ubuntu/blast-db-genome/genomes_prokka_single/faa >> PROKKA-IDsNEW.csv
          
          { 
            localhost: /Users/avoorhis/programming/blast_db/genomes_prokka/V11.0
                       /Users/avoorhis/programming/blast_db/genomes_ncbi/V11.0
                       
        }
        -i reqired infile: path to search for single blast databases
        
        Install both NCBI-IDs.csv and PROKKA-IDs.csv  into the root directories of the SS server (singles):
          
          ~/sequenceserver-single_ncbi
          ~/sequenceserver-single_prokka 
        
        -o output format default: g,e,i  (comma sep)
           
           e extention:  faa ffn or fna
           g genome name (SEQFXXXX.[1|2])
           i derived database id from MD5(path) same as w/ ruby code
           p  system path 
           
    """

    parser = argparse.ArgumentParser(description="." ,usage=usage)

    parser.add_argument("-i", "--indir",   required=True,  action="store",   dest = "indir", 
                                                    help=" ")
    parser.add_argument("-sql", "--sql",   required=False,  action="store_true",   dest = "sql", default=False,
                                                    help=" ")
    parser.add_argument("-host", "--host",
                        required = False, action = 'store', dest = "dbhost", default = 'localhost',
                        help = "choices=['homd',  'localhost']")
    
    parser.add_argument("-o", "--outformat",   required=False,  action="store",    dest = "outfmt", default='g,e,i',
                                                    help="verbose print()")
    args = parser.parse_args()
    
    #parser.print_help(usage)
                        
    if args.dbhost == 'homd_v4':
        #args.json_file_path = '/groups/vampsweb/vamps/nodejs/json'
        #args.TAX_DATABASE = 'HOMD_taxonomy'
        args.DATABASE = 'homd'
        dbhost= '192.168.1.46'   #
        args.prettyprint = False
        
    elif args.dbhost == 'homd_dev':
        args.DATABASE = 'homd'
        dbhost= '192.168.1.58' 
        
    elif args.dbhost == 'localhost':
        #args.json_file_path = '/Users/avoorhis/programming/homd-data/json'
        #args.TAX_DATABASE  = 'HOMD_taxonomy'
        args.DATABASE = 'homd'
        dbhost = 'localhost'
        #dbhost_old = 'localhost'
        
        
    else:
        sys.exit('dbhost - error')
    
    if args.sql:
        myconn = MyConnection(host=dbhost, db='homd',  read_default_file = "~/.my.cnf_node")
  
    run(args)
    md5(args)   
    
