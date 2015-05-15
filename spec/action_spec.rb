require "spec_helper"

describe "Import action", :type => :request do
  it "is shown" do
    get "/admin/ball"
    expect(response.body).to include "Import"
  end

  it "shows the form" do
    get "/admin/ball/import"
    expect(response.body).to include "Upload file"
  end
end
