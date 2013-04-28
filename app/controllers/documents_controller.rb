class DocumentsController < ApplicationController

  helper_method :sort_column, :sort_direction
  before_filter :authenticate

  # GET /documents
  # GET /documents.json
  def index
    @document = Document.new
    @documents = Document.order(sort_column, sort_direction)

    @documents = apply_tag    if params.has_key? :tag
    @documents = apply_search if params.has_key? :search

    @documents = @documents.offset(@offset) if @offset = params[:offset]

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @documents }
    end
  end

  # GET /documents/1
  # GET /documents/1.json
  def show
    @document = Document.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @document }
    end
  end

  # GET /documents/new
  # GET /documents/new.json
  def new
    @document = Document.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @document }
    end
  end

  # GET /documents/1/edit
  def edit
    @document = Document.find(params[:id])
  end

  # POST /documents
  # POST /documents.json
  def create
    @document = Document.new(params[:document])

    respond_to do |format|
      if @document.save
        format.html { redirect_to documents_path, notice: 'Document was successfully uploaded.' }
        format.json { render json: @document, status: :created, location: @document }
      else
        format.html { render new_document_path }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /documents/1
  # PUT /documents/1.json
  def update
    @document = Document.find(params[:id])
    @result = @document.update_attributes(params[:document])

    respond_to do |format|
      if @result
        format.html { redirect_to documents_path, notice: 'Document was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render edit_documents_path }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /documents/1
  # DELETE /documents/1.json
  def destroy
    @document = Document.find(params[:id])
    @document.destroy

    respond_to do |format|
      format.html { redirect_to documents_url }
      format.json { head :no_content }
    end
  end

  # GET /documents/tags.json
  def tags
    tag_list = Document.all.flat_map { |d| d.tags.to_a }.uniq
    render json: tag_list
  end

  private

  def apply_tag
    @documents.where(:tags => params[:tag])
  end

  def apply_search
    # SimpleDB requires that the query references the sort column
    where_cond = "search_data like ? and #{sort_column} is not null"
    query = params[:search].downcase
    @documents.where(where_cond, "%#{query}%")
  end

  def sort_column
    case params[:sort]
    when "author"
      :author
    when "filename"
      :filename
    when "created_at"
      :created_at
    else
      :title
    end
  end

  def sort_direction
    params[:direction] == :desc ? :desc : :asc
  end
end
