require 'spec_helper'

describe DocumentsController, type: :controller do
  before :each do
    AWS.stub!
    controller.stub authenticate: true
  end

  describe 'GET #index' do
    it 'assigns a new Document to @document' do
      get :index
      assigns(:document).should be_an_instance_of(Document)
    end

    it 'populates all documents without filters' do
      get :index
      scope = assigns(:documents)
      scope.should be_an_instance_of(AWS::Record::Model::Scope)
      options = scope.instance_variable_get(:@options)
      options[:where].should == []
      options[:order].should == [:title, :asc]
    end

    it 'populates documents matching a search query' do
      get :index, search: 'eskimo'
      options = assigns(:documents).instance_variable_get(:@options)
      expected_query = ['search_data like ? and title is not null', '%eskimo%']
      options[:where].should == [expected_query]
      options[:order].should == [:title, :asc]
    end

    it 'populates documents matching a tag' do
      get :index, tag: 'fishing'
      options = assigns(:documents).instance_variable_get(:@options)
      options[:where].should == [[{tags: 'fishing'}]]
      options[:order].should == [:title, :asc]
    end

    it 'allows the sort direction to be changed' do
      get :index, sort: 'created_at', direction: 'desc'
      options = assigns(:documents).instance_variable_get(:@options)
      options[:order].should == [:created_at, :desc]
    end

    it 'renders the index view' do
      get :index
      response.should render_template('index')
    end

    it 'populates documents with an offset'
  end

  describe 'GET #show' do
    it 'assigns requested Document to @document' do
      doc = create(:document)
      Document.stub(:find).with('42').and_return(doc)
      get :show, id: '42'
      assigns(:document).should == doc
    end

    it 'renders the show view' do
      Document.stub(:find).with('42').and_return(create(:document))
      get :show, id: '42'
      response.should render_template('show')
    end
  end

  describe 'GET #new' do
    it 'assigns a new Document to @document' do
      get :new
      assigns(:document).should be_an_instance_of(Document)
    end

    it 'renders the new view' do
      get :new
      response.should render_template('new')
    end
  end

  describe 'GET #edit' do
    it 'assigns the Document to be edited to @document' do
      doc = create(:document)
      Document.stub(:find).with('25').and_return(doc)
      get :edit, id: '25'
      assigns(:document).should == doc
    end

    it 'renders the edit view' do
      Document.stub(:find).with('25').and_return(create(:document))
      get :edit, id: '25'
      response.should render_template('edit')
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'saves the new document and redirects to index' do
        # Allow save to validate, but stub out the AWS interaction
        Document.any_instance.should_receive(:create).once.and_return(true)
        post :create, document: attributes_for(:document)
        flash[:notice].should == 'Document was successfully uploaded.'
        response.should redirect_to(documents_path)
      end
    end

    context 'with invalid attributes' do
      it 'renders the new view when unable to save' do
        Document.any_instance.should_receive(:create).never
        post :create, document: attributes_for(:document, :invalid)
        response.should render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    before :each do
      @document = create(:document)
      Document.stub(:find).with('42').and_return(@document)
    end

    context 'with valid attributes' do
      it 'locates the requested @document' do
        put :update, id: '42', document: attributes_for(:document)
        assigns(:document).should == @document
      end

      it 'updates the document and redirects to index' do
        @document.should_receive(:update).once.and_return(true)
        old_title = @document.title
        put :update, id: '42',
          document: attributes_for(:document, title: 'War and Peace')
        @document.title.should == 'War and Peace'
        response.should redirect_to(documents_path)
      end
    end

    context 'with invalid attributes' do
      it 'locates the requested @document' do
        put :update, id: '42', document: attributes_for(:document)
        assigns(:document).should == @document
      end

      it 'renders the edit view' do
        @document.should_receive(:update).never
        put :update, id: '42', document: attributes_for(:document, :invalid)
        response.should render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    before :each do
      @document = create(:document)
      Document.stub(:find).with('1').and_return(@document)
    end

    it 'destroys the document and redirects to index' do
      @document.should_receive(:destroy).once.and_return(true)
      delete :destroy, id: '1'
      response.should redirect_to(documents_path)
    end

    it 'sets flash error if the document could not be destroyed' do
      @document.should_receive(:destroy).once.and_return(false)
      delete :destroy, id: '1'
      flash[:error].should == 'There was an error deleting the document'
      response.should redirect_to(documents_path)
    end
  end

  describe 'GET #tags' do
    it 'renders document tags as JSON' do
      Document.should_receive(:all).and_return([
        build(:document, tags: ['white', 'green', 'orange']),
        build(:document, tags: ['white', 'blue', 'orange']),
        build(:document, tags: ['white', 'green', 'yellow'])
      ])
      expected = ['white', 'green', 'orange', 'blue', 'yellow']
      get :tags, format: :json
      response.header['Content-Type'].should include('application/json')
      response.body.should == expected.to_json
    end
  end
end
