module ExtOpenScad
  def self.compile!(scad_script)
    puts "\n"*5
    puts scad_script
    puts "\n"*3

    # create the temp files
    files = Hash[ {input: ".scad", output: ".js"}.collect { |sym, ext| [sym, Tempfile.new(["loljk", ext])] } ]
    stdin, stdout, stderr = [nil, nil, nil]
    response_data = ""

    begin
      # close the temp files immediately to save on file handles
      files.each {|sym, f| f.close(false)}

      # load the scad script in to the input file
      File.open(files[:input], 'w') {|f| f.write(scad_script) }

      puts "running extopenscad..."

      # process the input with the extopenscad js exporter
      hs_lib = File.expand_path( File.join File.dirname(__FILE__), "hs", "ImplicitExportJS.hs" )
      stdin, stdout, stderr, wait_thr = Open3.popen3("runhaskell #{hs_lib} #{files[:input].path} #{files[:output].path}")

      wait_thr.value # wait for extopenscad to return
      puts "extopenscad complete!"

      # respond with the output file
      response_data = File.open( files[:output].path ).read
    ensure
      # kill the temp files with fire!
      files.each {|sym, f| f.unlink}
      #recording the streams
      response = { :format => "THREE.Geometry", :data => response_data, :stdout => (stdout.gets || ""), :stderr => (stderr.gets || "") }
      # closing the output streams
      stdin.close unless stdin.nil?
      stdout.close unless stdout.nil?
      stderr.close unless stderr.nil?
    end

    # return the response data
    response
  end
end