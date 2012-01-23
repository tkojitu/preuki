#!ruby

require 'webrick/cgi'

class Preuki < WEBrick::CGI
  PAGE_ROOT = "/media/4GB/httpd/preuki/"

  def do_GET(req, res)
    if req.query.has_key?("view")
      on_view(req, res)
    else
      on_else(req, res)
    end
  end

  def on_view(req, res)
    res["Content-Type"] = "text/html"
    begin
      res.body = "<html><body><pre>"
      text = File.read(PAGE_ROOT + req.query["view"]) # insesure
      res.body << text
      res.body << "</pre></body></html>"
    rescue
      on_else(req, res)
      return
    end
  end

  def on_else(req, res)
    res["Content-Type"] = "text/html"
    res.body = "<html><body><p>hello, world</p></body></html>"
  end
end

Preuki.new.start
