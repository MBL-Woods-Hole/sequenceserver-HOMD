
require 'json'
require 'tilt/erb'
require 'sinatra/base'

require 'sequenceserver/job'
require 'sequenceserver/blast'
require 'sequenceserver/report'
require 'sequenceserver/database'
require 'sequenceserver/sequence'
require 'sequenceserver/makeblastdb'

require 'time'
require 'write_xlsx'


module SequenceServer
  # Controller.
  class Routes < Sinatra::Base
    # See
    # http://www.sinatrarb.com/configuration.html
    extend Forwardable
    def_delegators SequenceServer, :config, :sys
    
    configure do
      # We don't need Rack::MethodOverride. Let's avoid the overhead.
      disable :method_override

      # Ensure exceptions never leak out of the app. Exceptions raised within
      # the app must be handled by the app.
      disable :show_exceptions, :raise_errors

      # Make it a policy to dump to 'rack.errors' any exception raised by the
      # app.
      enable :dump_errors

      # We don't want Sinatra do setup any loggers for us. We will use our own.
      set :logging, nil
    end

    # See
    # http://www.sinatrarb.com/intro.html#Mime%20Types
    configure do
      mime_type :fasta, 'text/fasta'
      mime_type :xml,   'text/xml'
      mime_type :tsv,   'text/tsv'
    end

    configure do
      # Public, and views directory will be found here.
      set :root, File.join(__dir__, '..', '..')

      # Allow :frame_options to be configured for Rack::Protection.
      #
      # By default _any website_ can embed SequenceServer in an iframe. To
      # change this, set `:frame_options` config to :deny, :sameorigin, or
      # 'ALLOW-FROM uri'.
      set :protection, lambda {
        frame_options = SequenceServer.config[:frame_options]
        frame_options && { frame_options: frame_options }
      }

      # Serve compressed responses.
      use Rack::Deflater
    end

    # For any request that hits the app,  log incoming params at debug level.
    before do
      #username = env[‘REMOTE_USER’]}
      logger.debug params
    end

    # Set JSON content type for JSON endpoints.
    before '*.json' do
      content_type 'application/json'
    end

    # Returns base HTML. Rest happens client-side: rendering the search form.
    get '/' do
      erb :search, layout: true
      
    end
    
    # Borrowed from makeblastdb.rb
    def multipart_database_name?(db_name)
      !(db_name.match(%r{.+/\S+\.\d{2,3}$}).nil?)
    end
    def get_categories(path)
      path
        .gsub(config[:database_dir], '') # remove database_dir from path
        .split('/')
        .reject(&:empty?)[0..-2] # the first entry might be '' if database_dir does not end with /
    end
    def blastdbcmd (line)
      cmd = "blastdbcmd -recursive -list #{line}" \
            ' -list_outfmt "%f	%t	%p	%n	%l	%d	%v"'
      out, err = sys(cmd, path: config[:bin])
      errpat = /BLAST Database error/
      fail BLAST_DATABASE_ERROR.new(cmd, err) if err.match(errpat)
      return out
    rescue CommandFailed => e
      fail BLAST_DATABASE_ERROR.new(cmd, e.stderr)
    end
    
    # Returns data that is used to render the search form client side. These
    # include available databases and user-defined search options.
    get '/searchdata.json' do
      
        searchdata = {
            query: Database.retrieve(params[:query]),
            database: Database.all,
            options: SequenceServer.config[:options]
        }
     

      if SequenceServer.config[:databases_widget] == 'tree'
        searchdata.update(tree: Database.tree)
      end

      # If a job_id is specified, update searchdata from job meta data (i.e.,
      # query, pre-selected databases, advanced options used). Query is only
      # updated if params[:query] is not specified.
      update_searchdata_from_job(searchdata) if params[:job_id]

      searchdata.to_json
    end

    # Queues a search job and redirects to `/:jid`.
    post '/' do
      # params:
        # {"databases"=>["e17ac02845d0afc7c829031f011476d7"], 
        # "sequence"=>"CTGGGCCGTGTCTCAGTCCCAATGTGGCCGTTTACCCTCTCAGGCCGGCTACGCATCATCGCCTTGGTGGGCCGTT", 
        # "advanced"=>"-task blastn -evalue 1e-5", 
        # "method"=>"blastn"
        # }}
      logger.info "IP:#{request.ip}: URL:#{$HOMD_URL} Method:"+params.fetch(:method)+" Sequence20:"+params.fetch(:sequence)[0,20]
      
      if params[:input_sequence]
        @input_sequence = params[:input_sequence]
        
        erb :search, layout: true
      else
        
        job = Job.create(params)
        #puts "Looking for HOMD_URL: #{$HOMD_URL}"
        if $HOMD_URL == 'localhost' || $HOMD_URL == ''
           redirect to("/#{job.id}")
        else
           redirect to("/#{$HOMD_URL}/#{job.id}")
        end
      end
    end

