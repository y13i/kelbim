require 'aws-sdk'
require 'fileutils'

AWS.config({
  :access_key_id => (ENV['TEST_AWS_ACCESS_KEY_ID'] || 'scott'),
  :secret_access_key => (ENV['TEST_AWS_SECRET_ACCESS_KEY'] || 'tiger'),
  :region => ENV['TEST_AWS_REGION'],
})

def elbfile(options = {})
  updated = false
  tempfile = `mktemp /tmp/#{File.basename(__FILE__)}.XXXXXX`.strip

  begin
    open(tempfile, 'wb') {|f| f.puts(yield) }
    options = {:logger => Logger.new('/dev/null')}.merge(options)

    if options[:debug]
      AWS.config({
        :http_wire_trace => true,
        :logger => (options[:logger] || Kelbim::Logger.instance),
      })
    end

    client = Kelbim::Client.new(options)
    updated = client.apply(tempfile)
  ensure
    FileUtils.rm_f(tempfile)
  end

  return updated
end

def export_elb(options = {})
  options = {:logger => Logger.new('/dev/null')}.merge(options)

  if options[:debug]
    AWS.config({
      :http_wire_trace => true,
      :logger => (options[:logger] || Kelbim::Logger.instance),
    })
  end

  client = Kelbim::Client.new(options)
  client.export {|e, c| e }
end
