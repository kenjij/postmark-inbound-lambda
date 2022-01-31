require 'base64'

module PINS
  def self.handlers
    PINS::Handler.handlers
  end

  class Handler
    # Import handlers from designated directory
    def self.import
      path = File.expand_path('../../handlers', __FILE__)
      import_from_path(path)
    end

    # Import handlers from a directory
    # @param path [String] directory name
    def self.import_from_path(path)
      Dir.chdir(path) {
        Dir.foreach('.') { |f| load f unless File.directory?(f) }
      }
    end

    # Call as often as necessary to add handlers with blocks; each call creates a PINS::Handler object
    # @param server [String] Postmark server name
    # @param name [String] name of the handler
    def self.add(server, name = nil, &block)
      @handlers ||= {}
      @handlers[server] ||= []
      @handlers[server] << PINS::Handler.new(name, &block)
      PINS.logger.debug("Added #{server} handler: #{@handlers[server].last}")
    end

    # @return [Hash] containing all the handlers
    def self.handlers
      @handlers
    end

    # Run the appropriate handlers
    # @param e [Hash] Lambda event data
    # @return [Integer] number of handlers called
    def self.run(e)
      l = PINS.logger
      s = e.dig('requestContext', 'authorizer', 'lambda', 'server')
      raise 'Abort: authorization bypassed?' unless s
      i = 0
      if hds = @handlers[s]
        b = e['isBase64Encoded'] ? Base64.decode64(e['body']) : e['body']
        pin = JSON.parse(b)
        l.debug("Running handlers for server: #{s}")
        hds.each do |hd|
          begin
            hd.run(pin)
          rescue => e
            l.error "Aborting due to handler error:\n#{e}"
            break
          end
          i += 1
          if hd.stopped?
            l.debug('Handler stop was requested.')
            break
          end
        end
        l.info("Done running handlers for server: #{s}")
      else
        l.info("No handlers found for server: #{s}")
      end
      i
    end

    attr_reader :name

    def initialize(n = nil, &block)
      @name = n
      @block = block
      @stopped = false
    end

    def run(pin)
      l = PINS.logger
      l.warn("No block to execute for #{name} handler: #{self}") unless @block
      l.debug("Running #{name} handler: #{self}")
      @stopped = false
      @block.call(pin, self)
    rescue => e
      l.error(e.message)
      l.error(e.backtrace.join("\n"))
    end

    def stop
      @stopped = true
    end

    def stopped?
      @stopped
    end

    def to_s
      "#<#{self.class}:#{self.object_id.to_s(16)}(#{name})>"
    end
  end
end
