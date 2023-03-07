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
#from Bio import SeqIO
sys.path.append('../homd-data/')
sys.path.append('../../homd-data/')
from connect import MyConnection,mysql
import datetime


def run(args):
    collector = {}
    collector['ncbi'] = {}
    collector['prokka'] = {}
    with open(args.infile) as handle:
       for line in handle:
           
           line = line.strip().split()
           #print(line)
           path_parts = line[0].split('/')
           #print(path_parts)
           ext = path_parts[6]
           gid = path_parts[7].rstrip('.fna').rstrip('.ffn').rstrip('.faa')
           id = line[1]
           #print('gid',gid)
           if not gid.startswith('SEQF'):
               continue
           q = "SELECT organism from genomes where seq_id='"+gid+"'"
           #print(q)
           result = myconn.execute_fetch_one(q)
           #print(result[0])
           if myconn.cursor.rowcount == 1:
               org = result[0]
           else:
               org = ''
           if path_parts[4] =='genomes_prokka':
               collector['prokka'][gid] = {'ext':ext,'id':id,'org':org} 
           else:
               collector['ncbi'][gid] = {'ext':ext,'id':id,'org':org} 
    
    #print(collector['ncbi']) 
    #print('len prokka',len(collector['prokka']))
    #print('len ncbi',len(collector['ncbi'])) 
    
    fp = open('Xgenome_blastdbIds_ncbi.csv','w')
    for gid in collector['ncbi']:
        h = collector['ncbi'][gid]
        fp.write(gid+"\t"+h['ext']+"\t"+h['id']+"\t"+h['org']+"\n")
    fp.close()
    fp = open('Xgenome_blastdbIds_prokka.csv','w')
    for gid in collector['prokka']:
        h = collector['prokka'][gid]
        fp.write(gid+"\t"+h['ext']+"\t"+h['id']+"\t"+h['org']+"\n")
    fp.close()
    
    
if __name__ == "__main__":

    usage = """
    USAGE:
        ./add_genomes_to_NCBI_dbV10_1.py 
        
        host and annotation will determine directory to search
        
        -host/--host [vamps]  default:localhost
       
        

    """

    parser = argparse.ArgumentParser(description="." ,usage=usage)

    parser.add_argument("-i", "--infile",   required=True,  action="store",   dest = "infile", default='none',
                                                    help=" ")
    
    parser.add_argument("-host", "--host",
                        required = False, action = 'store', dest = "dbhost", default = 'localhost',
                        help = "choices=['homd',  'localhost']")
    
    parser.add_argument("-o", "--outfile",   required=False,  action="store",    dest = "out", default='ncbi_contig_data.tsv',
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
        
    
