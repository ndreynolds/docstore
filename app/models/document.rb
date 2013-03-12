class Document < AWS::Record::Base
  string_attr :title
  string_attr :author
  string_attr :filename
  string_attr :tags, :set => true
  timestamps

  def file=(file)
    self.filename = file.original_filename
    @file = file
  end

  def raw_tags=(raw_tags)
    self.tags = raw_tags.split(',')
    @raw_tags = raw_tags
  end

  def raw_tags
    tags.to_a.join(',')
  end

  def file_url
    filename ? file_s3_obj.url_for(:read) : nil
  end

  def save
    result = super
    if @file
      file_s3_obj.write(@file.read, :content_type => @file.content_type)
    end
    result
  end

  protected

  def file_s3_obj
    bucket_id = ENV['AWS_S3_BUCKET_ID']
    key = "#{id}/#{filename}"
    AWS::S3.new.buckets[bucket_id].objects[key]
  end
end
