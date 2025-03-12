require 'json'
require 'tilt/erb'
require 'sinatra/base'
#require 'rest-client'

require 'sequenceserver/job'
require 'sequenceserver/blast'
require 'sequenceserver/report'
require 'sequenceserver/database'
require 'sequenceserver/sequence'
require 'sequenceserver/makeblastdb'
require 'csv'

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
      #puts "in EDIT get '/searchdata.json' do"
      
      # if $DEV_HOST == 'AVhome'
#          path_prokka = '/Users/avoorhis/programming/blast-db-alt/'  #SEQF1595.fna*
#          path_ncbi = '/Users/avoorhis/programming/blast-db-alt_ncbi/'  #SEQF1595.fna*
#          #homdpath = '/mnt/efs/bioinfo/projects/homd_add_genomes_V10.1_all/add_blast/blastdb_ncbi/' #faa,ffn,fna
#       else
#          path_prokka = '/mnt/efs/bioinfo/projects/homd_add_genomes_V10.1_all/add_blast/blastdb_prokka/' #faa,ffn,fna
#          path_ncbi   = '/mnt/efs/bioinfo/projects/homd_add_genomes_V10.1_all/add_blast/blastdb_ncbi/' #faa,ffn,fna
#       end
      #puts 'dbs', dbs
      if !params[:gid].nil?
        $gid  = params[:gid]
        $SINGLE = true
        $DB_TO_SHOW = $gid
        if $DEV_HOST == 'AVhome'
          $ids_fn = './LOCAL-IDs.csv'
          puts "Reading LOCAL ID File #{$ids_fn}"
        elsif $ANNO == 'ncbi'
          #$ids_fn = './genome_blastdbIds_ncbiHASH.csv'
          $ids_fn = './NCBI-IDs.csv'
          puts "Reading NCBI ID File #{$ids_fn}"
        else
          #$ids_fn = './genome_blastdbIds_prokkaHASH.csv'
          $ids_fn = './PROKKA-IDs.csv'
          puts "gid is #{$gid}"
          puts "Reading PROKKA ID File #{$ids_fn}"
        end
        $file_data = CSV.parse(File.read($ids_fn), headers: false)
        #puts 'ANNO',$ANNO
   #      "database":[
