#!ruby

require 'webrick/cgi'

class Preuki < WEBrick::CGI
  PAGE_ROOT = "/media/4GB/httpd/preuki/"

  def initialize
    super()
  end

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
      show_page(res, req.query["view"])
    rescue
      on_else(req, res)
    end
  end

  def show_page(res, pagename)
    res.body = "<html><body><pre>"
    text = File.read(PAGE_ROOT + pagename)
    res.body << text
    res.body << "</pre><hr>\n"
    res.body << ("<a href='?edit=%s'>EditText</a>\n" % pagename)
    res.body << "</body></html>"
  end

  def on_edit(req, res)
    begin
      res.body = "<html><body>\n"
      res.body << "<form method='POST' action='?save=%s'>\n" % req.query["edit"]
      res.body << "<input type='submit' value='Save'><br>\n"
      res.body << "<textarea name='text' style='width:100%;height:90%' wrap='virtual'>"
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

  def do_POST(req, res)
    res["Content-Type"] = "text/html"
    on_else(req, res)
    if /\Asave=/ =~ req.query_string
      on_save(req, res)
    else
      on_else(req, res)
    end
  end

  def on_save(req, res)
    begin
      pagename = req.query_string.sub(/\Asave=/, '')
      save_page(req, pagename)
      show_page(res, pagename)
    rescue
      logger.error($!)
      on_else(req, res)
    end
  end

  def save_page(req, pagename)
    File.open(PAGE_ROOT + pagename, "w") do |output|
      output.print(req.query["text"])
    end
  end
end

Preuki.new.start
