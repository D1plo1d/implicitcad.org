class PagesController < ApplicationController
  include ApplicationHelper

  def index
  end

  def editor
    @example = params["example"] || "twisted_extrusion"
    @example = @example.downcase.gsub("[^a-z0-9\-]", "").gsub("[- ]", "_").to_sym
    raise "example does not exist" unless example_exists?(@example)
  end

end
