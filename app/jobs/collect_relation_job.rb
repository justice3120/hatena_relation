require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'csv'
require 'rinruby'


class CollectRelationJob < ActiveJob::Base
  queue_as :default

  def perform(collect_request, params)
    star_list = []

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
            raw_star_sender = star['name'].to_s
            raw_star_getter = bookmark['uri'].split('/')[3]
            star_sender = raw_star_sender.include?('@') ? raw_star_sender.split('@').first : raw_star_sender
            star_getter = raw_star_getter.include?('@') ? raw_star_getter.split('@').first : raw_star_getter
            star_list << [star_sender, star_getter]
          end
        end
      end
    end

    star_list_counted = star_list.map do |star|
      count = star_list.select {|s| s.eql?(star)}.length
      star_list.delete(star)
      star << count
      star
    end

    edges_csv_path = Rails.root.join("tmp", "#{collect_request.request_id}_edges.csv")
    nodes_csv_path = Rails.root.join("tmp", "#{collect_request.request_id}_nodes.csv")

    CSV.open(edges_csv_path, "w") do |csv|
      csv << ["star_sender", "star_getter", "count"]
      star_list_counted.each do |row|
        csv << row
      end
    end

    R.eval <<EOS
library(igraph)
library(linkcomm)
hatena_relations <- read.csv('#{edges_csv_path}')
g<-graph.edgelist(as.matrix(hatena_relations[1:2]),directed=T)
E(g)$weight <- hatena_relations[[3]]
g.bw<-betweenness(g, directed=T)
dcg <- decompose.graph(g)
sp.all <- c()
for (i in 1:length(dcg)){
  set.seed(1)
  sp <- spinglass.community(dcg[[i]])
  sp.all <- rbind(sp.all, cbind(sp$names, g.bw[sp$names], i, sp$membership))
}
nodes <- as.data.frame(sp.all)
colnames(nodes) <- c("name", "bw", "graph_id", "membership")
write.csv(nodes, '#{nodes_csv_path}', quote=F, row.names=F)
EOS

    result = { :nodes => [], :edges => [] }

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
    bw_max = nodes[:bw].max
    color_list = []
    nodes.each do |node|
      unless color_list[node[:graph_id]]
        color_list[node[:graph_id]] = []
      end
      unless color_list[node[:graph_id]][node[:membership]]
        color_list[node[:graph_id]][node[:membership]] = '#' + rand(0x1000000).to_s(16).rjust(6, '0')
      end
      result[:nodes] << {
        :id => node[:name],
        :label => node[:name],
        :size => node[:bw] > 1.0 ? node[:bw].to_f : 0.0,
        :color => color_list[node[:graph_id]][node[:membership]],
        :type => 'square',
        :image => {
          :url => "http://cdn1.www.st-hatena.com/users/#{node[:name].to_s[0, 2]}/#{node[:name]}/profile.gif",
          :scale => 0.9
        }
      }
    end

    collect_request.update(:completed => true, :result => result.to_json)

    File.delete(edges_csv_path)
    File.delete(nodes_csv_path)
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
