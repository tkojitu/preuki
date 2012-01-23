#!ruby

require 'webrick/cgi'

class Preuki < WEBrick::CGI
  def do_GET(req, res)
    res["Content-Type"] = "text/html"
    res.body = "<html><body><p>hello, world</p></body></html>"
  end
end

Preuki.new.start
