#!/usr/bin/env ruby

require 'bio'
require 'which'
require 'hit'
require 'crb-blast'

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

  def initialize query, target, output:nil
    @query = query
    @target = target
    if output.nil?
      @working_dir = File.expand_path(File.dirname(query)) # no trailing /
    else
      @working_dir = File.expand_path(output)
      mkcmd = "mkdir #{@working_dir}"
      if !Dir.exist?(@working_dir)
        puts mkcmd
        `#{mkcmd}`
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
      `#{make_query_db_cmd}`
    end

    make_target_db_cmd = "#{@makedb_path} -in #{@target}"
    make_target_db_cmd << " -dbtype nucl " if !@target_is_prot
    make_target_db_cmd << " -dbtype prot " if @target_is_prot
    make_target_db_cmd << " -title #{target_name} "
    make_target_db_cmd << " -out #{@working_dir}/#{target_name}"

    db_target = "#{target_name}.nsq" if !@target_is_prot
    db_target = "#{target_name}.psq" if @target_is_prot
    if !File.exists?("#{@working_dir}/#{db_target}")
      `#{make_target_db_cmd}`
    end
    @databases = true
    [@query_name, @target_name]
  end

  def run_blast(evalue, threads)
    if @databases
      @output1 = "#{@working_dir}/#{query_name}_into_#{target_name}.1.blast"
      @output2 = "#{@working_dir}/#{target_name}_into_#{query_name}.2.blast"
      cmd1=""
      cmd2=""
      if @query_is_prot
        if @target_is_prot
          cmd1 << "#{@blastp_path} "
          cmd2 << "#{@blastp_path} "
        else
          cmd1 << "#{@tblastn_path} " 
          cmd2 << "#{@blastx_path} "
        end
      else
        if @target_is_prot
          cmd1 << "#{@blastx_path} "
          cmd2 << "#{@tblastn_path} "
        else
          cmd1 << "#{@blastn_path} "
          cmd2 << "#{@blastn_path} "
        end
      end
      cmd1 << " -query #{@query} -db #{@working_dir}/#{@target_name} "
      cmd1 << " -out #{@output1} -evalue #{evalue} "
      cmd1 << " -outfmt \"6 std qlen slen\" "
      cmd1 << " -max_target_seqs 50 "
      cmd1 << " -num_threads #{threads}"

      cmd2 << " -query #{@target} -db #{@working_dir}/#{@query_name} "
      cmd2 << " -out #{@output2} -evalue #{evalue} "
      cmd2 << " -outfmt \"6 std qlen slen\" "
      cmd2 << " -max_target_seqs 50 "
      cmd2 << " -num_threads #{threads}"

      if !File.exists?("#{@output1}")
        `#{cmd1}`
      end
      if !File.exists?("#{@output2}")
        `#{cmd2}`
      end
      return true
    else
      return false
    end
  end

  def load_outputs
    if File.exist?("#{@working_dir}/reciprocal_hits.txt")
      # puts "reciprocal output already exists"
    else
      @query_results = Hash.new
      @target_results = Hash.new
      q_count=0
      t_count=0
      if !File.exists?("#{@output1}")
        puts "can't find #{@output1}"
      end
      if !File.exists?("#{@output2}")
        puts "can't find #{@output2}"
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
      @longest=0
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

  def run evalue, threads
    makedb
    run_blast evalue, threads
    load_outputs
    find_reciprocals
    find_secondaries
  end

  def size
    hits=0
    @reciprocals.each do |list|
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
