require 'open-uri'
require 'nokogiri'
require 'cgi'


class CollectRelationJob < ActiveJob::Base
  queue_as :default

  def perform(collect_request, params)
    result = { :nodes => [], :edges => [] }

    params[:eid_list].uniq.each do |eid|
      url = "http://b.hatena.ne.jp/entry.comment_fragments?eid=#{eid}&page=1&per_page=10000&comment_only=0"
      doc = get_html(url)

      bookmark_users = doc.css('li').map do |bookmark|
        {
          name: bookmark.css('.username').text,
          date: bookmark.css('.timestamp').css('a').text.split('/').join
        }
      end


      while !bookmark_users.empty?
        param = "?eid=#{eid}"

        bookmark_users.shift(100).each do |bookmark_user|
          param += "&u=#{bookmark_user[:name]}/#{bookmark_user[:date]}"
        end

        url = "http://s.hatena.ne.jp/entries.bookmark.json" + param
        get_json(url)['entries'].select {|b| !b['stars'].empty?}.each do |bookmark|
          if bookmark['stars'].any? {|s| s.class.eql?(Fixnum)}
            url = "http://s.hatena.ne.jp/entry.json?uri=#{CGI.escape(bookmark['uri'])}"
            bookmark['stars'] = get_json(url)['entries'].first['stars']
          end
          bookmark['stars'].each do |star|
            star_sender = star['name'].to_s
            star_getter = bookmark['uri'].split('/')[3]

            unless result[:nodes].find {|node| node[:id].eql?(star_sender)}
              result[:nodes] << {
                :id => star_sender,
                :label => star_sender
              }
            end

            unless result[:nodes].find {|node| node[:id].eql?(star_getter)}
              result[:nodes] << {
                :id => star_getter,
                :label => star_getter
              }
            end

            unless result[:edges].find {|edge| edge[:source].eql?(star_sender) && edge[:target].eql?(star_getter)}
              result[:edges] << {
                :id => SecureRandom.uuid,
                :source => star_sender,
                :target => star_getter
              }
            end
          end
        end
      end
    end

    #star_list_counted = star_list.map do |star|
    #  count = star_list.select {|s| s.eql?(star)}.length
    #  star_list.delete(star)
    #  star << count
    #  star
    #end

    collect_request.update(:completed => true, :result => result.to_json)
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

  def get_json(url)
    json = open(url, get_opt) do |f|
      f.read
    end
    JSON.parse(json)
  end

  def get_opt()
    opt = {}
    opt['User-Agent'] = 'Opera/9.80 (Windows NT 5.1; U; ja) Presto/2.7.62 Version/11.01 '
    opt
  end
end
