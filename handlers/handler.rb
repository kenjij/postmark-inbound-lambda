PINS::Handler.add('PINS-test123', 'Demonstration') do |pin, myself|
  puts "#{pin}"
  myself.stop
end
