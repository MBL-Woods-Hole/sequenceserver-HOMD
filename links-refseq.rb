require 'json'

#
# This file location on the blast server
#      ~/.sequenceserver-bin/links-refseq.rb
# 
# It is read by the sequenceserver-refseq.conf  file on startup
#

#  $DB_TYPE is Important! It allows distintion between genome and refseq SS instances
$DB_TYPE = "refseq"
#

module SequenceServer
	module Links
	
        def hmt
            hmtMatchData = title.match /(HMT-\d{3})/
            hmt = hmtMatchData[1]
            url = "https://homd.org/taxa/tax_description?otid=" +hmt.split('-')[1]
            {
             :order => 2,
             :title => hmt,
             :url   => url,
             :icon  => 'fa-external-link'
            }
        end
   end
end
