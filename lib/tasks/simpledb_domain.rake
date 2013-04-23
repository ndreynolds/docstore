require 'aws-sdk'
require 'colorize'

namespace :simpledb do
  task :setup => :environment do
    check_env
    name = ENV['DOCSTORE_SDB_DOMAIN']

    puts 'A new SimpleDB domain will be created'.yellow
    puts "==> #{name}"
    confirm

    AWS::SimpleDB.new.domains.create(name)
    puts '==> Domain created'.green
  end

  task :remove => :environment do
    check_env
    name = ENV['DOCSTORE_SDB_DOMAIN']

    puts err_msg('This will delete this SimpleDB domain and all data.', 'Warning')
    puts "==> #{name}"
    confirm

    AWS::SimpleDB.new.domains[ENV['DOCSTORE_SDB_DOMAIN']].delete!
    puts '==> Domain deleted'.green
  end

  def err_msg msg, type='Error'
    "#{type.red.underline}: #{msg}"
  end

  def check_env
    if not ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
      fail err_msg 'AWS environment variables are not set. See README.md'
    elsif not ENV['DOCSTORE_SDB_DOMAIN']
      fail err_msg '$DOCSTORE_SDB_DOMAIN is not set'
    end
  end

  def confirm
    print 'Would you like to continue (y/n)? '
    fail unless STDIN.gets.chomp.downcase == 'y'
    puts
  end
end
