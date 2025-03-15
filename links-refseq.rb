require 'json'
#########################################################################
# There are four links-* files in use
# links-jbrowse.rb        (used in ~/.sequenceserver-genome.conf)
# links-jbrowse-ncbi.rb   (used in ~/.sequenceserver-single_ncbi.conf)
# links-jbrowse-prokka.rb (used in ~/.sequenceserver-single_prokka.conf)
# links-refseq.rb         (used in ~/.sequenceserver-refseq.conf)
#########################################################################

#
# This file location on the blast server
#      ~/.sequenceserver-bin/links-refseq.rb
# 
# It is read by the sequenceserver-refseq.conf  file on startup
#

#  $DB_TYPE is Important! It allows distintion between genome and refseq SS instances

$HOMD_URL = "refseq_blast"
$DB_TYPE = "refseq"
$homd_url_base = "https://devel.homd.org/"
$ANNO = ""

module SequenceServer
	module Links
	
        def hmt
            hmtMatchData = title.match /(HMT-\d{3})/
            hmt = hmtMatchData[1]
            homdurl = $homd_url_base+"/taxa/tax_description?otid=" +hmt.split('-')[1]
            {
             :order => 2,
             :title => hmt,
             :url   => homdurl,
             :icon  => 'fa-external-link'
            }
        end
   end
end
