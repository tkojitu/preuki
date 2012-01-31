#!ruby

require 'webrick/cgi'

module Preuki
  class PreukiCGI < WEBrick::CGI
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
      rescue Errno::ENOENT
        set_redirect_to_new_page_editor(req, res)
      rescue
        on_else(req, res)
      end
    end

    def show_page(res, pagename)
      res.body = "<html><body><pre>"
      text = File.read(PAGE_ROOT + pagename)
      Notation.new.format!(text)
      res.body << text
      res.body << "</pre><hr>\n"
      res.body << ("<a href='?edit=%s'>EditText</a>\n" % pagename)
      res.body << "</body></html>"
    end

    def set_redirect_to_new_page_editor(req, res)
        res.set_redirect(WEBrick::HTTPStatus::SeeOther,
                         "?edit=%s" % req.query["view"])
    end

    def on_edit(req, res)
      begin
        text = File.read(PAGE_ROOT + req.query["edit"])
        set_editor(res, text, req.query["edit"])
      rescue Errno::ENOENT
        set_new_page_editor(req, res)
      rescue
        on_else(req, res)
      end
    end

    def set_editor(res, text, page)
        res.body = "<html><body>\n"
        res.body << "<form method='POST' action='?'>\n"
        res.body << "<input type='submit' value='Save'><br>\n"
        res.body << "<textarea name='text' style='width:100%;height:90%' wrap='virtual'>"
        res.body << text
        res.body << "</textarea>\n"
        res.body << ("<input type='hidden' name='save' value='%s'>\n" % page)
        res.body << "</form></body></html>"
    end

    def set_new_page_editor(req, res)
      set_editor(res, "", req.query["edit"])
    end

    def on_else(req, res)
      res.body = "<html><body><p>hello, world</p></body></html>"
    end

    def do_POST(req, res)
      res["Content-Type"] = "text/html"
      if req.query.has_key?("save")
        on_save(req, res)
      else
        on_else(req, res)
      end
    end

    def on_save(req, res)
      begin
        pagename = req.query["save"]
        save_page(req, pagename)
        res.set_redirect(WEBrick::HTTPStatus::SeeOther, "?view=%s" % pagename)
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

  class Notation
    def format!(text)
      text.gsub!(/\[\[\[([%0-9A-Za-z_-]+)\]\]\]/, "<a href='?view=\\1'>\\1</a>")
    end
  end
end

Preuki::PreukiCGI.new.start
