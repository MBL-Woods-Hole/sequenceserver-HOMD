require 'json'

require "mysql2"    # if needed

#########################################################################
# There are four links-* files in use
# links-jbrowse.rb        (used in ~/.sequenceserver-genome.conf)
# links-jbrowse-ncbi.rb   (used in ~/.sequenceserver-single_ncbi.conf)
# links-jbrowse-prokka.rb (used in ~/.sequenceserver-single_prokka.conf)
# links-refseq.rb         (used in ~/.sequenceserver-refseq.conf)
#########################################################################

$HOMD_URL = "genome_blast"
$DB_TYPE = "genome"
$db_host  = "localhost"
#$db_host  = "192.168.1.46"
$ANNO = ""

#$conn = Mysql2::Client.new(:host => $db_host, :username => $db_user, :password => $db_pass)
$conn = Mysql2::Client.new(:host => $db_host, :default_file => '/home/ubuntu/.my.cnf', :reconnect => true)

$homd_url_base = "https://homd.org/"
$jb_url_base = "https://www.homd.org/jbrowse/?data=homd_current/"
# mysqlconn.query(@db_query)
# less /var/lib/gems/2.7.0/gems/sequenceserver-2.0.0/lib/sequenceserver/links.rb
# expl pid from ncbi:   ESK64677.1
# expl pid from prokka: SEQF1595_00001

#   prokka: id === pid
def retrieve_seqid (idx)

   if idx.index("|") == nil
      pts = idx.split('_')
      seqid = pts[0]+'_'+pts[1]
   else
     seqid = idx[0, id.index("|")]
   end

end

def get_stats (dbtypex, idx, titlex)
    acc = nil
    if dbtypex == 'protein'
       # if idx.include? "_"
#            anno = 'PROKKA'
#            seqtype = "faa"
#            pid = idx
#        elsif idx.include? "|"
#           anno = 'NCBI'
#           seqtype = "faa"
#           pid = idx.split('|')[1]
#        end
       if idx.include? "|"
           anno = 'NCBI'
           seqtype = "faa"
           pid = idx.split('|')[1]
       else
          anno = 'PROKKA'
          seqtype = "faa"
          pid = idx
       end
       
    else   
        # only need to diff ffn and faa (above)
        
        if idx.include? "lcl"  # NCBI ffn only
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
        # elsif idx.include? "_"
#            anno = 'PROKKA'
#            seqtype = 'ffn'
#            pid = idx
        elsif idx.include? "|"
           anno = 'NCBI or PROKKA'  #NCBI::GCA_013267415.1|CP022384.1  PROKKA::GCA_013267415.1|CP022384.1
           seqtype = 'fna'
           pid = idx.split('|')[1]
        else   # PROKKA ffn  GCA_013267415.1_00199
           anno = 'PROKKA'
           seqtype = 'ffn'
           #pts = idx.split('_')
           pid = idx
        
        end
    end
    return {:pid => pid, :anno => anno, :seqtype => seqtype, :acc => acc}
end


module SequenceServer
    module Links

      def jbrowse

        puts 'dbtype: '+dbtype   # nucleotide or protein
        puts 'id '+id
        puts 'title '+title
        # get ANNO from database
        # get seqtype from database faa,fna,ffn
        
=begin
    comment section  for the jblink we need the seq_id|accession  and stop start
    Need to extract the HMT and the pid
    NCBI
      fna   Works without SQL
            # NCBI:fna:Nucleotide   id Pattern:  SEQF5022.1|CP022384.1  => accession
            # NEW  id = GCA_013267415.1|CP022384.1
            # ncbi:fna:title: Veillonella sp. oral taxon 780 str. F0422 ctg1127947897872, whole genome shotgun sequence [HMT-780 Veillonella sp. HMT 780 F0422]

       ffn (NEED SQL)
            # NCBI:ffn:Nucleotide   id   Pattern:  SEQF1668.1|lcl|JH470351.1_cds_EHM94433.1_1540  => seqid|lcl|accession_cds_protienID_cnt
            # NEW GCA_013267415.1|lcl|JH470351.1_cds_EHM94433.1_1540 
            # ncbi:ffn:title: [protein=hypothetical protein] [protein_id=EHM94433.1] [location=complement(347988..348755)] [gbkey=CDS] [HMT-849 Actinomyces johnsonii F0330]
      faa -protein  (NEED SQL)
            # NCBI:faa:Protein      id   SEQF9159.1|SUN85700.1  => protein_id   (NEED SQL for acc and counts)
            # NEW  GCA_013267415.1|SUN85700.1
            ncbi:faa:title: hypothetical protein HMPREF0833_10479 [Streptococcus parasanguinis ATCC 15912] [HMT-721 Streptococcus parasanguinis ATCC 15912]

    PROKKA
      fna Works without SQL
            # PROKKA:fna:Nucleotide id   Pattern:  SEQF5022.1|CP022384.1  => IS NCBI Acc!!
            # NEW  GCA_013267415.1|CP022384.1
            prokka:fna:title:  HMT-329 Capnocytophaga leadbetteri H6253

      ffn  (NEED SQL)
            # PROKKA:ffn:Nuc        id   Pattern: SEQF3711.1_00199   => the whole is protein_id (NEED SQL for acc and counts)
            # NEW  GCA_013267415.1_00199
            prokka:ffn:title:  16S ribosomal RNA [HMT-291 Prevotella denticola F0105]

      faa -protein  (NEED SQL)
            # PROKKA:faa:Protein id   SEQF2744.1_01439  => the whole is protein_id (NEED SQL for acc and counts)
            # NEW GCA_013267415.1_01439
            prokka:faa:title:  hypothetical protein [HMT-467 Peptostreptococcaceae G-1 Eubacterium sulci ATCC 35585]
      logic
         if protein
             NCBI faa   GCA_013267415.1|SUN85700.1  split on '|'
             PROKKA faa GCA_013267415.1_01439       split on '_' and combine  0,1
         else
             
