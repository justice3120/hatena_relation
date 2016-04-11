require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'csv'
require 'rserve'


class CollectRelationJob < ActiveJob::Base
  queue_as :default

  def perform(collect_request, params)
    collect_request.update(:status => "processing")

    edges_csv_path = Rails.root.join("tmp", "#{collect_request.request_id}_edges.csv")
    nodes_csv_path = Rails.root.join("tmp", "#{collect_request.request_id}_nodes.csv")

    result = { :nodes => [], :edges => [] }

    if params[:entry_id] || params[:entry_url]
      eid = params[:entry_id]
      eid = get_eid_from_url(params[:entry_url]) unless eid

      star_list = get_stars(eid)
      calculate_network(star_list, edges_csv_path, nodes_csv_path)

      edges = CSV.table(edges_csv_path)
      edges.each do |edge|
        result[:edges] << {
          :id => SecureRandom.uuid,
          :source => edge[:star_sender],
          :target => edge[:star_getter],
          :size => edge[:count],
          :type => 'arrow'
        }
      end

      bookmarks = get_bookmarks(eid)

      nodes = CSV.table(nodes_csv_path)
      nodes.each do |node|
        label = node[:name]
        bookmark = bookmarks.find {|b| b[:name].eql?(node[:name])}
        if bookmark
          label = "#{node[:name]}: #{bookmark[:comment]}"
        else
          label = "#{node[:name]}: <StarOnly>"
        end
        result[:nodes] << {
          :id => node[:name],
          :label => label,
          :size => node[:bw] > 1.0 ? node[:bw].to_f : 0.0,
          :type => 'square',
          :image => {
            :url => "http://cdn1.www.st-hatena.com/users/#{node[:name].to_s[0, 2]}/#{node[:name]}/profile.gif",
            :scale => 0.9
          }
        }
      end
    elsif params[:category] && params[:start_date] && params[:end_date]
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      category = params[:category]

      eid_list = []
      (start_date..end_date).each do |day|
        hotentry_url = "http://b.hatena.ne.jp/hotentry/#{category}/#{day.strftime('%Y%m%d')}"
        p hotentry_url
        doc = get_html(hotentry_url)
        doc.css('div.top').css('li.entry-unit').each do |entry|
          eid_list << entry['data-eid']
        end
      end

      eid_list.uniq!
      p eid_list

      star_list = []
      eid_list.each do |eid|
        begin
          star_list += get_stars(eid)
        rescue => e
          puts "#{e.class}: #{e.message}"
          retry
        end
      end

      calculate_network(star_list, edges_csv_path, nodes_csv_path)

      edges = CSV.table(edges_csv_path)
      edges.each do |edge|
        result[:edges] << {
          :id => SecureRandom.uuid,
          :source => edge[:star_sender],
          :target => edge[:star_getter],
          :size => edge[:count],
          :type => 'arrow'
        }
      end

      nodes = CSV.table(nodes_csv_path)
      nodes.each do |node|
        label = node[:name]
        result[:nodes] << {
          :id => node[:name],
          :label => label,
          :size => node[:bw] > 1.0 ? node[:bw].to_f : 0.0,
          :type => 'square',
          :image => {
            :url => "http://cdn1.www.st-hatena.com/users/#{node[:name].to_s[0, 2]}/#{node[:name]}/profile.gif",
            :scale => 0.9
          }
        }
      end
    else
      raise ArgumentError, 'invalid paramater'
    end

    File.delete(edges_csv_path)
    File.delete(nodes_csv_path)

    collect_request.update(:status => "completed", :result => result.to_json)
  rescue => e
    collect_request.update(:status => "failed")
    puts "#{e.class}: #{e.message}"
  end

  private
  def get_eid_from_url(url)
  end

  def get_stars(eid)
    star_list = []

    bookmarks = get_bookmarks(eid)

    while !bookmarks.empty?
      param = "?eid=#{eid}"

      bookmarks.shift(100).each do |bookmark|
        param += "&u=#{bookmark[:name]}/#{bookmark[:date]}"
      end

      url = "http://s.hatena.ne.jp/entries.bookmark.json" + param
        get_json(url)['entries'].select {|b| !b['stars'].empty?}.each do |bookmark|
          if bookmark['stars'].any? {|s| s.class.eql?(Fixnum)}
            url = "http://s.hatena.ne.jp/entry.json?uri=#{CGI.escape(bookmark['uri'])}"
            bookmark['stars'] = get_json(url)['entries'].first['stars']
          end
          bookmark['stars'].each do |star|
          raw_star_sender = star['name'].to_s
          raw_star_getter = bookmark['uri'].split('/')[3]
          star_sender = raw_star_sender.include?('@') ? raw_star_sender.split('@').first : raw_star_sender
          star_getter = raw_star_getter.include?('@') ? raw_star_getter.split('@').first : raw_star_getter
          star_list << [star_sender, star_getter]
        end
      end
    end
    return star_list
  end

  def calculate_network(star_list, edges_csv_path, nodes_csv_path)
    star_list_counted = star_list.map do |star|
      count = star_list.select {|s| s.eql?(star)}.length
      star_list.delete(star)
      star << count
      star
    end

    CSV.open(edges_csv_path, "w") do |csv|
      csv << ["star_sender", "star_getter", "count"]
      star_list_counted.each do |row|
        csv << row
      end
    end

    rc = Rserve::Connection.new

    rc.eval <<-EOS
library(igraph)
library(linkcomm)
hatena_relations <- read.csv('#{edges_csv_path}')
g<-graph.edgelist(as.matrix(hatena_relations[1:2]),directed=T)
E(g)$weight <- hatena_relations[[3]]
g.bw<-betweenness(g, directed=T)
nodes <- data.frame(name=attr(g.bw, 'names'), bw=g.bw)
write.csv(nodes, '#{nodes_csv_path}', quote=F, row.names=F)
    EOS
  end

  def get_bookmarks(eid)
    url = "http://b.hatena.ne.jp/entry.comment_fragments?eid=#{eid}&page=1&per_page=10000&comment_only=0"
    doc = get_html(url)

    bookmarks = doc.css('li').map do |bookmark|
      {
        name: bookmark.css('.username').text,
        date: bookmark.css('.timestamp').css('a').text.split('/').join,
        comment: bookmark.css('.comment').text
      }
    end
    bookmarks
  end

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
