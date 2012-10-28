module ApplicationHelper

  def escad_example(example_name, opts = {:format => :text})
    example = File.open(File.join Rails.root, "config", "implicit-cad-examples", "#{example_name.to_s.gsub("_", "-")}.escad").read
    return opts[:format] == :url ? example.gsub("\n", "\\n") : example
  end

  def example_exists?(example_name)
    File.exists?(File.join Rails.root, "config", "implicit-cad-examples", "#{example_name.to_s.gsub("_", "-")}.escad")
  end

  

  def examples
    File.read(File.join Rails.root, "config", "implicit-cad-examples.txt").split("\n")
  end

  def example_code(example)
    File.read(File.join Rails.root, "config", "implicit-cad-examples", "#{example}.escad")
  end

  def example_image_url(example)
    "/assets/examples-#{example}.png"
  end


end
