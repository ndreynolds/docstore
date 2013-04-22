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

  def thumb_url
    filename ? file_s3_obj_thumb.url_for(:read) : 'document.png'
  end

  def save
    result = super
    if @file
      if Rails.configuration.thumbnails_enabled
        image = MiniMagick::Image.read @file 
        image.format 'png'
        image.resize '128x128'
        path = "#{Rails.root}/tmp/#{id}_#{Process.pid}"
        image.write(path)
        file_s3_obj_thumb.write(File.open(path), :content_type => 'image/png')
      end

      file_s3_obj.write(@file.read, :content_type => @file.content_type)
    end
    result
  end

  def destroy
    file_s3_obj_thumb.delete
    file_s3_obj.delete
    super
  end

  protected

  def s3_obj key
    bucket_id = ENV['AWS_S3_BUCKET_ID']
    AWS::S3.new.buckets[bucket_id].objects[key]
  end

  def file_s3_obj
    s3_obj "#{id}/#{filename}"
  end

  def file_s3_obj_thumb
    s3_obj "#{id}/#{filename}.thumb.png"
  end
end
