require 'date'
require 'open-uri'
require 'nokogiri'

class HotentriesController < ApplicationController
  def index
    date = params[:date].to_s
    url = "http://b.hatena.ne.jp/hotentry"
    unless date.eql?(Date.today.strftime("%Y%m%d"))
      url += "/#{date}"
    end

    doc = get_html(url)
    @hotentories = doc.css('div.top').css('li.entry-unit').map do |entry|
      id = entry['data-eid']
      title = entry.css('a.entry-link').text
      category_class = entry['class'].split(' ').find {|c| c.include?('category')}
      category = category_class ? category_class.split('-').last : nil
      bookmark_count = entry.css('ul.users').css('span').text
      { "id" => id, "title" => title, "category" => category, "bookmarkCount" => bookmark_count }
    end

    respond_to do |format|
      response.headers['Content-Type'] = 'application/json; charset=utf-8'
      format.any { render json: @hotentories.to_json }
    end
  end

  private
  def get_html(url)
    charset = nil
    html = open(url, get_opt) do |f|
      charset = f.charset
      f.read
    end
    Nokogiri::HTML.parse(html, nil, charset)
  end

  def get_opt()
    opt = {}
    opt['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/49.0.2623.108 Chrome/49.0.2623.108 Safari/537.36'
    opt
  end
end
