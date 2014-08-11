require 'spec_helper'

describe DocumentsController, type: :controller do
  before :each do
    AWS.stub!
    allow(controller).to receive_messages authenticate: true
  end

  describe 'GET #index' do
    it 'assigns a new Document to @document' do
      get :index
      expect(assigns(:document)).to be_an_instance_of(Document)
    end

    it 'populates all documents without filters' do
      get :index
      scope = assigns(:documents)
      expect(scope).to be_an_instance_of(AWS::Record::Model::Scope)
      options = scope.instance_variable_get(:@options)
      expect(options[:where]).to eq([])
      expect(options[:order]).to eq([:title, :asc])
    end

    it 'populates documents matching a search query' do
      get :index, search: 'eskimo'
      options = assigns(:documents).instance_variable_get(:@options)
      expected_query = ['search_data like ? and title is not null', '%eskimo%']
      expect(options[:where]).to eq([expected_query])
      expect(options[:order]).to eq([:title, :asc])
    end

    it 'populates documents matching a tag' do
      get :index, tag: 'fishing'
      options = assigns(:documents).instance_variable_get(:@options)
      expect(options[:where]).to eq([[{tags: 'fishing'}]])
      expect(options[:order]).to eq([:title, :asc])
    end

    it 'allows the sort direction to be changed' do
      get :index, sort: 'created_at', direction: 'desc'
      options = assigns(:documents).instance_variable_get(:@options)
      expect(options[:order]).to eq([:created_at, :desc])
    end

    it 'renders the index view' do
      get :index
      expect(response).to render_template('index')
    end

    it 'populates documents with an offset'
  end

  describe 'GET #show' do
    it 'assigns requested Document to @document' do
      doc = create(:document)
      allow(Document).to receive(:find).with('42').and_return(doc)
      get :show, id: '42'
      expect(assigns(:document)).to eq(doc)
    end

    it 'renders the show view' do
      allow(Document).to receive(:find).with('42').and_return(create(:document))
      get :show, id: '42'
      expect(response).to render_template('show')
    end
  end

  describe 'GET #new' do
    it 'assigns a new Document to @document' do
      get :new
      expect(assigns(:document)).to be_an_instance_of(Document)
    end

    it 'renders the new view' do
      get :new
      expect(response).to render_template('new')
    end
  end

  describe 'GET #edit' do
    it 'assigns the Document to be edited to @document' do
      doc = create(:document)
      allow(Document).to receive(:find).with('25').and_return(doc)
      get :edit, id: '25'
      expect(assigns(:document)).to eq(doc)
    end

    it 'renders the edit view' do
      allow(Document).to receive(:find).with('25').and_return(create(:document))
      get :edit, id: '25'
      expect(response).to render_template('edit')
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'saves the new document and redirects to index' do
        # Allow save to validate, but stub out the AWS interaction
        expect_any_instance_of(Document).to receive(:create).once.and_return(true)
        post :create, document: attributes_for(:document)
        expect(flash[:notice]).to eq('Document was successfully uploaded.')
        expect(response).to redirect_to(documents_path)
      end
    end

    context 'with invalid attributes' do
      it 'renders the new view when unable to save' do
        expect_any_instance_of(Document).to receive(:create).never
        post :create, document: attributes_for(:document, :invalid)
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    before :each do
      @document = create(:document)
      allow(Document).to receive(:find).with('42').and_return(@document)
    end

    context 'with valid attributes' do
      it 'locates the requested @document' do
        put :update, id: '42', document: attributes_for(:document)
        expect(assigns(:document)).to eq(@document)
      end

      it 'updates the document and redirects to index' do
        expect(@document).to receive(:update).once.and_return(true)
        old_title = @document.title
        put :update, id: '42',
          document: attributes_for(:document, title: 'War and Peace')
        expect(@document.title).to eq('War and Peace')
        expect(response).to redirect_to(documents_path)
      end
    end

    context 'with invalid attributes' do
      it 'locates the requested @document' do
        put :update, id: '42', document: attributes_for(:document)
        expect(assigns(:document)).to eq(@document)
      end

      it 'renders the edit view' do
        expect(@document).to receive(:update).never
        put :update, id: '42', document: attributes_for(:document, :invalid)
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    before :each do
      @document = create(:document)
      allow(Document).to receive(:find).with('1').and_return(@document)
    end

    it 'destroys the document and redirects to index' do
      expect(@document).to receive(:destroy).once.and_return(true)
      delete :destroy, id: '1'
      expect(response).to redirect_to(documents_path)
    end

    it 'sets flash error if the document could not be destroyed' do
      expect(@document).to receive(:destroy).once.and_return(false)
      delete :destroy, id: '1'
      expect(flash[:error]).to eq('There was an error deleting the document')
      expect(response).to redirect_to(documents_path)
    end
  end

  describe 'GET #tags' do
    it 'renders document tags as JSON' do
      expect(Document).to receive(:all).and_return([
        build(:document, tags: ['white', 'green', 'orange']),
        build(:document, tags: ['white', 'blue', 'orange']),
        build(:document, tags: ['white', 'green', 'yellow'])
      ])
      expected = ['white', 'green', 'orange', 'blue', 'yellow']
      get :tags, format: :json
      expect(response.header['Content-Type']).to include('application/json')
      expect(response.body).to eq(expected.to_json)
    end
  end
end
