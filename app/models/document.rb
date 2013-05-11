class Document < AWS::Record::Base
  string_attr :title
  string_attr :author
  string_attr :filename
  string_attr :tags, set: true
  string_attr :search_data
  timestamps

  validates_presence_of :title, :author

  # Set the SimpleDB domain name from the configuration.
  def initialize(*args)
    raise 'DOCSTORE_SDB_DOMAIN not set' if Rails.configuration.sdb_domain.blank?
    self.class.set_domain_name Rails.configuration.sdb_domain

    raise '$DOCSTORE_S3_BUCKET_ID not set' if Rails.configuration.s3_bucket_id.blank?
    @sobjects = AWS::S3.new.buckets[Rails.configuration.s3_bucket_id].objects

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
    self.tags.to_a.join(',')
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
    upload_file if @file
    result
  end

  def destroy
    file_s3_obj_thumb.delete
    file_s3_obj.delete
    super
  end

  protected

  # SimpleDB doesn't support case-insensitive search, so we instead store the
  # concatenated, downcased search fields in the search_data column and search
  # that.
  def update_search_data
    self.search_data = [self.title, self.author, self.filename].join('|')
      .downcase
      .squeeze(' ')
      .gsub(/[^a-z\s|]/, '')
  end

  # Pass on an uploaded file to S3, also creating a thumbnail when configured.
  def upload_file
    upload_thumb if Rails.configuration.thumbnails_enabled
    file_s3_obj.write(@file.tempfile.open, content_type: @file.content_type)
  end

  # Create a thumbnail with Imagemagick and upload it to S3
  def upload_thumb
    path = "#{Rails.root}/tmp/#{id}_#{Process.pid}.png"
    `convert #{@file.tempfile.path}[0] -scale 128x128 #{path}`

    if File.exists? path
      file_s3_obj_thumb.write(file: path, content_type: 'image/png')
      File.delete(path)
    end
  end

  def file_s3_obj
    @sobjects["#{id}/#{filename}"]
  end

  def file_s3_obj_thumb
    @sobjects["#{id}/#{filename}.thumb.png"]
  end
end