#     get '/single' do
#        puts 'AAV IN SINGLE routes.rb'
#        #erb :search_single, layout: true
#        redirect to("/")
#     end
    # Returns results for the given job id in JSON format.  Returns 202 with
    # an empty body if the job hasn't finished yet.
    get '/:jid.json' do |jid|
      # if jid.length < 20
#          # redirect to new search page of single genome databases
#          puts "AAV Found short jobid: #{jid}"
#          #redirect to("/")
#          erb :search, layout: true
#       end
      job = Job.fetch(jid)
      halt 202 unless job.done?
      Report.generate(job).to_json
    end

    # Returns base HTML. Rest happens client-side: polling for and rendering
    # the results.
    get '/:jid' do
      erb :report, layout: true
    end

    # @params sequence_ids: whitespace separated list of sequence ids to
    # retrieve
    # @params database_ids: whitespace separated list of database ids to
    # retrieve the sequence from.
    # @params download: whether to return raw response or initiate file
    # download
    #
    # Use whitespace to separate entries in sequence_ids (all other chars exist
    # in identifiers) and retreival_databases (we don't allow whitespace in a
    # database's name, so it's safe).
    get '/get_sequence/' do
      sequence_ids = params[:sequence_ids].split(',')
      database_ids = params[:database_ids].split(',')
      logger.info "1-sequence_ids: #{sequence_ids}"
      sequences = Sequence::Retriever.new(sequence_ids, database_ids)
      sequences.to_json
    end

    post '/get_sequence' do
      sequence_ids = params['sequence_ids'].split(',')
      database_ids = params['database_ids'].split(',')
      sequences = Sequence::Retriever.new(sequence_ids, database_ids, true)
      logger.info "2-sequence_ids: #{sequence_ids}" 
      send_file(sequences.file.path,
                type:     sequences.mime,
                filename: sequences.filename)
    end
        
    post '/get_sqlquery' do
        out_type = params['filetype'] # xlsx or csv
        sequence_ids = params['sequence_ids'].split(',')
        if sequence_ids[0].start_with?("HMT")
            db_type = "refseq"
        else
            db_type = "genome"
        end
        job_id = params['job_id']
        job = Job.fetch(job_id)
        
        #
        # First get GIDS and Taxonomy from MySQL DB
        #
        mysql_ids = Array.new
        gids_list = ''
        logger.info "xSEQ IDS= #{sequence_ids}"
        logger.info "DB TYPE #{db_type}"
        sequence_ids.each {|n|
          if db_type == 'refseq'
             # ID == HMT-389_16S000742
             otid = n.split('_')[0].split('-')[1]
             mysql_ids.push(otid)
          else
             gid = 'GCA_'+n.split('_')[1].split('|')[0]
              #  prokka::protein sequence_ids look like this:   GCA_937930255.1_00575
              #  prokka:nucleotide sequence_ids look like this: GCA_937930255.1|pid
              #  ncbi::protein sequence_ids look like this:     GCA_026783725.1|MCY7224249.1
              #  ncbi::nucleotide sequence_ids look like this:  GCA_001815865.1|KV822194.1
              mysql_ids.push(gid)
          end
        }
        
        logger.info "MYSQLIDS= #{mysql_ids}"
        tax_gid_hash = {}
        tax_hmt_hash = {}
        if db_type == 'refseq'
            q = "SELECT otid_prime.otid,domain,phylum,klass,`order`,family,genus,species,subspecies from homd.`otid_prime`"
            q += " JOIN homd.taxonomy using(taxonomy_id)"
            q += " JOIN homd.domain using(domain_id)"
            q += " JOIN homd.phylum using(phylum_id)"
            q += " JOIN homd.klass using(klass_id)"
            q += " JOIN homd.`order` using(order_id)"
            q += " JOIN homd.family using(family_id)"
            q += " JOIN homd.genus using(genus_id)"
            q += " JOIN homd.species using(species_id)"
            q += " JOIN homd.subspecies using(subspecies_id)"
            q += " WHERE otid in ('"+mysql_ids.join("','")+"')"
            
        else
            q = "SELECT genome_id,otid_prime.otid,domain,phylum,klass,`order`,family,genus,species,subspecies,strain from homd.`otid_prime`"
            q += " JOIN homd.taxonomy using(taxonomy_id)"
            q += " JOIN homd.domain using(domain_id)"
            q += " JOIN homd.phylum using(phylum_id)"
            q += " JOIN homd.klass using(klass_id)"
            q += " JOIN homd.`order` using(order_id)"
            q += " JOIN homd.family using(family_id)"
            q += " JOIN homd.genus using(genus_id)"
            q += " JOIN homd.species using(species_id)"
            q += " JOIN homd.subspecies using(subspecies_id)"
            q += " JOIN homd.`genomesV11.0` using(otid)"
            q += " WHERE genome_id in ('"+mysql_ids.join("','")+"')"
        end
        logger.info "SQL Query= #{q}"
        results = $conn.query(q)
        results.each do |row|
            #f.write("write your stuff here")
            hmt = 'HMT-'+row['otid'].to_s.rjust(3,'0')
            if db_type == 'refseq'
                tax_hmt_hash[hmt] = {
                    :hmt => hmt,
                    :domain => row['domain'],
                    :phylum => row['phylum'],
                    :class => row['klass'],
                    :order => row['order'],
                    :family => row['family'],
                    :genus => row['genus'],
                    :species => row['species'],
                    :subspecies => row['subspecies']
                }
            else
                tax_gid_hash[row['genome_id']] = {
                    :strain => row['strain'],
                    :hmt => hmt,
                    :domain => row['domain'],
                    :phylum => row['phylum'],
                    :class => row['klass'],
                    :order => row['order'],
                    :family => row['family'],
                    :genus => row['genus'],
                    :species => row['species'],
                    :subspecies => row['subspecies']
                }
            end
        end
        
        #
        #  Next Parse XML file and Gather BLAST info
        #
        #fname_xml = File.join(DOTDIR, job_id, 'sequenceserver-xml_report.xml')
        #xml_ir = File.read(fname_xml)
        Xhash = Report.generate(job).to_json
      
        
        #myhash = Xhash.to_hash()
        #logger.info "XXX= #{Xhash}"
        
        #
        #  Now we have taxonomy hash and BLAST big_array
        #
        newHash = eval(Xhash)
        headerA1 = "### DATABASE: #{newHash[:querydb][0][:title]}"
        headerA2 = "### PROGRAM: #{newHash[:program_version]}"
        query_ary = newHash[:queries]
        big_array = [] # an array of hashes
        
        query_ary.each do |query_elem|
            
            hit_ary = query_elem[:hits]
            hit_ary.each do |hit_elem|
         
                # logger.info "Hit #{hit_elem}"
                #logger.info "Hit Def #{hit_elem['Hit_def']}"
                
                hit_id = hit_elem[:id]
                
                if db_type == 'refseq'
                    # ID == HMT-389_16S000742
                    hmt = hit_id.split('_')[0]
                    gid = 'refseq'
                else
                    hmt = 'genome'
                    gid = 'GCA_'+hit_id.split('_')[1].split('|')[0]
                end
                #logger.info "GID FROM HIT-ID #{gid}"
                
                hsps = hit_elem[:hsps]
                hit_evalue = hsps[0][:evalue]
                hit_ident = hsps[0][:identity]
                #hit_ident = "#{hsps[0][:identity]}"+' / '+"#{hsps[0][:length]}"
                hit_ident_pct = (((hsps[0][:identity].to_f) / (hsps[0][:length].to_f) )*100).round(1).to_s 
                hsps.each do |hsp_elem|
                   #logger.info "Hsp #{hsp_elem}"
                   #logger.info "H Def #{hit_elem['Hit_def']}"
                   #if gid not in tax_hash:
                    tmp_hash1 = {
                           :gid        => gid,
                           :query_num    => query_elem[:number],
                           :hit_title    => hit_elem[:title],
                           :hit_num    => hit_elem[:number],
                           :hit_length => hit_elem[:length],
                           :hit_qcov   => hit_elem[:qcovs],
                           :hit_tscore => hit_elem[:total_score],
                           :hit_evalue => hit_evalue,
                           :hit_ident  => hit_ident, 
                           :hit_ipct   => hit_ident_pct,
                           :hsp_num    => hsp_elem[:number],
                           :hsp_score  => hsp_elem[:score],
                           :hsp_bitscore  => hsp_elem[:bit_score],
                           :hsp_evalue => hsp_elem[:evalue],
                           :hsp_ident  => hsp_elem[:identity],
                           :hsp_gaps   => hsp_elem[:gaps]
                    }
                    
                    #use_hash = tax_hmt_hash
                    if (!tax_hmt_hash.has_key?(hmt) && !tax_gid_hash.has_key?(gid))
                        logger.info "Key #{gid} does not exist in the tax hash."
                        tmp_hash2 = {
                           :hmt       =>  '',
                           :domain    =>  '',
                           :phylum    => '',
                           :class     =>  '',
                           :order     =>  '',
                           :family    =>  '',
                           :genus     =>  '',
                           :species   =>  '',
                           :subspecies =>  '',
                           :strain    =>  ''
                        }
                    
                    else
                        if db_type == 'refseq'
                            tmp_hash2 = {
                               
                               :hmt       => tax_hmt_hash[hmt][:hmt],
                               :domain    => tax_hmt_hash[hmt][:domain],
                               :phylum    => tax_hmt_hash[hmt][:phylum],
                               :class     => tax_hmt_hash[hmt][:class],
                               :order     => tax_hmt_hash[hmt][:order],
                               :family    => tax_hmt_hash[hmt][:family],
                               :genus     => tax_hmt_hash[hmt][:genus],
                               :species   => tax_hmt_hash[hmt][:species],
                               :subspecies => tax_hmt_hash[hmt][:subspecies],
                               :strain    => tax_hmt_hash[hmt][:strain]
                           }
                        else   
                            tmp_hash2 = {
                               
                               :hmt       => tax_gid_hash[gid][:hmt],
                               :domain    => tax_gid_hash[gid][:domain],
                               :phylum    => tax_gid_hash[gid][:phylum],
                               :class     => tax_gid_hash[gid][:class],
                               :order     => tax_gid_hash[gid][:order],
                               :family    => tax_gid_hash[gid][:family],
                               :genus     => tax_gid_hash[gid][:genus],
                               :species   => tax_gid_hash[gid][:species],
                               :subspecies => tax_gid_hash[gid][:subspecies],
                               :strain    => tax_gid_hash[gid][:strain]
                           }
                        end
                    end
                   tmp_hash = tmp_hash1.merge(tmp_hash2)
                   big_array.push(tmp_hash)
                end
            end
        end

      
        fpath_out = File.join(DOTDIR, job_id, "custom_homd_taxonomy.#{out_type}")
        if out_type == 'xlsx'
            # Create a new Excel workbook
            workbook = WriteXLSX.new(fpath_out)
            # Add a worksheet
            worksheet = workbook.add_worksheet
          
            worksheet.write('A1',headerA1)
            worksheet.write('A2',headerA2)
            worksheet.write(2,0,"Query_num")
            worksheet.write(2,1,"Genome-ID")
            worksheet.write(2,2,"HMT-ID")
            worksheet.write(2,3,"Hit_title")
            worksheet.write(2,4,"Hit_num")
            worksheet.write(2,5,"Hit_length")
            worksheet.write(2,6,"Hit_qcov")
            worksheet.write(2,7,"Hit_tscore")
            worksheet.write(2,8,"Hit_evalue")
            worksheet.write(2,9,"Hit_ident")
            worksheet.write(2,10,"Hit_Ident(%)")
            worksheet.write(2,11,"Hsp_num")
            worksheet.write(2,12,"Hsp_score")
            worksheet.write(2,13,"Hsp_bitscore")
            worksheet.write(2,14,"Hsp_eval")
            worksheet.write(2,15,"Hsp_ident")
            worksheet.write(2,16,"Hsp_gaps")
            worksheet.write(2,17,"HOMD-Domain")
            worksheet.write(2,18,"HOMD-Phylum")
            worksheet.write(2,19,"HOMD-Class")
            worksheet.write(2,20,"HOMD-Order")
            worksheet.write(2,21,"HOMD-Family")
            worksheet.write(2,22,"HOMD-Genus")
            worksheet.write(2,23,"HOMD-Species")
            worksheet.write(2,24,"HOMD-Subspecies")
            worksheet.write(2,25,"HOMD-Strain")
        
            row = 3
            big_array.each_with_index do |el,i|
                col = 0
                
                worksheet.write(row,col,el[:query_num])
                worksheet.write(row,col+1,el[:gid])
                worksheet.write(row,col+2,el[:hmt])
                worksheet.write(row,col+3,el[:hit_title])
                worksheet.write(row,col+4,el[:hit_num])
                worksheet.write(row,col+5,el[:hit_length])
                worksheet.write(row,col+6,el[:hit_qcov])
                worksheet.write(row,col+7,el[:hit_tscore])
                worksheet.write(row,col+8,el[:hit_evalue])
                worksheet.write(row,col+9,el[:hit_ident])
                worksheet.write(row,col+10,el[:hit_ipct])
                worksheet.write(row,col+11,el[:hsp_num])
                worksheet.write(row,col+12,el[:hsp_score])
                worksheet.write(row,col+13,el[:hsp_bitscore])
                worksheet.write(row,col+14,el[:hsp_evalue])
                worksheet.write(row,col+15,el[:hsp_ident])
                worksheet.write(row,col+16,el[:hsp_gaps])
                worksheet.write(row,col+17,el[:domain])
                worksheet.write(row,col+18,el[:phylum])
                worksheet.write(row,col+19,el[:class])
                worksheet.write(row,col+20,el[:order])
                worksheet.write(row,col+21,el[:family])
                worksheet.write(row,col+22,el[:genus])
                worksheet.write(row,col+23,el[:species])
                worksheet.write(row,col+24,el[:subspecies])
                worksheet.write(row,col+25,el[:strain])
                
                row += 1
            end
            
            workbook.close()
        else
            #f.puts "#{el[:query_num]}\t#{el[:gid]}\t#{el[:hmt]}\t#{el[:hit_title]}\t#{el[:hit_num]}\t#{el[:hit_length]}\t#{el[:hit_qcov]}\t#
                #{el[:hit_tscore]}\t#{el[:hit_evalue]}\t#{el[:hit_ident]}\t#{el[:hit_ipct]}\t#{el[:hsp_num]}\t#{el[:hsp_score]}\t#{el[:hsp_bitscore]}
                #\t#{el[:hsp_evalue]}\t#{el[:hsp_ident]}\t#{el[:hsp_gaps]}\t#{el[:domain]}\t#{el[:phylum]}\t#{el[:class]}\t#{el[:order]}\t#{el[:family]}\t#{el[:genus]}\t#{el[:species]}\t#{el[:subspecies]}\t#{el[:strain]}"
                
            File.open(fpath_out, 'w') do |f|
                #f.puts "Genome-ID\tHMT-ID\tDomain\tPhylum\tClass\tOrder\tFamily\tGenus\tSpecies\tSubspecies\tStrain"
                #f.puts "Genome-ID\tQuery_num\tHit_title\tHit_num\tHit_length\tHit_qcov\tHit_tscore\tHit_evalue\tHit_ident\tHit_Ident(%)\tHsp_num\tHsp_score\tHsp_bitscore\tHsp_eval\tHsp_ident\tHsp_gaps\tHMT-ID\tDomain\tPhylum\tClass\tOrder\tFamily\tGenus\tSpecies\tSubspecies\tStrain"
                f.puts headerA1
                f.puts headerA2
                f.write "Query_num\tGenome-ID\tHMT-ID\tHit_title\tHit_num\tHit_length\tHit_qcov\tHit_tscore\t"
                f.write "Hit_evalue\tHit_ident\tHit_Ident(%)\tHsp_num\tHsp_score\tHsp_bitscore\tHsp_eval\tHsp_ident\tHsp_gaps\t"
                f.write "HOMD-Domain\tHOMD-Phylum\tHOMD-Class\tHOMD-Order\tHOMD-Family\tHOMD-Genus\tHOMD-Species\tHOMD-Subspecies\tStrain\n"
                #gid,hit_def,hit#,hit_length,qcov,tscore,evalue,%ident, hsp#,hsp_score,hsp_evalue,hsp_ident,hsp_gaps,hps_strand,HMT,TAXONOMY}
                big_array.each do |el|
                   f.puts "#{el[:query_num]}\t#{el[:gid]}\t#{el[:hmt]}\t#{el[:hit_title]}\t#{el[:hit_num]}\t#{el[:hit_length]}\t#{el[:hit_qcov]}\t#{el[:hit_tscore]}\t#{el[:hit_evalue]}\t#{el[:hit_ident]}\t#{el[:hit_ipct]}\t#{el[:hsp_num]}\t#{el[:hsp_score]}\t#{el[:hsp_bitscore]}\t#{el[:hsp_evalue]}\t#{el[:hsp_ident]}\t#{el[:hsp_gaps]}\t#{el[:domain]}\t#{el[:phylum]}\t#{el[:class]}\t#{el[:order]}\t#{el[:family]}\t#{el[:genus]}\t#{el[:species]}\t#{el[:subspecies]}\t#{el[:strain]}"
                end
            end
        end
      
      
      current_time = Time.now
      filename_datetime = current_time.strftime("%Y%m%d_%H%M%S")
      if out_type == 'xlsx'
          mimetype = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      else
          mimetype = 'text/csv'
      end
      
      send_file fpath_out, 
              type: mimetype, 
              filename: "custom_homd_taxonomy_#{filename_datetime}.#{out_type}", 
              disposition: 'attachment' 
     
    end
    
    # Download BLAST report in various formats.
    get '/download/:jid.:type' do |jid, type|
      job = Job.fetch(jid)
      logger.info "3-job: #{job}" 
      out = BLAST::Formatter.new(job, type)
      send_file out.file, filename: out.filename, type: out.mime
    end

    # Catches any exception raised within the app and returns JSON
    # representation of the error:
    # {
    #    title: ...,     // plain text
    #    message: ...,   // plain or HTML text
    #    more_info: ..., // pre-formatted text
    # }
    #
    # If the error class defines `http_status` instance method, its return
    # value will be used to set HTTP status. HTTP status is set to 500
    # otherwise.
    #
    # If the error class defines `title` instance method, its return value
    # will be used as title. Otherwise name of the error class is used as
    # title.
    #
    # All error classes should define `message` instance method that provides
    # a short and simple explanation of the error.
    #
    # If the error class defines `more_info` instance method, its return value
    # will be used as more_info, otherwise `backtrace.join("\n")` is used as
    # more_info.
    error 400..500 do
      error = env['sinatra.error']

      # All errors will have a message.
      error_data = { message: error.message }

      # If error object has a title method, use that, or use name of the
      # error class as title.
      error_data[:title] = if error.respond_to? :title
                             error.title
                           else
                             error.class.name
                           end

      # If error object has a more_info method, use that. If the error does not
      # have more_info, use backtrace.join("\n") as more_info.
      if error.respond_to? :more_info
        error_data[:more_info] = error.more_info
      elsif error.respond_to? :backtrace
        error_data[:more_info] = error.backtrace.join("\n")
      end

      error_data.to_json
    end

    # Get the query sequences, selected databases, and advanced params used.
    def update_searchdata_from_job(searchdata)
      job = Job.fetch(params[:job_id])
      return if job.imported_xml_file

      # Only read job.qfile if we are not going to use Database.retrieve.
      searchdata[:query] = File.read(job.qfile) if !params[:query]

      # Which databases to pre-select.
      searchdata[:preSelectedDbs] = job.databases

      # job.advanced may be nil in case of old jobs. In this case, we do not
      # override searchdata so that default advanced parameters can be applied.
      # Note that, job.advanced will be an empty string if a user deletes the
      # default advanced parameters from the advanced params input field. In
      # this case, we do want the advanced params input field to be empty when
      # the user hits the back button. Thus we do not test for empty string.
      method = job.method.to_sym
      if job.advanced && job.advanced !=
           searchdata[:options][method][:default].join(' ')
        searchdata[:options] = searchdata[:options].deep_copy
        searchdata[:options][method]['last search'] = [job.advanced]
      end
    end
  end
end