=end

        seq_id = retrieve_seqid id
        puts "seq_id "+seq_id
        stats = get_stats dbtype, id, title
        print stats,"\n"

        gc = "0.37"  # default -- This is wrong! but it is a start
        url = $jb_url_base + seq_id

        if stats[:seqtype] != 'fna'  # 
            if stats[:seqtype] == 'ffn' && stats[:anno] == 'NCBI' && stats[:pid] == nil && stats[:acc]
              a = stats[:acc]
              first_hit_start = hsps.map(&:sstart).at(0)
              first_hit_end = hsps.map(&:send).at(0)

              url += "&loc=#{seq_id}|#{a}:#{first_hit_start-500}..#{first_hit_end+500}"
              url += "&highlight=#{seq_id}|#{a}:#{first_hit_start}..#{first_hit_end}"
              url += "&tracks=" + ERB::Util.url_encode("DNA,prokka,prokka_ncrna,ncbi,ncbi_ncrna,GC Content (pivot at "+gc+"),GC Skew")
            else
                q2 = "SELECT accession, gc, start, stop FROM `"+stats[:anno]+"_meta`.`orf` where protein_id='"+stats[:pid]+"' limit 1"

                puts q2
                rs = $conn.query(q2)

                if rs.count > 0
                    start = rs.first['start'].to_i
                    stop = rs.first['stop'].to_i
                    acc = rs.first['accession']
                    gc = rs.first['gc']
                    #if stats[:anno] == 'PROKKA'
                    #   a = acc.split('_')[1]
                    #else
                    a = acc
                    #end
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




## ORIGINAL
#        def jbrowse
#            qstart = hsps.map(&:qstart).min
#            sstart = hsps.map(&:sstart).min
#            qend = hsps.map(&:qend).max
#            send = hsps.map(&:send).max
#            split_id = id.split('_')
#            seq_id = split_id[0]
#            protein_id = split_id[1]
#            first_hit_start = hsps.map(&:sstart).at(0)
#            first_hit_end = hsps.map(&:send).at(0)
#            my_features = ERB::Util.url_encode(JSON.generate([{
#                :seq_id => accession,
#                :start => sstart,
#                :end => send,
#                :type => "match",
#                :subfeatures =>  hsps.map {
#                  |hsp| {
#                    :start => hsp.send < hsp.sstart ? hsp.send : hsp.sstart,
#                    :end => hsp.send < hsp.sstart ? hsp.sstart : hsp.send,
#                    :type => "match_part"
#                  }
#                }
#            }]))
#            my_track = ERB::Util.url_encode(JSON.generate([
#                 {
#                    :label => "BLAST",
#                    :key => "BLAST hits",
#                    :type => "JBrowse/View/Track/CanvasFeatures",
#                    :store => "url",
#                    :glyph => "JBrowse/View/FeatureGlyph/Segments"
#                 }
#            ]))
#            tracks = ERB::Util.url_encode("DNA,prokka,prokka_ncrna,ncbi,ncbi_ncrna,GC Content,GC Skew")
#            url = "https://homd.org/jbrowse/index.html" \
#                         "?data=homd%2F#{seq_id}" \
#                         "&tracks=#{tracks}" \
#                         "&loc=#{seq_id}|#{protein_id}:#{first_hit_start-500}..#{first_hit_start+500}" \
#                         "&highlight=#{seq_id}|#{seq_id}:#{first_hit_start}..#{first_hit_end}"
#
#            {
#              :order => 2,
#              :title => 'JBrowse',
#              :url   => url,
#              :icon  => 'fa-external-link'
#            }
#        end
   end
end
