require 'tempfile'
require File.join Rails.root, "lib", "ext_open_scad_lib.rb"

class RenderersController < ApplicationController

  respond_to :json

  def render_scad

    # SCAD => STL
    # ==========================================

    #cache_control :no_cache
    request.body.rewind

    # Run the ExtOpenSCAD Compiler
    #results = ExtOpenScad.compile! request.body.read
    api_json = {"message" => "", "output" => ""}
    scad_file = Tempfile.new("scad")

    begin
      request.body.rewind
      scad_file.write(request.body.read)
      scad_file.close(false)

      puts  "\n\n" + "-"*30 + "\n\n" + IO.read(scad_file.path) + "\n\n"

      api_response = extopenscad File.new(scad_file)
      api_json = JSON.parse api_response.to_s

      puts api_json["message"].inspect + "\n\n" + "-"*30
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

    #response.body = {
    data = {
      :stdout => api_json["message"],
      :stderr => errored ? (api_json["message"].present? ? api_json["message"] : "Uh oh, that went horribly wrong. Try again?") : "",
      :data => defined?(js) ? js : "",
      :format => "THREE.Geometry"
    }
    render :json => data
    #response.headers["Content-Type"] = "json"
  end


  def extopenscad(f)
    #implicitcad_api_server = Rails.env.development? ? "localhost:3000" : "23.21.177.106:3000"
    implicitcad_api_server = "23.21.177.106:3000"

    RestClient.post("#{implicitcad_api_server}/v1/render", :file => f) {|response, request, result| response }
  end

  add_method_tracer :extopenscad, 'Custom/RenderController/extopenscad', :metric => true

end
