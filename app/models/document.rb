class Document < AWS::Record::Base
  string_attr :title
  string_attr :author
  string_attr :filename
  string_attr :tags, :set => true
  string_attr :search_data
  timestamps

  # Set the SimpleDB domain name from the configuration.
  def initialize(*args)
    raise 'DOCSTORE_SDB_DOMAIN not set' if Rails.configuration.sdb_domain.blank?
    self.class.set_domain_name Rails.configuration.sdb_domain
    super
  end

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
    update_search_data
    result = super
    upload_to_s3 if @file
    result
  end

  def destroy
    file_s3_obj_thumb.delete
    file_s3_obj.delete
    super
  end

  protected

  # SimpleDB doesn't support case-insensitive search, so we store the concatenated,
  # downcased search fields in the search_data column and search that.
  def update_search_data
    self.search_data = [self.title, self.author, self.filename].join('|')
      .downcase
      .squeeze(' ')
      .gsub(/[^a-z\s|]/, '')
  end

  # Pass on an uploaded file to S3, also creating a thumbnail when configured.
  def upload_to_s3
    if Rails.configuration.thumbnails_enabled
      path = "#{Rails.root}/tmp/#{id}_#{Process.pid}"

      image = MiniMagick::Image.read @file.tempfile
      image.limit 'memory', Rails.configuration.imagemagick_memory_limit
      image.format 'png'
      image.resize '128x128'
      image.write(path)
      image.destroy!

      File.open(path) do |fp|
        file_s3_obj_thumb.write(fp, :content_type => 'image/png')
      end
      File.delete(path)
    end

    file_s3_obj.write(@file.tempfile.open, :content_type => @file.content_type)
  end

  # Return an AWS::S3:S3Object with the given key from the configured bucket.
  def s3_obj key
    raise '$DOCSTORE_S3_BUCKET_ID not set' if Rails.configuration.s3_bucket_id.blank?
    AWS::S3.new.buckets[Rails.configuration.s3_bucket_id].objects[key]
  end

  def file_s3_obj
    s3_obj "#{id}/#{filename}"
  end

  def file_s3_obj_thumb
    s3_obj "#{id}/#{filename}.thumb.png"
  end
end
