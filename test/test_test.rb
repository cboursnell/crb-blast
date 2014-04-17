#!/usr/bin/env	ruby

require 'helper'

class TestCRBBlast < Test::Unit::TestCase

  context 'crb-blast' do

    setup do
      @blaster = CRB_Blast.new('test/query.fasta', 'test/target.fasta')
      @dbs = @blaster.makedb
      @run = @blaster.run_blast 6
      @load = @blaster.load_outputs
      @recips = @blaster.find_reciprocals
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
      assert_equal @load, [10,10]
    end

    should 'find reciprocals' do
      assert_equal @recips, 10
    end

    should 'check if contig has reciprocal hit' do
      assert_equal @blaster.has_reciprocal?("scaffold3"), true
    end
  end
end
