#!/usr/bin/env	ruby

require 'helper'

class TestCRBBlast < Test::Unit::TestCase

  context 'crb-blast' do

    setup do
      @blaster = CRB_Blast.new('test/query.fasta', 'test/target.fasta')
      @dbs = @blaster.makedb
      @run = @blaster.run_blast(1e-5, 6)
      @load = @blaster.load_outputs
      @recips = @blaster.find_reciprocals
      @secondaries = @blaster.find_secondaries
    end

    teardown do
      extensions  = ["blast", "nsq", "nin", "nhr", "psq", "pin", "phr"]
      Dir.chdir("test") do
        Dir["*"].each do |file|
          extensions.each do |extension|
            if file =~ /.*#{extension}/
              File.delete(file)
            end
          end
        end
      end
    end

    should 'setup should run ok' do
      ans = @blaster != nil
      assert_equal ans, true
    end

    should 'determine that the target is a protein sequence' do
      prot = @blaster.target_is_prot
      assert_equal @dbs, ['query', 'target']
      assert_equal prot, true
    end

    should 'run blast' do
      assert_equal @run, true
    end

    should 'load outputs' do
      assert_equal @load, [15,15]
    end

    should 'find reciprocals' do
      assert_equal @recips, 10
    end

    should 'check if contig has reciprocal hit' do
      assert_equal @blaster.has_reciprocal?("scaffold3"), true
    end

    should 'not find fake scaffold name' do
      assert_equal @blaster.has_reciprocal?("not_a_scaffold"), false
    end

    should 'get query results' do
      count=0
      @blaster.query_results.each_pair do |key, list|
        list.each do |hit|
          count+=1
        end
      end
      cmd = "wc -l test/query_into_target.1.blast"
      lines = `#{cmd}`.to_i
      assert_equal count, lines
    end

    should 'output all reciprocal hits' do
      a = @blaster.reciprocals
      assert_equal a["scaffold3"][0].target, "AT3G44735.1"
      assert_equal a["scaffold5"][0].target, "AT5G13650.2"
    end

    should 'run' do
      blaster = CRB_Blast.new('test/query.fasta', 'test/target.fasta')
      blaster.run 1, 1
    end

    should 'get number of reciprocals' do
      assert_equal 11, @blaster.size
    end
  end
end
