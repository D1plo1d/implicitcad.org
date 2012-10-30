class PagesController < ApplicationController
  include ApplicationHelper

  caches_page :index, :editor, :examples, :api, :faq, :tutorial

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

  def api
    @editor = false
  end

  def tutorial
    @editor = false
  end

  def faq
    @editor = false
  end

  def examples
    @editor = false
  end

end
