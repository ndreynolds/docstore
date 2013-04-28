require 'aws-sdk'
require 'colorize'

namespace :s3 do
  task :setup => :environment do
    check_env

    name = ENV['DOCSTORE_S3_BUCKET_ID']
    s3 = AWS::S3.new

    fail err_msg 'S3 bucket already exists' if s3.buckets[name].exists?

    puts 'A new S3 bucket will be created'.yellow
    puts "==> #{name}"
    confirm

    s3.buckets.create(name)
    puts '==> Bucket created'.green
  end

  def err_msg msg, type='Error'
    "#{type.red.underline}: #{msg}"
  end

  def check_env
    if not ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
      fail err_msg 'AWS environment variables are not set. See README.md'
    elsif not ENV['DOCSTORE_S3_BUCKET_ID']
      fail err_msg '$DOCSTORE_SDB_DOMAIN is not set'
    end
  end

  def confirm
    print 'Would you like to continue (y/n)? '
    fail unless STDIN.gets.chomp.downcase == 'y'
    puts
  end
end
