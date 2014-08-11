require 'spec_helper'

describe Document, :type => :model do
  before :each do
    Rails.configuration.sdb_domain = 'test'
    Rails.configuration.s3_bucket_id = 'test'

    AWS.stub!

    Document.send(:attr_accessor, :sobjects)
    Document.send(:attr_writer, :id)

    @doc = Document.new
    @doc.sobjects = double AWS::S3::ObjectCollection
    @doc.id = 'abc42'
    @doc.filename = 'foo.pdf'

    tempfile = double 'tempfile'
    allow(tempfile).to receive(:open).and_return(true)
    opts = { type: '', head: '', tempfile: tempfile }
    @uploaded_file = ActionDispatch::Http::UploadedFile.new opts
  end

  it 'can be instantiated' do
    expect(Document.new).to be_an_instance_of(Document)
  end

  it 'should set domain name upon instantiation' do
    Rails.configuration.sdb_domain = 'foobar'
    Document.new
    expect(Document.sdb_domain.name).to eq('foobar')
  end

  it 'should set up the ObjectCollection upon instantiation' do
    Rails.configuration.sdb_domain = 'foobar'
    doc = Document.new
    expect(doc.sobjects).to be_an_instance_of(AWS::S3::ObjectCollection)
  end

  it 'should complain if domain name not configured' do
    Rails.configuration.sdb_domain = nil
    expect { Document.new }.to raise_error

    Rails.configuration.sdb_domain = ''
    expect { Document.new }.to raise_error
  end

  it 'should complain if s3 bucket not configured' do
    Rails.configuration.s3_bucket_id = nil
    expect { Document.new }.to raise_error

    Rails.configuration.s3_bucket_id = ''
    expect { Document.new }.to raise_error
  end

  it 'should have the correct attributes set' do
    expect(@doc.attributes).to have_key(:title)
    expect(@doc.attributes).to have_key(:author)
    expect(@doc.attributes).to have_key(:filename)
    expect(@doc.attributes).to have_key(:tags)
    expect(@doc.attributes).to have_key(:search_data)
  end

  it 'should set the filename when file is set' do
    file_double = double 'file'
    expect(file_double).to receive(:original_filename).and_return('file.pdf')
    @doc.file = file_double
    expect(@doc.filename).to eq('file.pdf')
  end

  it 'should keep @tags and @raw_tags in sync' do
    @doc.raw_tags = 'scheme,c,python,ruby'
    expect(@doc.tags).to eq(Set.new(['scheme', 'c', 'python', 'ruby']))

    @doc.tags = @doc.tags.add 'clojure'
    expect(@doc.tags).to eq(Set.new(['scheme', 'c', 'python', 'ruby', 'clojure']))
    expect(@doc.raw_tags).to eq('scheme,c,python,ruby,clojure')
  end

  it 'provides the file url when a filename is set' do
    s3_obj = double 's3_obj'
    expect(s3_obj).to receive(:url_for).and_return('http://foo.com')
    expect(@doc).to receive(:file_s3_obj).and_return(s3_obj)
    expect(@doc.file_url).to eq('http://foo.com')
  end

  it 'provides the file thumbnail url when a filename is set' do
    s3_obj = double 's3_obj'
    expect(s3_obj).to receive(:url_for).and_return('http://bar.com')
    expect(@doc).to receive(:file_s3_obj_thumb).and_return(s3_obj)
    expect(@doc.thumb_url).to eq('http://bar.com')
  end

  it 'provides a default thumbnail when no filename is set' do
    @doc.filename = nil
    expect(@doc.sobjects).not_to receive :[]
    expect(@doc.thumb_url).to eq('document.png')
  end

  it 'updates @search_data on save' do
    @doc.title = 'Huckleberry Finn'
    @doc.author = 'Mark Twain'
    @doc.filename = 'finn.pdf'

    @doc.search_data = ''
    @doc.save
    expect(@doc.search_data).to eq('huckleberry finn|mark twain|finnpdf')
  end

  it 'filters punctuation and extra whitespace from @search_data' do
    @doc.title = 'huckle-.[];berry!!    finn'
    @doc.author = 'Mark       Twain'
    @doc.filename = 'finn.pdf'

    @doc.search_data = ''
    @doc.save
    expect(@doc.search_data).to eq('huckleberry finn|mark twain|finnpdf')
  end

  it 'tries to upload the file to S3 when present' do
    expect(@doc).to receive(:upload_file).once.and_return(true)
    file_double = double 'file'
    expect(file_double).to receive(:original_filename).and_return('file.pdf')
    @doc.file = file_double
    @doc.save
  end

  it 'does not try to upload the file to S3 when absent' do
    expect(@doc).to receive(:upload_file).never
    @doc.save
  end

  it 'should upload a thumbnail with the file' do
    Rails.configuration.thumbnails_enabled = true

    expect(@doc).to receive(:upload_thumb).once.and_return(true)

    allow(@doc).to receive_message_chain(:file_s3_obj, :write).and_return(true)
    @doc.file = @uploaded_file

    @doc.save
  end

  it 'should not upload a thumbnail when disabled' do
    Rails.configuration.thumbnails_enabled = false

    expect(@doc).to receive(:upload_thumb).never

    allow(@doc).to receive_message_chain(:file_s3_obj, :write).and_return(true)
    @doc.file = @uploaded_file

    @doc.save
  end

end
