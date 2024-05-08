class AddContentTypeToResourceDescriptions < ActiveRecord::Migration[7.0]
  def change
    add_column :triple_eye_effable_resource_descriptions, :content_type, :string
  end
end
