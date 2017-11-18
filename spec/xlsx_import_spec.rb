require "spec_helper"

describe "XLSX import", :type => :request do
  MIME_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  describe "for a simple model" do
    it "imports the data" do
      file = fixture_file_upload("balls.xlsx", MIME_TYPE)
      post "/admin/ball/import", file: file
      expect(response.body).not_to include "failed"
      expect(Ball.count).to eq 2
      expect(Ball.first.color).to eq "red"
    end
  end
  describe "when columns are blank" do
    it "skips the extra columns" do
      file = fixture_file_upload("balls_blank_columns.xlsx", MIME_TYPE)
      post "/admin/ball/import", file: file
      expect(response.body).not_to include "failed"
      expect(Ball.count).to eq 2
      expect(Ball.first.color).to eq "red"
    end
  end
end
