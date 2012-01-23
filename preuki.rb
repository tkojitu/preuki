#!ruby

require 'webrick/cgi'

class Preuki < WEBrick::CGI
  PAGE_ROOT = "/media/4GB/httpd/preuki/"

  def do_GET(req, res)
    res["Content-Type"] = "text/html"
    if req.query.has_key?("view")
      on_view(req, res)
    elsif req.query.has_key?("edit")
      on_edit(req, res)
    else
      on_else(req, res)
    end
  end

  def on_view(req, res)
    begin
      res.body = "<html><body><pre>"
      text = File.read(PAGE_ROOT + req.query["view"])
      res.body << text
      res.body << "</pre></body></html>"
    rescue
      on_else(req, res)
    end
  end

  def on_edit(req, res)
    begin
      res.body = "<html><body><form method='POST' action='?save=%s'>\n" % req.query["edit"]
      res.body << "<input type='submit' value='Save'><br>\n"
      res.body << "<textarea name='text' style='width=100%' rows=25 cols=80 wrap='virtual'>"
      text = File.read(PAGE_ROOT + req.query["edit"])
      res.body << text
      res.body << "</textarea></form></body></html>"
    rescue
      on_else(req, res)
    end
  end

  def on_else(req, res)
    res.body = "<html><body><p>hello, world</p></body></html>"
  end
end

Preuki.new.start
