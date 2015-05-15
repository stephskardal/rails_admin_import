require "spec_helper"
require "rails_admin_import"

describe RailsAdminImport::Formats::CSVImporter do

  it "finds the class" do
    expect(described_class).not_to be_nil
  end

end
