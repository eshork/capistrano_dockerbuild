require "spec_helper"

RSpec.describe Capistrano::Docker::Build do
  it "has a version number" do
    expect(Capistrano::Docker::Build::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
