require 'json'


#########################################################################
# OBSOLETE
# There are four links-* files in use
# links-jbrowse.rb        (used in ~/.sequenceserver-genome.conf)
# links-jbrowse-ncbi.rb   (used in ~/.sequenceserver-single_ncbi.conf)
# links-jbrowse-prokka.rb (used in ~/.sequenceserver-single_prokka.conf)
# links-refseq.rb         (used in ~/.sequenceserver-refseq.conf)
#########################################################################
$HOMD_URL = "genome_blast_single_ncbi"
$DB_TYPE = "genome"
$ANNO = "ncbi"
$GID = ""

$homd_url_base = "https://homd.org/"


module SequenceServer
    module Links
        def hmt
            hmtMatchData = title.match /(HMT-\d{3})/
            hmt = hmtMatchData[1]
            homdurl = $homd_url_base+"/taxa/tax_description?otid=" +hmt.split('-')[1]
            {
             :order => 3,
             :title => hmt,
             :url   => homdurl,
             :icon  => 'fa-external-link'
            }
        end
   end
end
