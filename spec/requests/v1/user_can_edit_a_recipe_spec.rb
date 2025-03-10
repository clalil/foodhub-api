# frozen_string_literal: true

RSpec.describe 'Update specific recipe', type: :request do
  let!(:creator) { create(:user) }
  let(:creator_credentials) { creator.create_new_auth_token }
  let!(:creator_headers) do
    { HTTP_ACCEPT: 'application/json' }.merge!(creator_credentials)
  end
  let!(:potential_editor) { create(:user) }
  let(:potential_editor_credentials) { potential_editor.create_new_auth_token }
  let!(:potential_editor_headers) do
    { HTTP_ACCEPT: 'application/json' }.merge!(potential_editor_credentials)
  end
  let(:recipe) do
    create(:recipe,
           title: 'Cookies',
           ingredients: 'Cookie ingredients, chocolate chips.',
           directions: 'Make the cookies.',
           user: creator)
  end
  describe 'user can update a recipe' do
    let(:expected_attributes) do
      {
        title: 'New Cookies',
        ingredients: 'New cookie mix, more chocolate.',
        directions: 'Make the new cookies.'
      }
    end
    before do
      put "/v1/recipes/#{recipe.id}", params: {
        recipe: {
          title: 'New Cookies',
          ingredients: 'New cookie mix, more chocolate.',
          directions: 'Make the new cookies.'
        }
      }, headers: creator_headers
    end

    it 'returns 201 response' do
      expect(response).to have_http_status 201
    end

    %i[title ingredients directions].each do |attribute|
      it "updates #{attribute} as value on the last Recipe" do
        expect(Recipe.last.send(attribute)).to eq expected_attributes[attribute]
      end
    end
  end

  describe 'returns an error message if attribute fail validations' do
    before do
      put "/v1/recipes/#{recipe.id}", params: {
        recipe: {
          title: 'New Cookies',
          ingredients: 'New cookie mix, more chocolate.' * 200,
          directions: 'Make the new cookies.'
        }
      }, headers: creator_headers
    end

    it 'returns 422 response' do
      expect(response).to have_http_status 422
    end

    it 'returns error message' do
      expect(response_json['error_message']).to eq 'Ingredients is too long (maximum is 5000 characters)'
    end
  end

  describe 'non-logged in visitor is unable to update a recipe' do
    let(:invalid_headers) { { HTTP_ACCEPT: 'application/json' } }

    before do
      put "/v1/recipes/#{recipe.id}", params: {
        recipe: {
          title: 'New Cookies',
          ingredients: 'New cookie mix, more chocolate.',
          directions: 'Make the new cookies.'
        }
      }, headers: invalid_headers
    end

    it 'returns 401 response' do
      expect(response).to have_http_status 401
    end

    it 'returns error message' do
      expect(response_json['errors']).to include 'You need to sign in or sign up before continuing.'
    end
  end

  describe 'non_creator can not update Recipe' do
    before do
      put "/v1/recipes/#{recipe.id}", params: {
        recipe: {
          title: 'New Cookies',
          ingredients: 'New cookie mix, more chocolate.',
          directions: 'Make the new cookies.'
        }
      }, headers: potential_editor_headers
    end

    it 'returns 401 response' do
      expect(response).to have_http_status 401
    end

    it 'returns error message' do
      expect(response_json['error_message']).to eq 'You are not authorized to perform this action.'
    end
  end
end
