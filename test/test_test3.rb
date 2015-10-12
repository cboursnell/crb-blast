#!/usr/bin/env	ruby

require 'helper'

class Test3CRBBlast < Test::Unit::TestCase

  context 'crb-blast' do

    setup do

    end

    teardown do
      extensions  = ["blast", "nsq", "nin", "nhr", "psq", "pin", "phr"]
      Dir["*"].each do |file|
        extensions.each do |extension|
          if file =~ /.*\.#{extension}$/
            File.delete(file)
          end
        end
      end
    end

    should 'raise error when files don\'t exist' do
      query = File.join(File.dirname(__FILE__), 'not_query.fasta')
      target = File.join(File.dirname(__FILE__), 'not_target.fasta')
      assert_raise IOError do
        blaster = CRB_Blast::CRB_Blast.new(query, target)
      end
    end

    should 'run' do
      blaster = CRB_Blast::CRB_Blast.new('test/query.fasta',
                                         'test/target.fasta')
      blaster.run 1, 1, false
      assert blaster.reciprocals
    end

    should 'work for query sequences with pipes' do
      query = File.join(File.dirname(__FILE__), 'query3.fasta')
      target = File.join(File.dirname(__FILE__), 'target.fasta')

      blaster = CRB_Blast::CRB_Blast.new(query, target)
      dbs = blaster.makedb
      run = blaster.run_blast(1e-5, 6, false)
      load = blaster.load_outputs
      recip_count = blaster.find_reciprocals
      recips = blaster.reciprocals
      assert_equal 3, recip_count, "reciprocal hits"
      assert recips.has_key?("tr|C3Y8C9|C3Y8C9_BRAFL")
      assert recips.has_key?("sp|O47426|ATP6_BRAFL")
      assert recips.has_key?("sp|C4A0D9|BAP1_BRAFL")
    end
  end
end
