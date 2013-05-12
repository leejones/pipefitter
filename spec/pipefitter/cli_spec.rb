require File.expand_path('../../spec_helper.rb', __FILE__)

describe Pipefitter::Cli do
  include Pipefitter::SpecHelper

  it 'compiles a path' do
    Pipefitter.should_receive(:compile).with('/tmp/pipefitter_app', kind_of(Hash)).and_return(true)
    environment = { :PWD => '/tmp' }
    Pipefitter::Cli.run(['/tmp/pipefitter_app'], :environment => environment)
  end

  it 'compiles the PWD' do
    Pipefitter.should_receive(:compile).with('/tmp/pipefitter_app', kind_of(Hash)).and_return(true)
    environment = { :PWD => '/tmp/pipefitter_app' }
    Pipefitter::Cli.run([], :environment => environment)
  end

  it 'forces a compile' do
    Pipefitter.should_receive(:compile).with('/tmp/pipefitter_app', {
      :logger => kind_of(Logger),
      :force => true
    }).and_return(true)
    environment = { :PWD => '/tmp/pipefitter_app' }
    Pipefitter::Cli.run(['--force'], :environment => environment)
  end

  it 'archives' do
    Pipefitter.should_receive(:compile).with('/tmp/pipefitter_app', {
      :logger => kind_of(Logger)
    }).and_return(true)
    environment = { :PWD => '/tmp/pipefitter_app' }
    Pipefitter::Cli.run([], :environment => environment)
  end

  it 'helps' do
    Pipefitter.should_not_receive(:compile)
    environment = { :PWD => '/tmp/pipefitter_app' }
    null_logger.should_receive(:info).with(/Usage/)
    Pipefitter::Cli.run(['--help'], {
      :environment => environment,
      :logger => null_logger
    })
  end

  it 'uses a custom command' do
    Pipefitter.should_receive(:compile).with('/tmp/pipefitter_app', {
      :logger => kind_of(Logger),
      :command => 'script/precompile_assets'
    }).and_return(true)
    environment = { :PWD => '/tmp/pipefitter_app' }
    Pipefitter::Cli.run(['--command', 'script/precompile_assets'], :environment => environment)
  end
end
