module ApplicationHelper

  def escad_example(example_name, opts = {:format => :text})
    example = File.open(File.join Rails.root, "config", "implicit-cad-examples", "#{example_name}.escad").read
    return opts[:format] == :url ? example.gsub("\n", "\\n") : example
  end

end
