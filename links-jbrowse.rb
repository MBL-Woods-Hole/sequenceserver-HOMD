require 'json'

require "mysql2"    # if needed

#
# This file location on the blast server:
#      ~/.sequenceserver-bin/links-jbrowse.rb
# 
# It is read by the sequenceserver-jbrowse.conf  file on startup
#

# db_host is taken from .my.cnf_node file
#$db_host  = "localhost"
#$db_host  = "192.168.1.42"


#$conn = Mysql2::Client.new(:host => $db_host, :username => $db_user, :password => $db_pass)
$conn = Mysql2::Client.new(:default_file => '/home/ubuntu/.my.cnf_node')

$url_base = "https://homd.org/jbrowse/index.html?data=homd_V10.1/"
# mysqlconn.query(@db_query)
# less /var/lib/gems/2.7.0/gems/sequenceserver-2.0.0/lib/sequenceserver/links.rb
# expl pid from ncbi:   ESK64677.1
# expl pid from prokka: SEQF1595_00001

#   prokka: id === pid
def retrieve_seqid (idx)
           
   #if no index of '|' then use '_'
   if idx.index("|") == nil
      seqid = idx[0, id.index("_")]
   else
     seqid = idx[0, id.index("|")]
   end

end
	 
def get_stats (dbtypex, idx, titlex)        
    acc = nil
    if dbtypex == 'protein'
       if idx.include? "_"
           anno = 'PROKKA'
           seqtype = "faa"
           pid = idx
       elsif idx.include? "|"
          anno = 'NCBI'
          seqtype = "faa"
          pid = idx.split('|')[1]
       end
    else
        # only need to diff ffn and faa
        if idx.include? "lcl"
           puts "got lcl"
           anno = 'NCBI'
           seqtype = 'ffn'
           #print "\n\n",seqtype,"\n"
           pidMatchDef =  titlex.match /\[protein_id\=(.*?)\]/
           if pidMatchDef
              pid = pidMatchDef[1]
           else
              acc = idx.split('|')[2].split('_')[0] 
           end
           #print 'PID ', pid,"\n"
        elsif idx.include? "_"
           anno = 'PROKKA'
           seqtype = 'ffn'
           pid = idx
        end
    end
    return {:pid => pid, :anno => anno, :seqtype => seqtype, :acc => acc}
end		
    

module SequenceServer
	module Links
	
        def hmt
            hmtMatchData = title.match /(HMT-\d{3})/
            hmt = hmtMatchData[1]
            url = "https://homd.org/taxa/tax_description?otid=" +hmt.split('-')[1]
            {
             :order => 3,
             :title => hmt,
             :url   => url,
             :icon  => 'fa-external-link'
            }
        end
	
       
	def jbrowse		
		
		puts 'dbtype: '+dbtype
        puts 'id '+id  
        puts 'title '+title
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
        
        seq_id = retrieve_seqid id
        puts "seq_id "+seq_id
        stats = get_stats dbtype, id, title
        print stats,"\n"
       
       
		url = $url_base+seq_id
		
		if stats[:seqtype]   # fna are always nil - no sql needed
		    if stats[:seqtype] == 'ffn' && stats[:anno] == 'NCBI' && stats[:pid] == nil && stats[:acc]
			  a = stats[:acc]
			  first_hit_start = hsps.map(&:sstart).at(0)
			  first_hit_end = hsps.map(&:send).at(0)
			  gc = "0.37"  # default -- This is wrong!
			
			  url += "&loc=#{seq_id}|#{a}:#{first_hit_start-500}..#{first_hit_end+500}" 
			  url += "&highlight=#{seq_id}|#{a}:#{first_hit_start}..#{first_hit_end}"
			  url += "&tracks=" + ERB::Util.url_encode("DNA,prokka,prokka_ncrna,ncbi,ncbi_ncrna,GC Content (pivot at "+gc+"),GC Skew")
            else
                q2 = "SELECT accession, gc, start, stop FROM `"+stats[:anno]+"_meta`.`orf` where protein_id='"+stats[:pid]+"' limit 1"
            
                puts q2
                rs = $conn.query(q2)
            
                #puts rs.first['start'].to_i
                if rs
                    start = rs.first['start'].to_i
                    stop = rs.first['stop'].to_i
                    acc = rs.first['accession']
                    gc = rs.first['gc']
                    if stats[:anno] == 'PROKKA'
                       a = acc.split('_')[1]
                    else 
                       a = acc
                    end
                    hitfrom = start
                    hitto = stop
                    if start > stop
                        hitfrom = stop
                        hitto = start
                    end
                    locfrom = hitfrom-500
                    locto = hitto+500
                    if locfrom < 1
                        locfrom = 1
                    end
                    locfrom = locfrom.to_s
                    locto = locto.to_s
                    hitfrom = hitfrom.to_s
                    hitto   = hitto.to_s
                    #end
                    gc = (gc.to_f/100).to_s
            
            
                    url += "&loc=#{seq_id}|#{a}:#{locfrom}..#{locto}" 
                    url += "&highlight=#{seq_id}|#{a}:#{hitfrom}..#{hitto}"
                    
                  
                end 
               
			   url += "&tracks="+ ERB::Util.url_encode("DNA,prokka,prokka_ncrna,ncbi,ncbi_ncrna,GC Content (pivot at "+gc+"),GC Skew")
			end
		else
			#nucleotide fna only
			# SEQF5022.1|CP022384.1
			split_id = id.split('|')
			first_hit_start = hsps.map(&:sstart).at(0)
			first_hit_end = hsps.map(&:send).at(0)
			acc = split_id[1]
			gc = "0.37"  # default -- This is wrong!
			
			url += "&loc=#{seq_id}|#{acc}:#{first_hit_start-500}..#{first_hit_end+500}" 
			url += "&highlight=#{seq_id}|#{acc}:#{first_hit_start}..#{first_hit_end}"
			url += "&tracks=" + ERB::Util.url_encode("DNA,prokka,prokka_ncrna,ncbi,ncbi_ncrna,GC Content (pivot at "+gc+"),GC Skew")
		end
		puts url
		{
		 :order => 2,
		 :title => 'JBrowse',
		 :url   => url,
		 :icon  => 'fa-external-link'
		}
	  end
   end
end
