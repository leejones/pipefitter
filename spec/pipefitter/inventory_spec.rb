require File.expand_path('../../../lib/pipefitter.rb', __FILE__)
require 'fileutils'

describe Pipefitter::Inventory do
  before(:each) do
    cleanup_inventory
  end

  it 'stores a record of a compilation' do
    inventory = Pipefitter::Inventory.new('/tmp/pipefitter_tests')
    inventory.put('source_checksum', 'artifact_checksum').should be_true
  end

  it 'retrieves a record of a compilation' do
    inventory = Pipefitter::Inventory.new('/tmp/pipefitter_tests')
    inventory.put('source_checksum', 'artifact_checksum')
    inventory.get('source_checksum').should eql('artifact_checksum')
  end

  private

  def cleanup_inventory
    FileUtils.rm_rf('/tmp/pipefitter_tests')
  end
end
