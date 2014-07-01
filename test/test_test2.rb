#!/usr/bin/env  ruby

require 'helper'

class Test2CRBBlast < Test::Unit::TestCase

  context 'crb-blast' do

    setup do
      @blaster = CRB_Blast.new('test/query2.fasta', 'test/target2.fasta')
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

    should 'setup2 should run ok' do
      ans = @blaster != nil
      assert_equal ans, true
    end

    should 'run blast should check if the databases exist yet' do
      tmp = CRB_Blast.new('test/query2.fasta', 'test/target2.fasta')
      assert_equal false, tmp.run_blast(10,1)
    end

    should 'load output should check if the databases exist' do
      tmp = CRB_Blast.new('test/query2.fasta', 'test/target2.fasta')
      assert_raise RuntimeError do
        tmp.load_outputs
      end
    end

    should 'find reciprocals' do
      assert_equal 7, @recips
    end

    should 'add secondary hits' do
      assert_equal 2, @secondaries
    end

    should 'get non reciprocal hits' do
      count=0
      @blaster.missed.each_pair do |key, value|
        value.each do |i|
          count+=1
        end
      end
      assert_equal count,70
    end
  end
end
