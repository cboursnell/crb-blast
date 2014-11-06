#!/usr/bin/env ruby

require 'bio'
require 'which'
require 'threach'

module CRB_Blast

  class Bio::FastaFormat
    def isNucl?
      Bio::Sequence.guess(self.seq, 0.9, 500) == Bio::Sequence::NA
    end

    def isProt?
      Bio::Sequence.guess(self.seq, 0.9, 500) == Bio::Sequence::AA
    end
  end

  class CRB_Blast

    include Which

    attr_accessor :query_name, :target_name, :reciprocals
    attr_accessor :missed
    attr_accessor :target_is_prot, :query_is_prot
    attr_accessor :query_results, :target_results, :working_dir

    def initialize query, target, output=nil
      raise IOError.new("File not found #{query}") if !File.exist?(query)
      raise IOError.new("File not found #{target}") if !File.exist?(target)
      @query = File.expand_path(query)
      @target = File.expand_path(target)
      if output.nil?
        #@working_dir = File.expand_path(File.dirname(query)) # no trailing /
        @working_dir = "."
      else
        @working_dir = File.expand_path(output)
        mkcmd = "mkdir #{@working_dir}"
        if !Dir.exist?(@working_dir)
          puts mkcmd
          mkdir = Cmd.new(mkcmd)
          mkdir.run
          if !mkdir.status.success?
            raise RuntimeError.new("Unable to create output directory")
          end
        end
      end
      @makedb_path = which('makeblastdb')
      raise 'makeblastdb was not in the PATH' if @makedb_path.empty?
      @blastn_path = which('blastn')
      raise 'blastn was not in the PATH' if @blastn_path.empty?
      @tblastn_path = which('tblastn')
      raise 'tblastn was not in the PATH' if @tblastn_path.empty?
      @blastx_path = which('blastx')
      raise 'blastx was not in the PATH' if @blastx_path.empty?
      @blastp_path = which('blastp')
      raise 'blastp was not in the PATH' if @blastp_path.empty?
      @makedb_path = @makedb_path.first
      @blastn_path = @blastn_path.first
      @tblastn_path = @tblastn_path.first
      @blastx_path = @blastx_path.first
      @blastp_path = @blastp_path.first
    end

    #
    # makes a blast database from the query and the target
    #
    def makedb
      # only scan the first few hundred entries
      n = 100
      # check if the query is a nucl or prot seq
      query_file = Bio::FastaFormat.open(@query)
      count_p=0
      count=0
      query_file.take(n).each do |entry|
        count_p += 1 if entry.isProt?
        count += 1
      end
      if count_p > count*0.9
        @query_is_prot = true
      else
        @query_is_prot = false
      end

      # check if the target is a nucl or prot seq
      target_file = Bio::FastaFormat.open(@target)
      count_p=0
      count=0
      target_file.take(n).each do |entry|
        count_p += 1 if entry.isProt?
        count += 1
      end
      if count_p > count*0.9
        @target_is_prot = true
      else
        @target_is_prot = false
      end
      # construct the output database names
      @query_name = File.basename(@query).split('.')[0..-2].join('.')
      @target_name = File.basename(@target).split('.')[0..-2].join('.')

      # check if the databases already exist in @working_dir
      make_query_db_cmd = "#{@makedb_path} -in #{@query}"
      make_query_db_cmd << " -dbtype nucl " if !@query_is_prot
      make_query_db_cmd << " -dbtype prot " if @query_is_prot
      make_query_db_cmd << " -title #{query_name} "
      make_query_db_cmd << " -out #{@working_dir}/#{query_name}"
      db_query = "#{query_name}.nsq" if !@query_is_prot
      db_query = "#{query_name}.psq" if @query_is_prot
      if !File.exists?("#{@working_dir}/#{db_query}")
        make_db = Cmd.new(make_query_db_cmd)
        make_db.run
        if !make_db.status.success?
          msg = "BLAST Error creating database:\n" +
                make_db.stdout + "\n" +
                make_db.stderr
          raise RuntimeError.new(msg)
        end
      end

      make_target_db_cmd = "#{@makedb_path} -in #{@target}"
      make_target_db_cmd << " -dbtype nucl " if !@target_is_prot
      make_target_db_cmd << " -dbtype prot " if @target_is_prot
      make_target_db_cmd << " -title #{target_name} "
      make_target_db_cmd << " -out #{@working_dir}/#{target_name}"

      db_target = "#{target_name}.nsq" if !@target_is_prot
      db_target = "#{target_name}.psq" if @target_is_prot
      if !File.exists?("#{@working_dir}/#{db_target}")
        make_db = Cmd.new(make_target_db_cmd)
        make_db.run
        if !make_db.status.success?
          raise RuntimeError.new("BLAST Error creating database")
        end
      end
      @databases = true
      [@query_name, @target_name]
    end

    # Construct BLAST output file name and run blast with multiple chunks or
    # with multiple threads
    #
    # @param [Float] evalue The evalue cutoff to use with BLAST
    # @param [Integer] threads The number of threads to run
    # @param [Boolean] split If the fasta files should be split into chunks
    def run_blast(evalue, threads, split)
      if @databases
        @output1 = "#{@working_dir}/#{query_name}_into_#{target_name}.1.blast"
        @output2 = "#{@working_dir}/#{target_name}_into_#{query_name}.2.blast"
        if @query_is_prot
          if @target_is_prot
            bin1 = "#{@blastp_path} "
            bin2 = "#{@blastp_path} "
          else
            bin1 = "#{@tblastn_path} "
            bin2 = "#{@blastx_path} "
          end
        else
          if @target_is_prot
            bin1 = "#{@blastx_path} "
            bin2 = "#{@tblastn_path} "
          else
            bin1 = "#{@blastn_path} "
            bin2 = "#{@blastn_path} "
          end
        end
        if split and threads > 1
          run_blast_with_splitting evalue, threads, bin1, bin2
        else
          run_blast_with_threads evalue, threads, bin1, bin2
        end
        return true
      else
        return false
      end
    end

    # Run BLAST using its own multithreading
    #
    # @param [Float] evalue The evalue cutoff to use with BLAST
    # @param [Integer] threads The number of threads to run
    # @param [String] bin1
    # @param [String] bin2
    def run_blast_with_threads evalue, threads, bin1, bin2
      # puts "running blast with #{threads} threads"
      cmd1 = "#{bin1} -query #{@query} -db #{@working_dir}/#{@target_name} "
      cmd1 << " -out #{@output1} -evalue #{evalue} "
      cmd1 << " -outfmt \"6 std qlen slen\" "
      cmd1 << " -max_target_seqs 50 "
      cmd1 << " -num_threads #{threads}"

      cmd2 = "#{bin2} -query #{@target} -db #{@working_dir}/#{@query_name} "
      cmd2 << " -out #{@output2} -evalue #{evalue} "
      cmd2 << " -outfmt \"6 std qlen slen\" "
      cmd2 << " -max_target_seqs 50 "
      cmd2 << " -num_threads #{threads}"
      if !File.exist?("#{@output1}")
        blast1 = Cmd.new(cmd1)
        blast1.run
        if !blast1.status.success?
          raise RuntimeError.new("BLAST Error:\n#{blast1.stderr}")
        end
      end

      if !File.exist?("#{@output2}")
        blast2 = Cmd.new(cmd2)
        blast2.run
        if !blast2.status.success?
          raise RuntimeError.new("BLAST Error:\n#{blast2.stderr}")
        end
      end
    end

    # Run BLAST by splitting the input into multiple chunks and using 1 thread
    # for each chunk
    #
    # @param [Float] evalue The evalue cutoff to use with BLAST
    # @param [Integer] threads The number of threads to run
    # @param [String] bin1
    # @param [String] bin2
    def run_blast_with_splitting evalue, threads, bin1, bin2
      # puts "running blast by splitting input into #{threads} pieces"
      if !File.exist?(@output1)
        blasts=[]
        files = split_input(@query, threads)
        threads = [threads, files.length].min
        files.threach(threads) do |thread|
          cmd1 = "#{bin1} -query #{thread} -db #{@working_dir}/#{@target_name} "
          cmd1 << " -out #{thread}.blast -evalue #{evalue} "
          cmd1 << " -outfmt \"6 std qlen slen\" "
          cmd1 << " -max_target_seqs 50 "
          cmd1 << " -num_threads 1"
          if !File.exists?("#{thread}.blast")
            blast1 = Cmd.new(cmd1)
            blast1.run
            if !blast1.status.success?
              raise RuntimeError.new("BLAST Error:\n#{blast1.stderr}")
            end
          end
          blasts << "#{thread}.blast"
        end
        cat_cmd = "cat "
        cat_cmd << blasts.join(" ")
        cat_cmd << " > #{@output1}"
        catting = Cmd.new(cat_cmd)
        catting.run
        if !catting.status.success?
          raise RuntimeError.new("Problem catting files:\n#{catting.stderr}")
        end
        files.each do |file|
          File.delete(file) if File.exist?(file)
        end
        blasts.each do |b|
          File.delete(b) # delete intermediate blast output files
        end
      end

      if !File.exist?(@output2)
        blasts=[]
        files = split_input(@target, threads)
        threads = [threads, files.length].min
        files.threach(threads) do |thread|
          cmd2 = "#{bin2} -query #{thread} -db #{@working_dir}/#{@query_name} "
          cmd2 << " -out #{thread}.blast -evalue #{evalue} "
          cmd2 << " -outfmt \"6 std qlen slen\" "
          cmd2 << " -max_target_seqs 50 "
          cmd2 << " -num_threads 1"
          if !File.exists?("#{thread}.blast")
            blast2 = Cmd.new(cmd2)
            blast2.run
            if !blast2.status.success?
              raise RuntimeError.new("BLAST Error:\n#{blast2.stderr}")
            end
          end
          blasts << "#{thread}.blast"
        end
        cat_cmd = "cat "
        cat_cmd << blasts.join(" ")
        cat_cmd << " > #{@output2}"
        catting = Cmd.new(cat_cmd)
        catting.run
        if !catting.status.success?
          raise RuntimeError.new("Problem catting files:\n#{catting.stderr}")
        end
        files.each do |file|
          File.delete(file) if File.exist?(file)
        end
        blasts.each do |b|
          File.delete(b) # delete intermediate blast output files
        end
      end

    end

    # Split a fasta file in pieces
    #
    # @param [String] filename
    # @param [Integer] pieces
    def split_input filename, pieces
      input = {}
      name = nil
      seq=""
      sequences=0
      File.open(filename).each_line do |line|
        if line =~ /^>(.*)$/
          sequences+=1
          if name
            input[name]=seq
            seq=""
          end
          name = $1
        else
          seq << line.chomp
        end
      end
      input[name]=seq
      # construct list of output file handles
      outputs=[]
      output_files=[]
      pieces = [pieces, sequences].min
      pieces.times do |n|
        outfile = File.basename("#{filename}_chunk_#{n}.fasta")
        outfile = "#{@working_dir}/#{outfile}"
        outputs[n] = File.open("#{outfile}", "w")
        output_files[n] = "#{outfile}"
      end
      # write sequences
      count=0
      input.each_pair do |name, seq|
        outputs[count].write(">#{name}\n")
        outputs[count].write("#{seq}\n")
        count += 1
        count %= pieces
      end
      outputs.each do |out|
        out.close
      end
      output_files
    end

    # Load the two BLAST output files and store the hits in a hash
    #
    def load_outputs
      if File.exist?("#{@working_dir}/reciprocal_hits.txt")
        # puts "reciprocal output already exists"
      else
        @query_results = Hash.new
        @target_results = Hash.new
        q_count=0
        t_count=0
        if !File.exists?("#{@output1}")
          raise RuntimeError.new("can't find #{@output1}")
        end
        if !File.exists?("#{@output2}")
          raise RuntimeError.new("can't find #{@output2}")
        end
        if File.exists?("#{@output1}") and File.exists?("#{@output2}")
          File.open("#{@output1}").each_line do |line|
            cols = line.chomp.split("\t")
            hit = Hit.new(cols)
            @query_results[hit.query] = [] if !@query_results.has_key?(hit.query)
            @query_results[hit.query] << hit
            q_count += 1
          end
          File.open("#{@output2}").each_line do |line|
            cols = line.chomp.split("\t")
            hit = Hit.new(cols)
            @target_results[hit.query] = [] if !@target_results.has_key?(hit.query)
            @target_results[hit.query] << hit
            t_count += 1
          end
        else
          raise "need to run blast first"
        end
      end
      [q_count, t_count]
    end

    # fills @reciprocals with strict reciprocal hits from the blast results
    def find_reciprocals
      if File.exist?("#{@working_dir}/reciprocal_hits.txt")
        # puts "reciprocal output already exists"
      else
        @reciprocals = Hash.new
        @missed = Hash.new
        @evalues = []
        @longest = 0
        hits = 0
        @query_results.each_pair do |query_id, list_of_hits|
          list_of_hits.each_with_index do |target_hit, query_index|
            if @target_results.has_key?(target_hit.target)
              list_of_hits_2 = @target_results[target_hit.target]
              list_of_hits_2.each_with_index do |query_hit2, target_index|
                if query_index == 0 && target_index == 0 &&
                   query_id == query_hit2.target
                  e = target_hit.evalue.to_f
                  e = 1e-200 if e==0
                  e = -Math.log10(e)
                  if !@reciprocals.key?(query_id)
                    @reciprocals[query_id] = []
                  end
                  @reciprocals[query_id] << target_hit
                  hits += 1
                  @longest = target_hit.alnlen  if target_hit.alnlen > @longest
                  @evalues << {:e => e, :length => target_hit.alnlen}
                elsif query_id == query_hit2.target
                  if !@missed.key?(query_id)
                    @missed[query_id] = []
                  end
                  @missed[query_id] << target_hit
                end
              end
            end
          end
        end
      end
      return hits
    end

    # Learns the evalue cutoff based on the length of the sequence
    # Finds hits that have a lower evalue than this cutoff
    def find_secondaries

      if File.exist?("#{@working_dir}/reciprocal_hits.txt")
        # puts "reciprocal output already exists"
      else
        length_hash = Hash.new
        fitting = Hash.new
        @evalues.each do |h|
          length_hash[h[:length]] = [] if !length_hash.key?(h[:length])
          length_hash[h[:length]] << h
        end

        (10..@longest).each do |centre|
          e = 0
          count = 0
          s = centre*0.1
          s = s.to_i
          s = 5 if s < 5
          (-s..s).each do |side|
            if length_hash.has_key?(centre+side)
              length_hash[centre+side].each do |point|
                e += point[:e]
                count += 1
              end
            end
          end
          if count>0
            mean = e/count
            fitting[centre] = mean
          end
        end
        hits = 0
        @missed.each_pair do |id, list|
          list.each do |hit|
            l = hit.alnlen.to_i
            e = hit.evalue
            e = 1e-200 if e==0
            e = -Math.log10(e)
            if fitting.has_key?(l)
              if e >= fitting[l]
                if !@reciprocals.key?(id)
                  @reciprocals[id] = []
                  found=false
                  @reciprocals[id].each do |existing_hit|
                    if existing_hit.query == hit.query &&
                      existing_hit.target == hit.target
                     found=true
                    end
                  end
                  if !found
                    @reciprocals[id] << hit
                    hits += 1
                  end
                end
              end
            end
          end
        end
      end
      return hits
    end

    def clear_memory
      # running lots of jobs at the same time was keeping a lot of stuff in
      # memory that you might not want so this empties out those big hashes.
      @query_results = nil
      @target_results = nil
    end

    def run evalue=1e-5, threads=1, split=true
      makedb
      run_blast evalue, threads, split
      load_outputs
      find_reciprocals
      find_secondaries
    end

    def size
      hits=0
      @reciprocals.each_pair do |key, list|
        list.each do |hit|
          hits += 1
        end
      end
      hits
    end

    def write_output
      s=""
      unless @reciprocals.nil?
        @reciprocals.each_pair do |query_id, hits|
          hits.each do |hit|
            s << "#{hit}\n"
          end
        end
        File.open("#{@working_dir}/reciprocal_hits.txt", "w") {|f| f.write s }
      end
    end

    def has_reciprocal? contig
      return true if @reciprocals.has_key?(contig)
      return false
    end
  end

end
