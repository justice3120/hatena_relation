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
            star_sender = star['name'].to_s
            star_getter = bookmark['uri'].split('/')[3]
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

    tmp_csv_path = Rails.root.join("tmp", "#{collect_request.request_id}_tmp.csv")
    betweenness_csv_path = Rails.root.join("tmp", "#{collect_request.request_id}_betweenness.csv")
    community_csv_path = Rails.root.join("tmp", "#{collect_request.request_id}_community.csv")

    CSV.open(tmp_csv_path, "w") do |csv|
      csv << ["star_sender", "star_getter", "count"]
      star_list_counted.each do |row|
        csv << row
      end
    end

    R.eval <<EOS
library(igraph)
library(linkcomm)
hatena_relations <- read.csv('#{tmp_csv_path}')
g<-graph.edgelist(as.matrix(hatena_relations[1:2]),directed=T)
E(g)$weight <- hatena_relations[[3]]
g.bw<-betweenness(g, directed=T)
bw <- c("name", "betweenness")
for (i in 1:length(g.bw)){
  bw <- rbind(V(g)$name[i], g.bw[i])
}
write.csv(bw, '#{betweenness_csv_path}', quote=F, row.names=F, col.names=F)
dcg <- decompose.graph(g)
sp.all <- c("graph_id", "name", "membership")
for (i in 1:length(dcg)){
  set.seed(1)
  sp <- spinglass.community(dcg[[i]])
  sp.all <- rbind(sp.all, cbind(i, sp$names, sp$membership))
}
write.csv(sp.all, '#{community_csv_path}', quote=F, row.names=F, col.names=F)
EOS

    bw = R.pull "g.bw"
    v = R.pull "g.v"

    result = { :nodes => [], :edges => [] }

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
