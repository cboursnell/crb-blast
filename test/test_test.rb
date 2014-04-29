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
      # delete stuff
      db_files = ["target.psq", "target.pin", "target.phr",
        "query.nsq", "query.nin", "query.nhr", 
        "query_into_target.1.blast", "target_into_query.2.blast"]
      db_files.each do |file|
        `rm #{file}`
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
      cmd = "wc -l query_into_target.1.blast"
      lines = `#{cmd}`.to_i
      assert_equal count, lines
    end

    should 'output all reciprocal hits' do
      a = @blaster.reciprocals
      assert_equal a["scaffold3"][0].target, "AT3G44735.1"
      assert_equal a["scaffold5"][0].target, "AT5G13650.2"
    end
  end
end
