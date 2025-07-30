require 'ox'
Ox.default_options = { skip: :skip_none }

require 'json'
require 'nokogiri'
require 'tilt/erb'
require 'sinatra/base'

require 'sequenceserver/job'
require 'sequenceserver/blast'
require 'sequenceserver/report'
require 'sequenceserver/database'
require 'sequenceserver/sequence'
require 'sequenceserver/makeblastdb'


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
      sequence_ids = params['sequence_ids'].split(',')
      job_id = params['job_id']
      job = Job.fetch(job_id)
      fpath_out = File.join(DOTDIR, job_id, 'custom_homd_taxonomy.csv')
      Xhash = Report.generate(job).to_json
      logger.info "XXX= #{Xhash}"
      #
      # First get GIDS and Taxonomy from MySQL DB
      #
      gids = Array.new
      gids_list = ''
      sequence_ids.each {|n|
          gid = 'GCA_'+n.split('_')[1].split('|')[0]
          #  prokka::protein sequence_ids look like this:   GCA_937930255.1_00575
          #  prokka:nucleotide sequence_ids look like this: GCA_937930255.1|pid
          #  ncbi::protein sequence_ids look like this:     GCA_026783725.1|MCY7224249.1
          #  ncbi::nucleotide sequence_ids look like this:  GCA_001815865.1|KV822194.1
          gids.push(gid)
      }
      tax_hash = {}
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
      q += " WHERE genome_id in ('"+gids.join("','")+"')"
      results = $conn.query(q)
      results.each do |row|
           #f.write("write your stuff here")
           hmt = 'HMT-'+row['otid'].to_s.rjust(3,'0')
           tax_hash[row['genome_id']] = {'hmt' => hmt,
                                         'domain' => row['domain'],
                                         'phylum' => row['phylum'],
                                         'class' => row['klass'],
                                         'order' => row['order'],
                                         'family' => row['family'],
                                         'genus' => row['genus'],
                                         'species' => row['species'],
                                         'subspecies' => row['subspecies'],
                                         'strain' => row['strain']
                                         }
           #f.puts "#{row['genome_id']}\t#{hmt}\t#{row['domain']}\t#{row['phylum']}\t#{row['klass']}\t#{row['order']}\t#{row['family']}\t#{row['genus']}\t#{row['species']}\t#{row['subspecies']}\t#{row['strain']}"
      end
        
      #
      #  Next Parse XML file and Gather BLAST info
      #
      fname_xml = File.join(DOTDIR, job_id, 'sequenceserver-xml_report.xml')
      xml_ir = File.read(fname_xml)
      # Parse the XML string
      hash = Ox.load(xml_ir, mode: :hash_no_attrs)
      #logger.info "hash['BlastOutput'] #{hash['BlastOutput']}"   #['BlastOutput_iterations']['Iteration']['Iteration_hits']['Hit'][0]
      #hit_ary = hash['BlastOutput']['BlastOutput_iterations']['Iteration']['Iteration_hits']['Hit']
      hit_ary = Xhash['queries']['hits']
      #hits_count = hit_ary.length()
      big_array = [] # an array of hashes
    #{gid,hit_def,hit#,hit_length,qcov,tscore,evalue,%ident, hsp#,hsp_score,hsp_evalue,hsp_ident,hsp_gaps,hps_strand,HMT,TAXONOMY}
      
      hit_ary.each do |hit_elem|
         
        # logger.info "Hit #{hit_elem}"
         #logger.info "Hit Def #{hit_elem['Hit_def']}"
         hit_title = hit_elem['title']
         hit_id = hit_elem['id']
         #hit_pts = hit_elem['Hit_def'].split()
         gid = 'GCA_'+hit_id.split('_')[1].split('|')[0]
         hit_num = hit_elem['number']
         hit_length = hit_elem['length']
         hit_qcov = hit_elem['qcovs']
         hit_tscore = hit_elem['total_score']
         
         
         # get gid from hit_def
         #if hit_elem['Hit_hsps']['Hsp'] is hash => then single
         
         #if hit_elem['Hit_hsps']['Hsp'] is array => then multiple
         
         hsps = hit_elem['Hsps']
         if hsps.kind_of?(Array)
            # multiple elements
            hit_evalue = hsps[0]['evalue']
            hit_ident = hsps[0]['identity']
            hsps.each do |hsp_elem|
               #logger.info "Hsp #{hsp_elem}"
               #logger.info "H Def #{hit_elem['Hit_def']}"
               hsp_num = hsp_elem['number']
               hsp_score = hsp_elem['score']
               hsp_evalue = hsp_elem['evalue']
               hsp_ident = hsp_elem['identity']
               hsp_gaps = hsp_elem['gaps']
               #hsp_strand = hsps['Hsp_strand']
               tmp_hash = {
               'gid'        => gid,
               'hit_def'    => hit_def,
               'hit_num'    => hit_num,
               'hit_length' => hit_length,
               'hit_qcov'   => hit_qcov,
               'hit_tscore' => hit_tscore,
               'hit_evalue' => hit_evalue,
               'hit_ident'  => hit_ident, 
               'hsp_num'    => hsp_num,
               'hsp_score'  => hsp_score,
               'hsp_evalue' => hsp_evalue,
               'hsp_ident'  => hsp_ident,
               'hsp_gaps'   => hsp_gaps,
               'hmt'       => tax_hash[gid]['hmt'],
               #'taxonomy'  => tax_hash[gid]['genus']+' '+tax_hash[gid]['species']+' '+tax_hash[gid]['strain']
               'domain'    => tax_hash[gid]['domain'],
               'phylum'    => tax_hash[gid]['phylum'],
               'class'     => tax_hash[gid]['class'],
               'order'     => tax_hash[gid]['order'],
               'family'    => tax_hash[gid]['family'],
               'genus'     => tax_hash[gid]['genus'],
               'species'   => tax_hash[gid]['species'],
               'subspecies' => tax_hash[gid]['subspecies'],
               'strain'    => tax_hash[gid]['strain']
               
               }
               
               
               big_array.push(tmp_hash)
            end
         else
            # hash and single element
            hit_evalue = hsps['evalue']
            hit_ident = hsps['identity']
            hsp_num = hsps['number']
            hsp_score = hsps['score']
            hsp_evalue = hsps['evalue']
            hsp_ident = hsps['identity']
            hsp_gaps = hsps['gaps']
            #hsp_strand = hsps['Hsp_strand']
            tmp_hash = {
               'gid'        => gid,
               'hit_def'    => hit_def,
               'hit_num'    => hit_num,
               'hit_length' => hit_length,
               'hit_qcov'   => hit_qcov,
               'hit_tscore' => hit_tscore,
               'hit_evalue' => hit_evalue,
               'hit_ident'  => hit_ident, 
               'hsp_num'    => hsp_num,
               'hsp_score'  => hsp_score,
               'hsp_evalue' => hsp_evalue,
               'hsp_ident'  => hsp_ident,
               'hsp_gaps'   => hsp_gaps,
               'hmt'       => tax_hash[gid]['hmt'],
               #'taxonomy'  => tax_hash[gid]['genus']+' '+tax_hash[gid]['species']+' '+tax_hash[gid]['strain']
               'domain'    => tax_hash[gid]['domain'],
               'phylum'    => tax_hash[gid]['phylum'],
               'class'     => tax_hash[gid]['class'],
               'order'     => tax_hash[gid]['order'],
               'family'    => tax_hash[gid]['family'],
               'genus'     => tax_hash[gid]['genus'],
               'species'   => tax_hash[gid]['species'],
               'subspecies' => tax_hash[gid]['subspecies'],
               'strain'    => tax_hash[gid]['strain']
            }
               
               
            big_array.push(tmp_hash)
         end
         
      end
     
     
      
      
      
      #
      #  Now we have taxonomy hash and BLAST array
      #
      
      File.open(fpath_out, 'w') do |f|
        #f.puts "Genome-ID\tHMT-ID\tDomain\tPhylum\tClass\tOrder\tFamily\tGenus\tSpecies\tSubspecies\tStrain"
        f.puts "Genome-ID\tHit_def\tHit_num\tHit_length\tHit_qcov\tHit_tscore\tHit_evalue\tHit_ident\tHsp_num\tHsp_score\tHsp_eval\tHsp_ident\tHsp_gaps\tHMT-ID\tDomain\tPhylum\tClass\tOrder\tFamily\tGenus\tSpecies\tSubspecies\tStrain"
        #gid,hit_def,hit#,hit_length,qcov,tscore,evalue,%ident, hsp#,hsp_score,hsp_evalue,hsp_ident,hsp_gaps,hps_strand,HMT,TAXONOMY}
        big_array.each do |el|
           f.puts "#{el['gid']}\t#{el['hit_def']}\t#{el['hit_num']}\t#{el['hit_length']}\t#{el['hit_qcov']}\t#{el['hit_tscore']}\t#{el['hit_evalue']}\t#{el['hit_ident']}\t#{el['hsp_num']}\t#{el['hsp_score']}\t#{el['hsp_evalue']}\t#{el['hsp_ident']}\t#{el['hsp_gaps']}\t#{el['hmt']}\t#{el['domain']}\t#{el['phylum']}\t#{el['class']}\t#{el['order']}\t#{el['family']}\t#{el['genus']}\t#{el['species']}\t#{el['subspecies']}\t#{el['strain']}"
        end
        #sequences = Sequence::Retriever.new(sequence_ids, database_ids, true)
        # Sequence::Retriever is in lib/sequenceserver/blast/sequence.rb
        logger.info "3-sequence_ids: #{gids}" 
        logger.info "3-q: #{q}" 
        #out = BLAST::Formatter.new(job, 'sql_custom')
        # send_file only sends file to browser that is already created
        
        logger.info "3-path: #{fpath_out}" 
        
      end
      
      send_file fpath_out, 
              type: 'text/csv', 
              filename: 'custom_homd_taxonomy.csv', 
              disposition: 'attachment' 
      #file.close # Close the file to ensure all data is written and flushed
      #file.unlink
      #send_file(SequenceServer.config[:bin],
      #          type:     'sql_custom',
      #          filename: 'test_mysql')
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
