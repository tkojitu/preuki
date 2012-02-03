require 'webrick'

class WebServer
  SERVER_ROOT = '/media/4GB/httpd/'
  DOCUMENT_ROOT = SERVER_ROOT + 'htdocs/'
  CGI_ROOT = SERVER_ROOT + 'cgi-bin/'
  RUBYBIN = 'ruby'

  def main
    server = WEBrick::HTTPServer.new(server_options)
    mount_cgis(server)
    trap_signals(server)
    server.start
  end

  def server_options
    return {
      :DocumentRoot => DOCUMENT_ROOT,
      :BindAddress => '0.0.0.0',
      :CGIInterpreter => RUBYBIN,
      :Port => 8888
    }
  end

  def mount_cgis(server)
    Dir.chdir(CGI_ROOT) do
      Dir.glob('*.rb').each do |filename|
        server.mount('/cgi-bin/' + filename, WEBrick::HTTPServlet::CGIHandler,
                     File.expand_path(filename))
      end
    end
  end

  def trap_signals(server)
    ['INT', 'TERM'].each do |signal|
      Signal.trap(signal){server.shutdown}
    end
  end
end

WebServer.new.main
