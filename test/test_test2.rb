#!/usr/bin/env  ruby

require 'helper'

class TestCRBBlast < Test::Unit::TestCase

  context 'crb-blast' do

    setup do
      @blaster = CRB_Blast.new('test/query2.fasta', 'test/target2.fasta')
      @dbs = @blaster.makedb
      @run = @blaster.run_blast 6
      @load = @blaster.load_outputs
      @recips = @blaster.find_reciprocals
    end

    teardown do
      # delete stuff
      db_files = ["target2.nsq", "target2.nin", "target2.nhr",
        "query2.nsq", "query2.nin", "query2.nhr", 
        "query2_into_target2.1.blast", "target2_into_query2.2.blast"]
      db_files.each do |file|
        `rm #{file}`
      end
    end

    should 'setup2 should run ok' do
      ans = @blaster != nil
      assert_equal ans, true
    end

    should 'run blast should check if the databases exist yet' do
      tmp = CRB_Blast.new('test/query2.fasta', 'test/target2.fasta')
      assert_equal tmp.run_blast(1), false
    end

    should 'load output should check if the databases exist' do
      tmp = CRB_Blast.new('test/query2.fasta', 'test/target2.fasta')
      assert_raise RuntimeError do
        tmp.load_outputs
      end
    end

    should 'print all reciprocals' do
      assert_equal @recips, 9
    end
  end
end
