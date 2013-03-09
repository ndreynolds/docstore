class Document < AWS::Record::Base
  string_attr :title
  string_attr :author
  string_attr :filename
  timestamps

  def file= file
    self.filename = file.original_filename
    @file = file
  end

  def file_url
    filename ? file_s3_obj.url_for(:read) : nil
  end

  def save
    super
    if @file
      file_s3_obj.write(@file.read, :content_type => @file.content_type)
    end
  end

  protected

  def file_s3_obj
    bucket_id = ENV['AWS_S3_BUCKET_ID']
    key = "#{id}/#{filename}"
    AWS::S3.new.buckets[bucket_id].objects[key]
  end
end
