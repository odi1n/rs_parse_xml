require 'uri'
require 'net/http'
require 'nokogiri'

LINK_PARS = 'https://flow.postnauka.ru/rss/index'

class Channel
    attr_accessor :title
    attr_accessor :link
    attr_accessor :description
    attr_accessor :language
    attr_accessor :lastBuildDate
    attr_accessor :item

    def initialize(title, link, description, language, lastBuildDate, item)
        @title = title
        @link = link
        @description = description
        @language = language
        @lastBuildDate = lastBuildDate
        @item = item
    end

    def to_s
        { 'title': @title,
          'link': @link,
          'desc': @description,
          'language': @language,
          'lastBuildDate': @lastBuildDate,
          'items': @item }
    end
end

class Item
    attr_accessor :title
    attr_accessor :link
    attr_accessor :pubDate
    attr_accessor :media_rating
    attr_accessor :author
    attr_accessor :description
    attr_accessor :enclosure
    attr_accessor :content

    def initialize(title, link, pubDate, media_rating, author, description, enclosure, content)
        @title = title
        @link = link
        @pubDate = pubDate
        @media_rating = media_rating
        @author = author
        @description = description
        @enclosure = enclosure
        @content = content
    end

    def to_s
        { 'title': @title,
          'link': @link,
          'pubDate': @pubDate,
          'media_rating': @media_rating,
          'author': @author,
          'description': @description,
          'enclosure': @enclosure,
          'content': @content, }
    end
end

def get_request
    uri = URI(LINK_PARS)
    return Net::HTTP.get_response(uri).body
end

def pars(response)
    items = []

    doc = Nokogiri::XML(response)
    doc.xpath('//item').each do |item|
        content = item.xpath('./content:encoded').text.gsub("<![CDATA[ ", "").gsub("]]>", "")
        content_html = Nokogiri::HTML(content)

        content = item.xpath('description').text.gsub("<![CDATA[ ", "").gsub("]]>", "")
        description_html = Nokogiri::HTML(content)

        enclosures = []
        item.xpath('./enclosure').each do |enclosure|
            enclosures.append(enclosure['url'])
        end

        items.append(Item.new(item.xpath('./title').text,
                              item.xpath('./link').text,
                              item.xpath('./pubDate').text,
                              item.xpath('./media:rating').text,
                              item.xpath('./author').text,
                              description_html.text,
                              enclosures,
                              content_html.text.strip.gsub('\n\n', ' ')).to_s)
    end

    # puts items[0]
    # items = nil

    channel = Channel.new(doc.xpath('//title').first.text,
                          doc.xpath('//link').first.text,
                          doc.xpath('//description').first.text,
                          doc.xpath('//language').first.text,
                          doc.xpath('//lastBuildDate').first.text,
                          items)

    return channel
end

puts pars(get_request()).to_s