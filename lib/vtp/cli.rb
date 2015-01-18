require 'slop'
require 'json'
require_relative 'vtp'

class VTP
  class CLI
    CRASH_FILE = 'vtp.crash-'
    attr_reader :debug

    def initialize
      _args, @opts = opts_parse
      @debug = true if @opts[:debug]
    end

    def run
      Process.daemon unless @debug
      vtp = VTP.new @opts.to_hash
      vtp.inject if @opts[:domain]
      vtp.capture do |pkt|
        json = packet_to_json pkt
        # is File.write atomic?
        @opts[:file] ? File.write(@opts[:file], json) : puts(json)
      end
    rescue => error
      crash error
      raise
    end

    private

    def crash error
      require 'tempfile'
      crashfile = Tempfile.new CRASH_FILE
      ObjectSpace.undefine_finalizer crashfile
      open(crashfile, 'w') do |file|
        file.puts Time.now.utc
        file.puts error.message + ' [' + error.class.to_s + ']'
        file.puts '-' * 60
        file.puts error.backtrace
        file.puts '=' * 60
      end
    end

    def packet_to_json pkt
      hash  = {}
      hash['domain']   = pkt.domain
      hash['revision'] = pkt.revision
      hash['vlan']     = pkt.vlan.map do |vlan|
        next unless vlan.type == 1
        { 'id'=>vlan.id, 'name'=>vlan.name}
      end.compact
      JSON.pretty_generate hash
    end

    def opts_parse
      opts = Slop.parse(help: true) do
        banner 'Usage: vtpd [options]'
        on 'd' , 'debug',       'turn on debugging'
        on 'f=', 'file',        'store to file'
        on 'i=', 'interface',   "specify interface to listen, instead of #{INTERFACE}"
        on 'n=', 'domain name', 'if set, injects advertisement request on start'
      end
      [opts.parse!, opts]
    end
  end
end

