require "spec_helper"

describe "XLSX import", :type => :request do
  describe "for a simple model" do
    it "imports the data" do
      file = fixture_file_upload("balls.xlsx", "octet/stream") # FIXME: xlsx MIME type
      post "/admin/ball/import", file: file, import_format: 'xlsx'
      expect(response.body).not_to include "failed"
      expect(Ball.count).to eq 2
      expect(Ball.first.color).to eq "red"
    end
  end
end
