class PagesController < ApplicationController
  include ApplicationHelper

  caches_page :index, :editor, :docs, :dev

  def index
    @editor = false
  end

  def editor
    @editor = true
    @example = params["example"] || "twisted_extrusion"
    @example = @example.downcase.gsub("[^a-z0-9\-]", "").gsub("[- ]", "_").to_sym
    raise "example does not exist" unless example_exists?(@example)
  end

  def docs
    @editor = false
  end

  def dev
    @editor = false
  end

end
