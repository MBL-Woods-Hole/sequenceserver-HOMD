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

from connect import MyConnection,mysql
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
    print("The hexadecimal equivalent of hash is : ", end ="")
    print(result.hexdigest())

def get_organism(g):
    q = "SELECT organism from genomes where seq_id='%s'"  % (g)
    print(q)
    result = myconn.execute_fetch_one(q)
    return result[0]
def run(args):
    collector = {}
    
    for (root,dirs,files) in os.walk(args.indir, topdown=True):
       for file in files:
          if file.startswith('SEQF'):
             
             file_pts = file.split('.') # eg  SEQF1595.2.faa.psq
             ext = file_pts[2]
             genome = file_pts[0]+'.'+file_pts[1]
             org = get_organism(genome)
             print('org',org)
             path = root+'/'+genome+'.'+ext
             #print(root,ext,genome,path)
             id = result = hashlib.md5(path.encode())
             collector[path] = {"g":genome,"e":ext,"i":id.hexdigest(),"p":path}
    
    fmt = args.outfmt.split(',')  # p,e,i,g
    for path in collector:
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
              currently: /mnt/xvdb/blastdb/genomes_prokka/V10.1/
              
          ./blast_get_SS_databaseIDs.py -i /mnt/xvdb/blastdb/genomes_ncbi/V10.1 > NCBI-IDs.csv
          ./blast_get_SS_databaseIDs.py -i /mnt/xvdb/blastdb/genomes_prokka/V10.1 > PROKKA-IDs.csv
          
        -i reqired infile: path to search for single blast databases
        
        Install both NCBI-IDs.csv and PROKKA-IDs.csv  into the root directories of the SS server:
          
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
    
    parser.add_argument("-host", "--host",
                        required = False, action = 'store', dest = "dbhost", default = 'localhost',
                        help = "choices=['homd',  'localhost']")
    
    parser.add_argument("-o", "--outformat",   required=False,  action="store",    dest = "outfmt", default='g,e,i',
                                                    help="verbose print()")
    args = parser.parse_args()
    
    #parser.print_help(usage)
                        
    if args.dbhost == 'homd':
        #args.json_file_path = '/groups/vampsweb/vamps/nodejs/json'
        #args.TAX_DATABASE = 'HOMD_taxonomy'
        args.DATABASE = 'homd'
        #dbhost_old = '192.168.1.51'
        dbhost= '192.168.1.42'   #TESTING is 1.42  PRODUCTION is 1.40
        args.prettyprint = False
        #args.ncbi_dir = '/mnt/efs/bioinfo/projects/homd_add_genomes_V10.1/GCA_V10.1_all'
        #args.prokka_dir = '/mnt/efs/bioinfo/projects/homd_add_genomes_V10.1/prokka_V10.1_all'
        
    elif args.dbhost == 'localhost':
        #args.json_file_path = '/Users/avoorhis/programming/homd-data/json'
        #args.TAX_DATABASE  = 'HOMD_taxonomy'
        args.DATABASE = 'homd'
        dbhost = 'localhost'
        #dbhost_old = 'localhost'
        
        
    else:
        sys.exit('dbhost - error')
    
    
    myconn = MyConnection(host=dbhost, db='homd',  read_default_file = "~/.my.cnf_node")
  
    run(args)
    md5(args)   
    
