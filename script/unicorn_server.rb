Dir.chdir(File.join File.dirname(__FILE__), "..")
`rm ./public/index.html`
puts "Precompiling.."
`bundle exec rake assets:precompile`
puts "[ DONE ]"
`unicorn -c ./config/unicorn.rb`
