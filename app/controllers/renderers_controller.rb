require 'tempfile'
require File.join Rails.root, "lib", "ext_open_scad_lib.rb"

class RenderersController < ApplicationController

  respond_to :json

  def render

    # SCAD => STL
    # ==========================================

    #cache_control :no_cache
    request.body.rewind

    # Run the ExtOpenSCAD Compiler
    #results = ExtOpenScad.compile! request.body.read
    api_json = {"message" => "", "output" => ""}
    scad_file = Tempfile.new("scad")

    begin
      scad_file.write(request.body.read)
      scad_file.close(false)
      api_response = RestClient.post('localhost:3000/v1/render', :file => File.new(scad_file)) {|response, request, result| response }
      api_json = JSON.parse api_response.to_s
    #rescue Exception => e
    #  puts [ "\n<Error>".red, [e.message, e.backtrace], "</Error>\n".red ].flatten(2).join("\n")
    ensure
      scad_file.close(true) if defined? scad_file
    end

    errored = !(defined? api_response and api_response.present? and api_response.code == 201)


    # STL => THREE.js
    # ==========================================

    if errored == false

      stl = Tempfile.new(["stl", ".stl"], File.join(Rails.root, "tmp"))
      begin
        stl.write api_json["output"]
        stl.close(false)

        js = ThreeJSMonkey.compile_js(File.new stl.path )
      ensure
        stl.close(true)
      end

    end

    # Response
    # ==========================================

    response.body = {
      :stdout => api_json["message"],
      :stderr => errored ? (api_json["message"].present? ? api_json["message"] : "Uh oh, that went horribly wrong. Try again?") : "",
      :data => defined?(js) ? js : "",
      :format => "THREE.Geometry"
    }.to_json
    response.headers["Content-Type"] = "json"
  end

end
