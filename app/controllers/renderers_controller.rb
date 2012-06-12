require File.join Rails.root, "lib", "ext_open_scad_lib.rb"

class RenderersController < ApplicationController

  respond_to :json

  def render
    #cache_control :no_cache
    request.body.rewind

    # Run the ExtOpenSCAD Compiler
    results = ExtOpenScad.compile! request.body.read

    response.body = results.to_json
    response.headers["Content-Type"] = "json"
  end

end
