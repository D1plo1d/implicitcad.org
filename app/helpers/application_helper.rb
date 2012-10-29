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

  def navigation_button(url, title)
    if current_page? url
      link_to(title, url, class: "btn btn-large disabled")
    else
      link_to(title, url, class: "btn btn-large")
    end
  end

  def navigation_item(url, title)
    if current_page? url
      content_tag("li", link_to(title, url), class: "disabled-navigation")
    else
      content_tag("li", link_to(title, url))
    end
  end

  def navigation_button_small(url, title)
    if current_page? url
      link_to(title, url, class: "btn disabled")
    else
      link_to(title, url, class: "btn")
    end
  end


end
