require 'tempfile'
require File.join Rails.root, "lib", "ext_open_scad_lib.rb"
require File.join Rails.root, "lib", "scad.rb"

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


    # STL => UTF
    # ==========================================

    if errored == false
      #puts "stl -> obj"
      #obj = SCAD.convert_format(api_json["output"], 'stl', 'obj')[:output]
      puts "obj -> utf"
      #obj = IO.read File.join Rails.root, "tools", "ben_00.obj"
      obj = api_json["output"]

      obj_file = File.new(File.join(Rails.root, "test.obj"), "w")
      obj_file.write obj
      obj_file.close
      
      #puts obj
      utf_files = SCAD.obj_to_utf(obj)[:output]
      utf = utf_files.collect do |f|
        puts f.path
        s = IO.read(f)
        File.unlink(f.path)
        s
      end
      #puts utf.inspect

      #js = ThreeJSMonkey.compile_js(File.new stl.path )
    end

    # Response
    # ==========================================

    #response.body = {
    data = {
      :stdout => api_json["message"],
      :stderr => errored ? (api_json["message"].present? ? api_json["message"] : "Uh oh, that went horribly wrong. Try again?") : "",
      :data => defined?(utf) ? utf : "",
      :format => "utf-8"
    }
    render :json => data
    #response.headers["Content-Type"] = "json"
  end


  def extopenscad(f)
    #implicitcad_api_server = Rails.env.development? ? "localhost:3000" : "23.21.177.106:3000"
    implicitcad_api_server = Rails.env.development? ? "172.16.42.4:3000" : "23.21.177.106:3000"
    #implicitcad_api_server = "23.21.177.106:3000"

    RestClient.post("#{implicitcad_api_server}/v1/render", :file => f, :format => "obj") {|response, request, result| response }
  end

  add_method_tracer :extopenscad, 'Custom/RenderController/extopenscad', :metric => true

end
