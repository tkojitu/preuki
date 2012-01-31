#!ruby
# -*- encoding: utf-8 -*-

require 'webrick/cgi'

module Preuki
  class PreukiCGI < WEBrick::CGI
    PAGE_ROOT = "/media/4GB/httpd/preuki/"

    def initialize
      super()
      @hd = HealthDep.new
    end

    def do_GET(req, res)
      res["Content-Type"] = "text/html"
      cmd, page = get_command(req)
      case cmd
      when "view"
        on_view(page, res)
      when "edit"
        on_edit(page, res)
      else
        on_else(page, res)
      end
    end

    def get_command(req)
      key = command_key(req)
      return [nil, nil] unless key
      return [key, get_page(req, key)]
    end

    def command_key(req)
      if req.query.has_key?("view")
        return "view"
      elsif req.query.has_key?("edit")
        return "edit"
      elsif req.query.has_key?("save")
        return "save"
      else
        return nil
      end
    end

    def get_page(req, key)
      return @hd.disinfect_pagename(req.query[key])
    end

    def on_view(page, res)
      begin
        show_page(page, res)
      rescue Errno::ENOENT
        set_redirect_to_new_page_editor(page, res)
      rescue
        logger.error($!)
        on_else(page, res)
      end
    end

    def show_page(page, res)
      res.body = "<html>\n"
      res.body << "<head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'></head>\n"
      res.body << "<body><pre>"
      text = File.read(PAGE_ROOT + page)
      text = @hd.disinfect_text(text)
      Notation.new(@hd).format!(text)
      res.body << text
      res.body << "</pre><hr>\n"
      res.body << ("<a href='?edit=%s'>EditText</a>\n" % page)
      res.body << "</body></html>"
    end

    def set_redirect_to_new_page_editor(page, res)
      res.set_redirect(WEBrick::HTTPStatus::SeeOther, "?edit=%s" % page)
    end

    def on_edit(page, res)
      begin
        text = File.read(PAGE_ROOT + page)
        text = @hd.disinfect_text(text)
        set_editor(page, res, text)
      rescue Errno::ENOENT
        set_new_page_editor(page, res)
      rescue
        logger.error($!)
        on_else(page, res)
      end
    end

    def set_editor(page, res, text)
      res.body = "<html>\n"
      res.body << "<head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'></head>\n"
      res.body << "<body>\n"
      res.body << "<form method='POST' action='?'>\n"
      res.body << "<input type='submit' value='Save'><br>\n"
      res.body << "<textarea name='text' style='width:100%;height:90%' wrap='virtual'>"
      res.body << text
      res.body << "</textarea>\n"
      res.body << ("<input type='hidden' name='save' value='%s'>\n" % page)
      res.body << "</form></body></html>"
    end

    def set_new_page_editor(page, res)
      set_editor(page, res, "")
    end

    def on_else(page, res)
      res.body = "<html><body><p>hello, world</p></body></html>"
    end

    def do_POST(req, res)
      res["Content-Type"] = "text/html"
      cmd, page = get_command(req)
      case cmd
      when "save"
        on_save(page, req, res)
      else
        on_else(page, res)
      end
    end

    def on_save(page, req, res)
      begin
        save_page(page, req)
        res.set_redirect(WEBrick::HTTPStatus::SeeOther, "?view=%s" % page)
      rescue
        logger.error($!)
        on_else(page, res)
      end
    end

    def save_page(page, req)
      File.open(PAGE_ROOT + page, "w") do |output|
        output.print(req.query["text"])
      end
    end
  end

  class HealthDep
    def disinfect_pagename(pagename)
      pagename.force_encoding("ASCII-8BIT")
      return WEBrick::HTMLUtils::escape(pagename).gsub(/\.\.|\/|\\|:/, '')
    end

    def disinfect_text(text)
      text.force_encoding("ASCII-8BIT")
      return WEBrick::HTMLUtils::escape(text)
    end

    def disinfect_link(name)
      name.force_encoding("ASCII-8BIT")
      return WEBrick::HTTPUtils::escape(name)
    end
  end

  class Notation
    def initialize(health_dep)
      @hd = health_dep
    end

    def format!(text)
      st = 0
      while true
        st = text.index(/\[\[\[[^\]]/, st)
        break unless st
        ed = text.index("]]]", st)
        break unless ed
        text[st..(ed+2)] = sprintf("<a href='?view=%s'>%s</a>",
                                   @hd.disinfect_link(text[(st+3)..(ed-1)]),
                                   text[(st+3)..(ed-1)])
      end
    end
  end
end

Preuki::PreukiCGI.new.start
