class ThreeJSMonkey

  def self.header
    # some dense JS. Let's make helper functions so that we don't repeat code each line
    <<-eos
var Shape = function(){
  var s = this;
  THREE.Geometry.call(this);
  function vec(x,y,z){return new THREE.Vector3(x,y,z);}
  function v(x,y,z){s.vertices.push(new THREE.Vertex(vec(x,y,z)));}
  function f(a,b,c,nx,ny,nz){
    s.faces.push( new THREE.Face3(a,b,c,vec(nx,ny,nz)) );
  }
    eos
  end

  def self.footer
    <<-eos
}
Shape.prototype = new THREE.Geometry();
Shape.prototype.constructor = Shape;
    eos
  end

  def self.add_vert(js, line)
    vert = line[1..3]
    js << "v(#{vert.join(",")});\n"
    return vert
  end

  # Compiles a STL file to a THREE.js file
  def self.compile_js(stl_file)

    js = self.header
    vert_count = 0

    begin 
      until false

        line = stl_file.readline.split(" ")

        # Parsing each vertex and face line and adding them to the js string
        case line[0]

          # Parsing faces from the stl format: 'facet normal 0 0 0'
          when "facet"
            face_verts = (0..2).map{ |i| vert_count + i }
            normal = line[2..4].map &:to_f

            # a 0,0,0 normal is defined as an undefined normal in the STL format
            if normal == [0,0,0]
              # skipping the "Loop" line
              stl_file.readline

              # Getting the next 3 verts
              v = (0..2).map do |i|
                vert_count += 1
                self.add_vert( js, stl_file.readline.split(" ") ).map &:to_f
              end

              # Getting v1 and v2 relative to v0 so that we can take their cross product to get a normal
              rel_v = v[1..2].map { |vert_n| (0..2).map {|i| vert_n[i] - v[0][i] } }

              # Cross product
              normal = [[1,2], [2,0], [0,1]].map do |a|
                rel_v[0][a[0]] * rel_v[1][a[1]] - rel_v[0][a[1]] * rel_v[1][a[0]]
              end
            end

            js << "f(#{ ( face_verts + normal ).join(",") });\n"

          # Parsing vertexes from the stl format: 'vertex 7.5789475 15.380524 -20.0'
          when "vertex"
            vert_count += 1
            self.add_vert(js, line)
        end

      end
    rescue EOFError # End of file, this happens on the last readline, ignore.
    end

    return js + self.footer
  end


  # New Relic Performance Hook
  if defined? NewRelic
    class << self
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation
      add_method_tracer :compile_js, 'Custom/ThreeJSMonkey/compile_js', :metric => false
    end
  end

end
