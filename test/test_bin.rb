#!/usr/bin/env  ruby

require 'helper'

class TestBinary < Test::Unit::TestCase

  context 'crb-blast' do

    should 'run binary' do
      cmd = "bundle exec bin/crb-blast --help"
      runner = CRB_Blast::Cmd.new(cmd)
      runner.run
      assert runner.status.success?
    end

  end
end
