#!/usr/bin/env ruby

require 'json'

#require "mysql2"    # if needed
=begin
    comment section  for the jblink we need the seq_id|accession  and stop start
    Need to extract the HMT and the pid
    NCBI
      fna   Works without SQL    
            # NCBI:fna:Nucleotide   id Pattern:  SEQF5022.1|CP022384.1  => accession
            # ncbi:fna:title: Veillonella sp. oral taxon 780 str. F0422 ctg1127947897872, whole genome shotgun sequence [HMT-780 Veillonella sp. HMT 780 F0422]
      
       ffn     
            # NCBI:ffn:Nucleotide   id   Pattern:  SEQF1668.1|lcl|JH470351.1_cds_EHM94433.1_1540  => seqid|lcl|accession_cds_protienID_cnt
            # ncbi:ffn:title: [protein=hypothetical protein] [protein_id=EHM94433.1] [location=complement(347988..348755)] [gbkey=CDS] [HMT-849 Actinomyces johnsonii F0330]
      faa -protein   
            # NCBI:faa:Protein      id   SEQF9159.1|SUN85700.1  => protein_id   (NEED SQL for acc and counts)
            ncbi:faa:title: hypothetical protein HMPREF0833_10479 [Streptococcus parasanguinis ATCC 15912] [HMT-721 Streptococcus parasanguinis ATCC 15912]
        
    PROKKA
      fna Works without SQL 
            # PROKKA:fna:Nucleotide id   Pattern:  SEQF5022.1|CP022384.1  => IS NCBI Acc!!
            prokka:fna:title:  HMT-329 Capnocytophaga leadbetteri H6253
            
      ffn      
            # PROKKA:ffn:Nuc        id   Pattern: SEQF3711.1_00199   => the whole is protein_id (NEED SQL for acc and counts)
            prokka:ffn:title:  16S ribosomal RNA [HMT-291 Prevotella denticola F0105]
            
      faa -protein      
            # PROKKA:faa:Protein id   SEQF2744.1_01439  => the whole is protein_id (NEED SQL for acc and counts)
            prokka:faa:title:  hypothetical protein [HMT-467 Peptostreptococcaceae G-1 Eubacterium sulci ATCC 35585]
        
=end        

	def hmt
	
	    hmtMatchData = retrieve_hmt title
	    hmt = hmtMatchData[1]
	    puts 'HHH'
	    puts hmt
	    url = "https://homd.org/taxa/tax_description?otid=" +hmt.split('-')[1]
	   {
		 :order => 3,
		 :title => hmt,
		 :url   => url,
		 :icon  => 'fa-external-link'
		}
	end
	
	def retrieve_seqid (id)
	   #SEQF7384.1|JACIDI010000035.1
	   # SEQF1872.1_00001
	   #if no index of '|' then use '_'
	   if id.index("|") == nil
	      seqid = id[0, id.index("_")]
	   else
	     seqid = id[0, id.index("|")]
	   end
	   
	   return seqid
	end
	
	def retrieve_hmt (title)
	   #FORMAT = /(HMT-\d{3})/
	   
	   return title.match /(HMT-\d{3})/
	end
	   
def get_stats (dbtype, id, title)        
    if dbtype == 'protein'
       if id.include? "_"
           anno = 'PROKKA'
           seqtype = "faa"
           pid = id
       elsif id.include? "|"
          anno = 'NCBI'
          seqtype = "faa"
          pid = id.split('|')[1]
       end
    else
        # only need to diff ffn and faa
        if id.include? "lcl"
           anno = 'NCBI'
           seqtype = 'ffn'
           #print "\n\n",seqtype,"\n"
           pidMatchDef =  title.match /\[protein_id\=(.*?)\]/
           pid = pidMatchDef[1]
           #print 'PID ', pid,"\n"
        elsif id.include? "_"
           anno = 'PROKKA'
           seqtype = 'ffn'
           pid = id
        end
    end
    return {:pid => pid, :anno => anno, :seqtype => seqtype}
end		
		
#$conn = Mysql2::Client.new(:host => $db_host, :username => $db_user, :password => $db_pass)
#$conn = Mysql2::Client.new(:default_file => '/home/ubuntu/.my.cnf_node')

$url_base = "https://homd.org/jbrowse/index.html?data=homd_V10.1/"
# mysqlconn.query(@db_query)
# less /var/lib/gems/2.7.0/gems/sequenceserver-2.0.0/lib/sequenceserver/links.rb
# expl pid from ncbi:   ESK64677.1
# expl pid from prokka: SEQF1595_00001

#   prokka: id === pid

		
system = 'prokka_faa'

if system == 'ncbi_ffn'
  id = "SEQF1668.1|lcl|JH470351.1_cds_EHM94433.1_1540"
  title = "[protein=hypothetical protein] [protein_id=EHM94433.1] [location=complement(347988..348755)] [gbkey=CDS] [HMT-849 Actinomyces johnsonii F0330]"
  dbtype = 'nucleotide'
elsif system == 'ncbi_fna'
  id = "SEQF5022.1|CP022384.1"
  title = "Veillonella sp. oral taxon 780 str. F0422 ctg1127947897872, whole genome shotgun sequence [HMT-780 Veillonella sp. HMT 780 F0422]"
  dbtype = 'nucleotide'
elsif system == 'ncbi_faa'
  id = "SEQF9159.1|SUN85700.1"
  title = "hypothetical protein HMPREF0833_10479 [Streptococcus parasanguinis ATCC 15912] [HMT-721 Streptococcus parasanguinis ATCC 15912]"
  dbtype = 'protein'

elsif system == 'prokka_ffn'
  id = "SEQF3711.1_00199 "
  title = "16S ribosomal RNA [HMT-291 Prevotella denticola F0105]"
  dbtype = 'nucleotide'
elsif system == 'prokka_fna'
  id = "SEQF5022.1|CP022384.1"
  title = "HMT-329 Capnocytophaga leadbetteri H6253"
  dbtype = 'nucleotide'
elsif system == 'prokka_faa'
  id = "SEQF2744.1_01439"
  title = "hypothetical protein [HMT-467 Peptostreptococcaceae G-1 Eubacterium sulci ATCC 35585]"
  dbtype = 'protein'
end

print 'id ',id,"\n"
print 'title ',title,"\n"

        
        seq_id = retrieve_seqid id
        
        puts seq_id
        stats = get_stats dbtype, id, title
        puts stats
        puts stats[:pid]
        if stats[:dbtype]   # fna are always nil - no sql needed
            q2 = "SELECT accession, gc, start, stop FROM `"+stats[:anno]+"`.`orf` where protein_id='"+stats[:pid]+"' limit 1"

		
		
	  

	
		