#           {"name":"/Users/avoorhis/programming/blast-db-testing/HOMD_16S_rRNA_RefSeq_V15.22.fasta","title":"HOMD_16S_rRNA_RefSeq_V15.22.fasta","type":"nucleotide","nsequences":"1015","ncharacters":"1363402","updated_on":"Mar 4, 2023  11:00 AM","format":"5","categories":[],"id":"3ec27a6fd90c71054f68543e3d0ef624"},
#           {"name":"/Users/avoorhis/programming/blast-db-testing/genomes_ncbi/faa/ALL_genomes.faa","title":"ftp_ncbi/faa/ALL_genomes.faa","type":"protein","nsequences":"4665857","ncharacters":"1437439366","updated_on":"Mar 4, 2023  11:07 AM","format":"5","categories":["genomes_ncbi","faa"],"id":"629eef5dd9b21f895b01feb4a9e58de8"},
#           {"name":"/Users/avoorhis/programming/blast-db-testing/genomes_ncbi/fna/ALL_genomes.fna","title":"ftp_ncbi/fna/ALL_genomes.fna","type":"nucleotide","nsequences":"112918","ncharacters":"5541364068","updated_on":"Mar 4, 2023  12:14 PM","format":"5","categories":["genomes_ncbi","fna"],"id":"e17ac02845d0afc7c829031f011476d7"}
#         ]
        $ORGANISM = ''
        mydataids = []
        lookup = {}
        $file_data.each do |i|
           tmp = i[0].split("\t")
           #puts "X",tmp,tmp[0],$gid
           if tmp[0] == $gid
             #puts 'Match'
             # ["SEQF1595.2\tfaa\t45fd1a168c938b04c2a30ec725c0acdd"]
             # ["SEQF1595.2\tfaa\t45fd1a168c938b04c2a30ec725c0acdd\torganism"]
             tmp = i[0].split("\t")
             #puts 'tmp[2]',tmp[2]
             mydataids.push(tmp[2].strip())
             if tmp.length >3
               puts "Found #{tmp}"
               lookup[tmp[2].strip()] = tmp[3].strip()
             end
           end
        end
        newdbs =[]
        #puts 'mydataids',mydataids
        #mydataids.each do |i|
        #  puts "'"+i+"'"
        #end
        annoup = $ANNO.upcase
        #puts 'anno',$ANNO
        #puts 'annoup',annoup
        Database.each do |i|
          puts 'database inspect',i.inspect()
          puts 'i.id',"'"+i.id+"'"
          puts '1i.name',i.name
          if mydataids.include? i.id
            if lookup.has_key?(i.id)
               $ORGANISM = lookup[i.id]
            end
            #puts '2i.name',i.name
            #puts '$ORGANISM',$ORGANISM
            if i.name.include? 'faa'
              i.title = "#{annoup}::Annotated proteins (faa)"
            elsif i.name.include? 'ffn'
              i.title = "#{annoup}::Nucleotide Sequences of annotated proteins (ffn)"
            else
              i.title = "#{annoup}::Genomic DNA sequences/contigs (fna)"
            end
            i.title.concat("\n::#{$ORGANISM} (#{$gid})") 
            #i.organism = $ORGANISM
            puts "new DBs: i-2",i
            newdbs.push(i)
          end
          #puts 'newdbs',newdbs
          #<struct SequenceServer::Database 
          #name="/Users/avoorhis/programming/blast-db-testing/HOMD_16S_rRNA_RefSeq_V15.22.fasta", 
          #title="HOMD_16S_rRNA_RefSeq_V15.22.fasta", 
          #type="nucleotide", 
          #nsequences="1015", ncharacters="1363402", 
          #updated_on="Mar 4, 2023  11:00 AM", 
          #format="5", categories=[]>
        end
        puts "new DBs:",newdbs.length
        searchdata = {
            query: Database.retrieve(params[:query]),
            database: newdbs,
            options: SequenceServer.config[:options]
        }
        erb :search_single, layout: true
        
        if SequenceServer.config[:databases_widget] == 'tree'
            searchdata.update(tree: Database.tree)
        end

          # If a job_id is specified, update searchdata from job meta data (i.e.,
          # query, pre-selected databases, advanced options used). Query is only
          # updated if params[:query] is not specified.
        puts "Entering update_searchdata_from_job2"
        update_searchdata_from_job2(searchdata) if params[:job_id]
        
      else
        $SINGLE = false
        
        searchdata = {
            query: Database.retrieve(params[:query]),
            #database: Database.all,
            database: [],
            options: SequenceServer.config[:options]
        }
        
        if SequenceServer.config[:databases_widget] == 'tree'
            searchdata.update(tree: Database.tree)
        end

          # If a job_id is specified, update searchdata from job meta data (i.e.,
          # query, pre-selected databases, advanced options used). Query is only
          # updated if params[:query] is not specified.
        update_searchdata_from_job(searchdata) if params[:job_id]
        
      end

      
      
       #puts 'searchdata.to_json-after:'
       #puts searchdata.to_json
       
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
        #puts 'job.id'
        #puts job.id
        if $HOMD_URL == 'localhost' || $HOMD_URL == ''
           redirect to("/#{job.id}")
        else
           redirect to("/#{$HOMD_URL}/#{job.id}")
        end
                
        
      end
    end

    # Returns results for the given job id in JSON format.  Returns 202 with
    # an empty body if the job hasn't finished yet.
    get '/:jid.json' do |jid|
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
      sequences = Sequence::Retriever.new(sequence_ids, database_ids)
      sequences.to_json
    end

    post '/get_sequence' do
      sequence_ids = params['sequence_ids'].split(',')
      database_ids = params['database_ids'].split(',')
      sequences = Sequence::Retriever.new(sequence_ids, database_ids, true)
      send_file(sequences.file.path,
                type:     sequences.mime,
                filename: sequences.filename)
    end

    # Download BLAST report in various formats.
    get '/download/:jid.:type' do |jid, type|
      job = Job.fetch(jid)
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
    # Get the query sequences, selected databases, and advanced params used.
    # SINGLE
    def update_searchdata_from_job2(searchdata)
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